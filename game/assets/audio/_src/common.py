"""Utilitaires de synthèse sonore pour « État des lieux ».

Tous les sons du jeu sont générés ici (synthèse procédurale, aucun échantillon
tiers) : licence CC0, reproductible, réglable au sample près.

Sortie : OGG Vorbis mono 44,1 kHz (Godot importe l'OGG nativement).
Les scripts se lancent depuis la racine du dépôt :

    python3 game/assets/audio/_src/synth_camera.py
    python3 game/assets/audio/_src/preview.py camera/camera_flash.ogg

Dépendances : numpy, scipy, soundfile (+ matplotlib pour les spectrogrammes).
"""

from __future__ import annotations

import os
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy import signal

SR = 44100
AUDIO_ROOT = Path(__file__).resolve().parent.parent  # game/assets/audio/


# --------------------------------------------------------------- bruit / rng

def rng_for(seed: int) -> np.random.Generator:
	"""Générateur déterministe : un son = une graine."""
	return np.random.default_rng(seed)


def noise(n: int, rng: np.random.Generator) -> np.ndarray:
	return rng.standard_normal(n)


# ------------------------------------------------------------------- filtres

def _sos(kind: str, f, order: int, sr: int = SR):
	nyq = sr / 2.0
	if kind == "band":
		lo, hi = f
		if hi >= nyq * 0.99:
			return signal.butter(order, max(lo / nyq, 1e-5), btype="high", output="sos")
		if lo <= 20.0:
			return signal.butter(order, min(hi / nyq, 0.99), btype="low", output="sos")
		return signal.butter(order, [max(lo / nyq, 1e-5), min(hi / nyq, 0.99)], btype="band", output="sos")
	if kind == "low":
		return signal.butter(order, min(f / nyq, 0.99), btype="low", output="sos")
	return signal.butter(order, max(f / nyq, 1e-5), btype="high", output="sos")


def bp(x: np.ndarray, lo: float, hi: float, order: int = 4, sr: int = SR) -> np.ndarray:
	return signal.sosfiltfilt(_sos("band", (lo, hi), order, sr), x)


def lp(x: np.ndarray, f: float, order: int = 4, sr: int = SR) -> np.ndarray:
	return signal.sosfiltfilt(_sos("low", f, order, sr), x)


def hp(x: np.ndarray, f: float, order: int = 4, sr: int = SR) -> np.ndarray:
	return signal.sosfiltfilt(_sos("high", f, order, sr), x)


def peak(f: float, q: float, sr: int = SR):
	"""Filtre résonant (passe-bande étroit) : simule une résonance mécanique."""
	nyq = sr / 2.0
	w = min(f / nyq, 0.99)
	bw = max(w / max(q, 0.1), 1e-4)
	return signal.butter(2, [max(w - bw / 2, 1e-5), min(w + bw / 2, 0.99)], btype="band", output="sos")


def resonate(x: np.ndarray, f: float, q: float = 6.0, sr: int = SR) -> np.ndarray:
	return signal.sosfiltfilt(peak(f, q, sr), x)


# -------------------------------------------------------------- enveloppes

def t_axis(n: int, sr: int = SR) -> np.ndarray:
	return np.arange(n, dtype=np.float64) / sr


def exp_decay(n: int, tau: float, sr: int = SR) -> np.ndarray:
	if tau <= 0:
		return np.zeros(n)
	return np.exp(-np.arange(n, dtype=np.float64) / (tau * sr))


def ar_env(n: int, attack: float, release: float, sr: int = SR, power: float = 1.0) -> np.ndarray:
	"""Attaque linéaire puis relâchement exponentiel (en secondes)."""
	t = t_axis(n, sr)
	a = max(int(attack * sr), 1)
	r = max(int(release * sr), 1)
	env = np.ones(n)
	if a > 1:
		env[:a] = np.linspace(0.0, 1.0, a)
	if r > 1:
		tail = exp_decay(r, release / 3.0, sr) if release > 0 else np.zeros(r)
		tail = tail ** power
		env[a:a + r] *= tail
	if a + r < n:
		env[a + r:] = 0.0
	return np.clip(env, 0.0, None)


def ramp(n: int, start: float, end: float) -> np.ndarray:
	return np.linspace(start, end, n)


def gate(t: np.ndarray, t0: float, dur: float, attack: float = 0.002, release: float = None) -> np.ndarray:
	"""Porte temporelle douce : 1 entre t0 et t0+dur, fondu aux bords."""
	release = release if release is not None else dur * 0.5
	env = np.zeros_like(t)
	attack = max(attack, 1e-5)
	env += np.clip((t - t0) / attack, 0.0, 1.0)
	env -= np.clip((t - (t0 + dur)) / max(release, 1e-5), 0.0, 1.0)
	return np.clip(env, 0.0, 1.0)


# ----------------------------------------------------------------- éléments

def tone(freqs, amps, taus, n: int, rng: np.random.Generator, sr: int = SR, detune: float = 0.0) -> np.ndarray:
	"""Somme de sinus amorties (modes mécaniques d'un objet)."""
	t = t_axis(n, sr)
	out = np.zeros(n)
	for f, a, tau in zip(freqs, amps, taus):
		f *= 1.0 + detune * rng.uniform(-1.0, 1.0)
		out += a * np.sin(2 * np.pi * f * t + rng.uniform(0, 2 * np.pi)) * exp_decay(n, tau, sr)
	return out


def click(n: int, rng: np.random.Generator, tau: float = 0.006, lo: float = 1200.0, hi: float = 9000.0, amp: float = 1.0, sr: int = SR) -> np.ndarray:
	"""Transient : bruit filtré à décroissance exponentielle (un « clac »)."""
	x = noise(n, rng) * exp_decay(n, tau, sr)
	return amp * bp(x, lo, hi, order=2, sr=sr)


def sweep(f0: float, f1: float, n: int, sr: int = SR, curve: str = "exp", phase0: float = 0.0) -> np.ndarray:
	"""Sinus à fréquence glissante (phase intégrée : pas de distorsion)."""
	t = t_axis(n, sr)
	if curve == "exp":
		k = np.log(f1 / f0)
		f = f0 * np.exp(k * t / (n / sr))
	else:
		f = np.linspace(f0, f1, n)
	phase = 2 * np.pi * np.cumsum(f) / sr + phase0
	return np.sin(phase)


# -------------------------------------------------------------- réverbération

def make_ir(dur: float = 0.35, decay: float = 0.18, sr: int = SR, bright: float = 3500.0, rng: np.random.Generator = None, taps=None) -> np.ndarray:
	"""Réponse impulsionnelle synthétique : quelques réflexions + queue bruitée."""
	rng = rng or np.random.default_rng(0)
	n = int(dur * sr)
	t = t_axis(n, sr)
	ir = noise(n, rng) * np.exp(-t / decay)
	ir = lp(ir, bright, order=2, sr=sr)
	ir[0] = 1.0
	for delay, gain in (taps or [(0.011, 0.5), (0.019, 0.35), (0.031, 0.28), (0.047, 0.18)]):
		i = int(delay * sr)
		if 0 < i < n:
			ir[i] += gain
	return ir


def reverb(x: np.ndarray, ir: np.ndarray, mix: float = 0.2) -> np.ndarray:
	wet = signal.fftconvolve(x, ir)[: len(x)]
	wet = wet / (np.max(np.abs(wet)) + 1e-9)
	return (1.0 - mix) * x + mix * wet * np.sqrt(max(np.max(np.abs(x)), 1e-9))


# ------------------------------------------------------------------- sortie

def norm(x: np.ndarray, peak_db: float = -3.0) -> np.ndarray:
	m = np.max(np.abs(x))
	if m < 1e-9:
		return x
	target = 10.0 ** (peak_db / 20.0)
	return x * (target / m)


def trim_tail(x: np.ndarray, floor_db: float = -70.0) -> np.ndarray:
	"""Coupe la queue inaudible (les OGG ne doivent pas traîner)."""
	floor = 10.0 ** (floor_db / 20.0)
	idx = np.nonzero(np.abs(x) > floor)[0]
	if len(idx) == 0:
		return x[:1]
	end = min(len(x), int(idx[-1]) + int(0.05 * SR))
	return x[:end]


def loopitize(x: np.ndarray, n: int, fade: int) -> np.ndarray:
	"""Rend une boucle sans couture : la queue (n : n+fade) se fond dans la tête."""
	x = np.asarray(x, dtype=np.float64)
	out = x[:n].copy()
	tail = x[n:n + fade]
	if len(tail) < fade:      # pas assez généré : on complète en silence
		tail = np.concatenate([tail, np.zeros(fade - len(tail))])
	w = 0.5 - 0.5 * np.cos(np.pi * np.arange(fade) / fade)   # fondu en cosinus
	out[:fade] = out[:fade] * w + tail * (1.0 - w)
	return out


def write(path: str, x: np.ndarray, sr: int = SR, peak_db: float = -3.0, floor_db: float = -70.0) -> str:
	x = np.asarray(x, dtype=np.float64)
	x = np.nan_to_num(x)
	x = norm(x, peak_db)
	x = trim_tail(x, floor_db)
	# Anti-clipping final : saturation douce si nécessaire.
	x = np.tanh(x * 1.02) / 1.02
	out = AUDIO_ROOT / path
	out.parent.mkdir(parents=True, exist_ok=True)
	# Écriture par blocs : sf.write() en un seul appel plante (segfault de
	# libsndfile) au-delà de ~2^21 échantillons (~47 s).
	block = 10 * sr
	with sf.SoundFile(str(out), "w", samplerate=sr, channels=1,
					  format="OGG", subtype="VORBIS") as f:
		for i in range(0, len(x), block):
			f.write(x[i:i + block].astype(np.float32))
	size = os.path.getsize(out)
	print("  -> %-44s %6.2f s  %7.1f ko" % (path, len(x) / sr, size / 1024.0))
	return str(out)


def stats(x: np.ndarray, label: str = "", sr: int = SR) -> None:
	rms = float(np.sqrt(np.mean(x ** 2)))
	dbfs = 20 * np.log10(rms + 1e-12)
	spec = np.abs(np.fft.rfft(x * np.hanning(len(x))))
	freqs = np.fft.rfftfreq(len(x), 1 / sr)
	centroid = float(np.sum(freqs * spec) / (np.sum(spec) + 1e-12))
	print("     %-26s dur=%.3fs  rms=%.1f dBFS  centre=%.0f Hz  crête=%.2f"
		  % (label, len(x) / sr, dbfs, centroid, float(np.max(np.abs(x)))))
