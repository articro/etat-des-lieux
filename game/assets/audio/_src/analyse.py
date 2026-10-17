"""Contrôle objectif des sons générés (durée, dynamique, spectre, attaque).

Usage :
    python3 game/assets/audio/_src/analyse.py            # tout le dossier audio
    python3 game/assets/audio/_src/analyse.py camera      # un sous-dossier

Sert de filet de sécurité : pas de NaN, pas de silence en tête, pas d'écrêtage,
une durée et une dynamique plausibles pour l'usage du son.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy import signal

from common import AUDIO_ROOT


def analyse(path: Path) -> dict:
	x, sr = sf.read(str(path), dtype="float64")
	if x.ndim > 1:
		x = x.mean(axis=1)
	x = np.nan_to_num(x)
	peak = float(np.max(np.abs(x)))
	rms = float(np.sqrt(np.mean(x ** 2)) + 1e-12)
	env = np.abs(signal.hilbert(x)) if False else np.abs(x)
	# Enveloppe lissée pour mesurer l'attaque et la durée utile.
	win = max(int(sr * 0.001), 1)
	smooth = np.convolve(env, np.ones(win) / win, mode="same")
	thr = peak * 0.1
	idx = np.nonzero(smooth > thr)[0]
	start = float(idx[0] / sr) if len(idx) else 0.0
	end = float(idx[-1] / sr) if len(idx) else 0.0
	imax = int(np.argmax(smooth))
	above = np.nonzero(smooth[: imax + 1] > peak * 0.9)[0]
	attack = float((above[0] if len(above) else imax) / sr)
	crest = 20 * np.log10(peak / rms + 1e-12)
	f, ts, S = signal.spectrogram(x, sr, nperseg=1024, noverlap=768)
	cent = []
	for k in range(4):
		a = k * len(ts) // 4
		b = max((k + 1) * len(ts) // 4, a + 1)
		col = S[:, a:b].mean(axis=1)
		cent.append(float(np.sum(f * col) / (np.sum(col) + 1e-12)))
	# Couture de boucle : pour les nappes (>= 8 s), la jonction fin -> début
	# ne doit pas produire de discontinuité audible.
	seam = 0.0
	if path.name.startswith("amb_"):      # uniquement les nappes bouclées
		# On compare le saut de couture au pas moyen *juste avant* la fin :
		# comparer au milieu du fichier pénalise les nappes dont le niveau varie.
		d_loc = float(np.mean(np.abs(np.diff(x[int(len(x) - 0.5 * sr):]))))
		seam = float(abs(x[0] - x[-1]) / (d_loc + 1e-12))
	return {
		"seam": seam,
		"path": str(path.relative_to(AUDIO_ROOT)),
		"sr": sr,
		"dur": len(x) / sr,
		"utile": end - start,
		"tete": start,
		"peak": peak,
		"rms_db": 20 * np.log10(rms),
		"crest": crest,
		"attack": attack,
		"cent": cent,
	# La musique a le droit de mettre une seconde à s'installer ; un one-shot non.
	"ok": (peak <= 1.001 and start < (2.0 if "music" in str(path) else 0.12)
		   and len(x) / sr > 0.02 and np.isfinite(rms) and seam < 8.0),
	}


def main() -> None:
	sub = sys.argv[1] if len(sys.argv) > 1 else ""
	base = AUDIO_ROOT / sub if sub else AUDIO_ROOT
	files = sorted(p for p in base.rglob("*.ogg"))
	print("%-42s %6s %6s %6s %7s %6s %6s %6s  %s" % (
		"fichier", "dur", "utile", "tête", "rms dB", "crête", "atk", "couture",
		"centres (4 fenêtres) Hz"))
	bad = 0
	for p in files:
		r = analyse(p)
		flag = "  " if r["ok"] else "!!"
		if not r["ok"]:
			bad += 1
		print("%s%-40s %6.2f %6.2f %6.3f %7.1f %6.1f %6.3f %6.1f  %s" % (
			flag, r["path"][:40], r["dur"], r["utile"], r["tete"],
			r["rms_db"], r["crest"], r["attack"], r["seam"],
			" ".join("%5.0f" % c for c in r["cent"])))
	print("\n%d fichier(s), %d hors tolérance." % (len(files), bad))


if __name__ == "__main__":
	main()
