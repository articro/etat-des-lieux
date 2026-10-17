"""D-3 — Le corps de Camille : pas par matériau, souffle, sac.

Convention (docs/audio_conventions.md) : le Niveau pose `metadata/surface` sur
les StaticBody3D (ou un parent) ; l'AudioManager fait un rayon vers le bas
depuis `EventBus.player_noise` et choisit `footstep_<surface>`.

Matériaux V1 : wood (parquet), tile (carrelage), carpet (moquette),
gravel (cour), stone (cave). Quatre variantes par matériau : le jeu alterne
aléatoirement et module la hauteur, donc jamais deux pas identiques.
"""

from __future__ import annotations

import numpy as np

from common import (
	SR, bp, click, exp_decay, make_ir, noise, reverb, rng_for, sweep,
	t_axis, tone, write,
)

DUR = 0.38


def _place(dst: np.ndarray, x: np.ndarray, t0: float) -> np.ndarray:
	i = int(t0 * SR)
	j = min(len(dst), i + len(x))
	if i < len(dst):
		dst[i:j] += x[: j - i]
	return dst


def _scuff(rng, n: int, t0: float, lo: float, hi: float, tau: float, amp: float) -> np.ndarray:
	"""Frottement de semelle : un bruit filtré très court."""
	d = int(n * SR) if n < 1 else n
	x = bp(noise(int(0.12 * SR), rng), lo, hi, order=2) * exp_decay(int(0.12 * SR), tau)
	out = np.zeros(int(DUR * SR))
	return _place(out, amp * x, t0)


def _step(material: str, seed: int) -> np.ndarray:
	rng = rng_for(seed)
	n = int(DUR * SR)
	out = np.zeros(n)
	# Léger décalage et variation de hauteur : chaque pas est unique.
	det = rng.uniform(-0.09, 0.09)

	if material == "wood":
		# Parquet : le talon cogne, le plancher répond, la semelle frotte.
		d = int(0.14 * SR)
		heel = tone([95, 168], [0.55, 0.30], [0.045, 0.030], d, rng, detune=det)
		heel += click(d, rng, tau=0.008, lo=400, hi=3000, amp=0.24)
		heel += tone([285, 520], [0.30, 0.16], [0.060, 0.035], d, rng, detune=det)
		_place(out, heel, 0.0)
		out += _scuff(rng, 0, 0.055, 500, 2500, 0.030, 0.15)
		if rng.random() < 0.4:      # une lame qui grince, parfois
			c = sweep(190, 245, int(0.30 * SR)) * exp_decay(int(0.30 * SR), 0.17)
			_place(out, 0.05 * c, 0.020)
		ir = make_ir(0.35, 0.11, bright=3000, rng=rng_for(seed + 7))
		return reverb(out, ir, mix=0.16)

	if material == "tile":
		# Carrelage : clair, sec, ça résonne un peu.
		d = int(0.16 * SR)
		heel = click(d, rng, tau=0.005, lo=1500, hi=7000, amp=0.48)
		heel += tone([1100, 2400, 3600], [0.28, 0.17, 0.08], [0.030, 0.018, 0.010], d, rng, detune=det)
		heel += tone([120], [0.34], [0.035], d, rng, detune=det)
		_place(out, heel, 0.0)
		out += _scuff(rng, 0, 0.048, 800, 4000, 0.020, 0.11)
		ir = make_ir(0.50, 0.16, bright=7000, rng=rng_for(seed + 7),
					 taps=[(0.008, 0.42), (0.015, 0.30), (0.024, 0.20)])
		return reverb(out, ir, mix=0.26)

	if material == "carpet":
		# Moquette : sourd, aucun claquement, presque pas de queue.
		d = int(0.14 * SR)
		heel = tone([85, 150], [0.60, 0.24], [0.050, 0.030], d, rng, detune=det)
		heel += click(d, rng, tau=0.010, lo=150, hi=1200, amp=0.10)
		_place(out, heel, 0.0)
		x = bp(noise(int(0.14 * SR), rng), 200, 1200, order=2) * exp_decay(int(0.14 * SR), 0.045)
		_place(out, 0.34 * x, 0.030)
		ir = make_ir(0.22, 0.07, bright=1800, rng=rng_for(seed + 7))
		return reverb(out, ir, mix=0.06)

	if material == "gravel":
		# Gravier : le talon enfonce, les cailloux croustillent.
		d = int(0.14 * SR)
		heel = tone([90, 140], [0.34, 0.17], [0.040, 0.025], d, rng, detune=det)
		_place(out, heel, 0.0)
		crunch = bp(noise(int(0.22 * SR), rng), 700, 6000, order=2)
		crunch *= exp_decay(int(0.22 * SR), 0.075)
		crunch *= 0.55 + 0.45 * np.abs(np.sin(2 * np.pi * 47.0 * t_axis(int(0.22 * SR))
											  + rng.uniform(0, 6)))
		_place(out, 0.30 * crunch, 0.010)
		for _ in range(22):     # les grains qui roulent
			ti = rng.uniform(0.015, 0.230)
			_place(out, click(int(0.02 * SR), rng, tau=0.0035, lo=1200, hi=9000,
							  amp=rng.uniform(0.03, 0.11)), ti)
		ir = make_ir(0.28, 0.08, bright=5000, rng=rng_for(seed + 7))
		return reverb(out, ir, mix=0.09)

	# stone : la cave. Plus lourd, et la pièce répond longtemps.
	d = int(0.18 * SR)
	heel = tone([70, 130], [0.50, 0.28], [0.070, 0.048], d, rng, detune=det)
	heel += click(d, rng, tau=0.007, lo=800, hi=6000, amp=0.28)
	_place(out, heel, 0.0)
	out += _scuff(rng, 0, 0.052, 400, 3000, 0.030, 0.14)
	ir = make_ir(0.95, 0.30, bright=2500, rng=rng_for(seed + 7),
				 taps=[(0.013, 0.40), (0.027, 0.32), (0.041, 0.22), (0.058, 0.14)])
	return reverb(out, ir, mix=0.30)


def footstep(material: str, index: int) -> np.ndarray:
	return _step(material, hash((material, index)) % 100000 + 2000)


# ----------------------------------------------------------------- souffle

def breath(kind: str) -> np.ndarray:
	"""Respiration de Camille. `in` : inspiration nette par le nez ;
	`out` : expiration plus longue et plus sombre."""
	rng = rng_for(3100 if kind == "in" else 3200)
	n = int((0.85 if kind == "in" else 1.05) * SR)
	t = t_axis(n)
	x = noise(n, rng)
	if kind == "in":
		env = np.clip(t / 0.20, 0, 1) ** 1.3 * np.clip((0.72 - t) / 0.28, 0, 1) ** 1.1
		x = bp(x, 480, 3200, order=2)
		x *= env
		x += 0.10 * bp(noise(n, rng), 900, 5000, order=2) * env   # pointe du souffle
	else:
		env = np.clip(t / 0.13, 0, 1) ** 0.9 * np.clip((0.95 - t) / 0.55, 0, 1) ** 1.2
		x = bp(x, 240, 1500, order=2)
		x *= env * 1.15
		x += 0.05 * tone([118, 176], [1.0, 0.4], [0.30, 0.20], n, rng)  # un peu de gorge
	# Résonance de la gorge / du masque : deux formants discrets.
	x += 0.18 * bp(x, 600, 900, order=2)
	x += 0.10 * bp(x, 1050, 1350, order=2)
	return 0.9 * x


# -------------------------------------------------------------------- sac

def bag_leather() -> np.ndarray:
	"""Le sac en cuir contre la hanche : crissement, toile,petits à-coups."""
	rng = rng_for(3300)
	n = int(0.42 * SR)
	out = np.zeros(n)
	# Crissement du cuir : une résonance qui glisse et tremble.
	t = t_axis(int(0.30 * SR))
	glide = sweep(880, 1560, len(t))
	glide *= exp_decay(len(t), 0.10) * (0.75 + 0.25 * np.sin(2 * np.pi * 34.0 * t))
	_place(out, 0.20 * glide, 0.010)
	# Micro-à-coups de la sangle.
	for _ in range(7):
		_place(out, click(int(0.02 * SR), rng, tau=0.0025, lo=1500, hi=8000,
						  amp=rng.uniform(0.03, 0.09)), rng.uniform(0.01, 0.30))
	# Toile qui frotte.
	x = bp(noise(int(0.25 * SR), rng), 800, 4200, order=2) * exp_decay(int(0.25 * SR), 0.075)
	_place(out, 0.13 * x, 0.02)
	return out


MATERIALS = ["wood", "tile", "carpet", "gravel", "stone"]


def main() -> None:
	print("D-3 — pas, souffle, sac")
	for m in MATERIALS:
		for i in range(1, 5):
			write("player/footstep_%s_%02d.ogg" % (m, i), _step(m, hash((m, i)) % 99991 + 2000),
				  peak_db=-2.0)
	write("player/breath_in.ogg", breath("in"), peak_db=-6.0)
	write("player/breath_out.ogg", breath("out"), peak_db=-6.0)
	write("player/bag_leather.ogg", bag_leather(), peak_db=-8.0)


if __name__ == "__main__":
	main()
