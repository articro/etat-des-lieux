"""Sons d'interaction (D-3, complément) : ouvrir, prendre, lire, brûler.

Ces sons sont déclenchés par l'AudioManager lui-même, qui écoute
`EventBus.player_interacted(target_id, kind)` : aucun autre module n'a besoin
de les connaître (voir docs/audio_conventions.md).
"""

from __future__ import annotations

import numpy as np

from common import (
	SR, bp, click, exp_decay, hp, lp, make_ir, noise, reverb, rng_for,
	sweep, t_axis, tone, write,
)


def _place(dst: np.ndarray, x: np.ndarray, t0: float) -> np.ndarray:
	i = max(int(t0 * SR), 0)
	j = min(len(dst), i + len(x))
	if i < len(dst):
		dst[i:j] += x[: j - i]
	return dst


def drawer_open() -> np.ndarray:
	"""Tiroir de bois : ça frotte sur les coulisses, puis ça bute."""
	rng = rng_for(4100)
	n = int(0.62 * SR)
	t = t_axis(n)
	out = np.zeros(n)
	# Poignée : un petit claquement pour démarrer.
	_place(out, click(int(0.05 * SR), rng, tau=0.006, lo=600, hi=5000, amp=0.30), 0.0)
	# Glissement : bruit de bois modulé par les rouleaux (~18 Hz).
	slide = bp(noise(n, rng), 180, 1300, order=2)
	env = np.clip(t / 0.06, 0, 1) * np.clip((0.50 - t) / 0.16, 0, 1)
	slide *= env * (0.75 + 0.25 * np.sin(2 * np.pi * 18.0 * t))
	out += 0.42 * slide
	# Grincement léger du bois.
	_place(out, 0.05 * sweep(240, 300, int(0.35 * SR)) * exp_decay(int(0.35 * SR), 0.15), 0.10)
	# Butée de fin de course.
	d = int(0.16 * SR)
	_place(out, click(d, rng, tau=0.007, lo=400, hi=4000, amp=0.35)
		   + tone([190, 420], [0.40, 0.20], [0.055, 0.030], d, rng), 0.455)
	ir = make_ir(0.34, 0.11, bright=3200, rng=rng_for(4101))
	return reverb(out, ir, mix=0.16)


def door_open() -> np.ndarray:
	"""Porte : loquet, gonds qui grincent, puis le vide derrière."""
	rng = rng_for(4200)
	n = int(1.05 * SR)
	t = t_axis(n)
	out = np.zeros(n)
	_place(out, click(int(0.04 * SR), rng, tau=0.005, lo=1200, hi=8000, amp=0.32), 0.0)
	# Gonds : une résonance qui monte et tremble (stick-slip).
	m = int(0.72 * SR)
	tm = t_axis(m)
	creak = sweep(410, 620, m)
	creak *= exp_decay(m, 0.32) * (0.65 + 0.35 * np.abs(np.sin(2 * np.pi * 8.5 * tm)))
	creak += 0.30 * bp(noise(m, rng), 700, 2600, order=2) * exp_decay(m, 0.22)
	_place(out, 0.22 * creak, 0.06)
	# Air déplacé.
	air = bp(noise(int(0.55 * SR), rng), 90, 700, order=2) * exp_decay(int(0.55 * SR), 0.24)
	_place(out, 0.16 * air, 0.30)
	ir = make_ir(0.60, 0.18, bright=2600, rng=rng_for(4201))
	return reverb(out, ir, mix=0.22)


def door_close() -> np.ndarray:
	"""Porte qui se ferme : elle claque mollement, la maison encaisse."""
	rng = rng_for(4300)
	n = int(0.62 * SR)
	out = np.zeros(n)
	air = bp(noise(int(0.30 * SR), rng), 80, 600, order=2) * exp_decay(int(0.30 * SR), 0.13)
	_place(out, 0.30 * air, 0.01)
	d = int(0.30 * SR)
	# Le battant contre le cadre.
	_place(out, click(d, rng, tau=0.010, lo=200, hi=3000, amp=0.55)
		   + tone([85, 155, 320], [0.60, 0.32, 0.16], [0.090, 0.055, 0.030], d, rng), 0.13)
	# Loquet : un clac net par-dessus.
	_place(out, click(int(0.06 * SR), rng, tau=0.004, lo=1800, hi=9000, amp=0.34), 0.155)
	# La vibration du cadre, puis la pièce.
	_place(out, 0.10 * tone([62, 118], [1.0, 0.4], [0.20, 0.13], int(0.40 * SR), rng), 0.15)
	ir = make_ir(0.70, 0.20, bright=2800, rng=rng_for(4301),
				 taps=[(0.012, 0.38), (0.026, 0.26), (0.044, 0.16)])
	return reverb(out, ir, mix=0.26)


def interact_open() -> np.ndarray:
	"""Ouverture générique : un objet qu'on soulève, sec et court."""
	rng = rng_for(4400)
	n = int(0.40 * SR)
	out = np.zeros(n)
	d = int(0.14 * SR)
	_place(out, click(d, rng, tau=0.006, lo=500, hi=4000, amp=0.40)
		   + tone([260, 640], [0.32, 0.18], [0.045, 0.028], d, rng), 0.0)
	x = bp(noise(int(0.18 * SR), rng), 300, 2200, order=2) * exp_decay(int(0.18 * SR), 0.055)
	_place(out, 0.18 * x, 0.02)
	ir = make_ir(0.32, 0.10, bright=3000, rng=rng_for(4401))
	return reverb(out, ir, mix=0.15)


def interact_pickup() -> np.ndarray:
	"""Prendre un objet : contact des doigts, l'objet bouge un peu."""
	rng = rng_for(4500)
	n = int(0.34 * SR)
	out = np.zeros(n)
	_place(out, click(int(0.05 * SR), rng, tau=0.004, lo=900, hi=6000, amp=0.28), 0.0)
	x = bp(noise(int(0.20 * SR), rng), 600, 3500, order=2) * exp_decay(int(0.20 * SR), 0.045)
	_place(out, 0.30 * x, 0.015)
	d = int(0.12 * SR)
	_place(out, tone([180, 380], [0.20, 0.10], [0.040, 0.025], d, rng), 0.02)
	return reverb(out, make_ir(0.24, 0.08, bright=2800, rng=rng_for(4501)), mix=0.12)


def interact_paper() -> np.ndarray:
	"""Manipuler un papier : ça bruisse, sec."""
	rng = rng_for(4600)
	n = int(0.48 * SR)
	t = t_axis(n)
	out = bp(noise(n, rng), 1800, 8000, order=2)
	env = np.clip(t / 0.05, 0, 1) * np.clip((0.44 - t) / 0.30, 0, 1)
	out *= env
	for _ in range(10):
		_place(out, click(int(0.02 * SR), rng, tau=0.002, lo=2500, hi=9500,
						  amp=rng.uniform(0.05, 0.14)), rng.uniform(0.02, 0.42))
	return 0.85 * out


def interact_generic() -> np.ndarray:
	"""Contact neutre : un tout petit clac, presque rien."""
	rng = rng_for(4700)
	n = int(0.22 * SR)
	out = np.zeros(n)
	_place(out, click(int(0.06 * SR), rng, tau=0.005, lo=700, hi=5000, amp=0.35), 0.0)
	_place(out, tone([420], [0.16], [0.028], int(0.08 * SR), rng), 0.0)
	return out


def fire_start() -> np.ndarray:
	"""Le carnet dans le poêle : l'air s'engouffre, le papier prend."""
	rng = rng_for(4800)
	n = int(1.30 * SR)
	t = t_axis(n)
	out = np.zeros(n)
	# Souffle d'air dans le foyer.
	air = bp(noise(n, rng), 90, 1100, order=2)
	env = np.clip(t / 0.14, 0, 1) * np.clip((1.20 - t) / 0.60, 0, 1)
	out += 0.34 * air * env
	# Le feu qui démarre : crépitements de plus en plus nombreux.
	for i in range(46):
		ti = rng.uniform(0.10, 1.22)
		gain = 0.25 + 0.75 * np.clip((ti - 0.10) / 0.7, 0, 1)
		_place(out, click(int(0.02 * SR), rng, tau=0.0022, lo=1400, hi=9500,
						  amp=rng.uniform(0.02, 0.10) * gain), ti)
	# Grondement grave.
	rumble = lp(noise(int(1.0 * SR), rng), 220, order=2) * exp_decay(int(1.0 * SR), 0.55)
	_place(out, 0.22 * rumble, 0.12)
	ir = make_ir(0.55, 0.16, bright=2200, rng=rng_for(4801))
	return reverb(out, ir, mix=0.18)


def flashlight_click() -> np.ndarray:
	"""Interrupteur de la lampe : plastique sec, tout petit."""
	rng = rng_for(4900)
	n = int(0.10 * SR)
	out = np.zeros(n)
	_place(out, click(int(0.03 * SR), rng, tau=0.0025, lo=2000, hi=9000, amp=0.55), 0.0)
	_place(out, tone([1500, 3100], [0.22, 0.10], [0.010, 0.007], int(0.04 * SR), rng), 0.001)
	_place(out, click(int(0.02 * SR), rng, tau=0.002, lo=1200, hi=6000, amp=0.18), 0.022)
	return out


def notebook_open() -> np.ndarray:
	"""Le carnet s'ouvre : carton, dos qui craque, pages."""
	rng = rng_for(5001)
	n = int(0.62 * SR)
	out = np.zeros(n)
	_place(out, 0.18 * sweep(320, 260, int(0.24 * SR)) * exp_decay(int(0.24 * SR), 0.10), 0.02)
	x = bp(noise(int(0.30 * SR), rng), 1500, 7000, order=2) * exp_decay(int(0.30 * SR), 0.09)
	_place(out, 0.34 * x, 0.06)
	x2 = bp(noise(int(0.22 * SR), rng), 400, 2000, order=2) * exp_decay(int(0.22 * SR), 0.07)
	_place(out, 0.26 * x2, 0.02)
	for _ in range(8):
		_place(out, click(int(0.02 * SR), rng, tau=0.002, lo=2000, hi=8500,
						  amp=rng.uniform(0.03, 0.09)), rng.uniform(0.05, 0.45))
	return out


def notebook_close() -> np.ndarray:
	"""Le carnet se referme : un petit choc mou, les pages qui se tassent."""
	rng = rng_for(5002)
	n = int(0.46 * SR)
	out = np.zeros(n)
	d = int(0.16 * SR)
	_place(out, click(d, rng, tau=0.008, lo=300, hi=3000, amp=0.40)
		   + tone([150, 330], [0.34, 0.16], [0.055, 0.032], d, rng), 0.0)
	x = bp(noise(int(0.26 * SR), rng), 1200, 6500, order=2) * exp_decay(int(0.26 * SR), 0.075)
	_place(out, 0.24 * x, 0.05)
	x2 = bp(noise(int(0.20 * SR), rng), 300, 1600, order=2) * exp_decay(int(0.20 * SR), 0.06)
	_place(out, 0.20 * x2, 0.02)
	return out


def pencil_check() -> np.ndarray:
	"""Crayon sur le papier : trois petits traits, puis la coche."""
	rng = rng_for(5003)
	n = int(0.52 * SR)
	out = np.zeros(n)
	for k, t0 in enumerate([0.02, 0.16, 0.30]):
		d = int(0.14 * SR)
		s = bp(noise(d, rng), 1200, 6500, order=2)
		env = np.clip(t_axis(d) / 0.02, 0, 1) * exp_decay(d, 0.045)
		seg = s * env * (0.55 + 0.45 * np.abs(np.sin(2 * np.pi * 38.0 * t_axis(d))))
		_place(out, 0.42 * seg, t0)
		_place(out, click(int(0.02 * SR), rng, tau=0.002, lo=2000, hi=9000, amp=0.10), t0 + 0.10)
	return out


SOUNDS = {
	"interact/drawer_open.ogg": (drawer_open, -3.0),
	"interact/door_open.ogg": (door_open, -3.0),
	"interact/door_close.ogg": (door_close, -2.0),
	"interact/interact_open.ogg": (interact_open, -4.0),
	"interact/interact_pickup.ogg": (interact_pickup, -5.0),
	"interact/interact_paper.ogg": (interact_paper, -6.0),
	"interact/interact_generic.ogg": (interact_generic, -6.0),
	"interact/fire_start.ogg": (fire_start, -4.0),
	"interact/flashlight_click.ogg": (flashlight_click, -5.0),
	"interact/notebook_open.ogg": (notebook_open, -5.0),
	"interact/notebook_close.ogg": (notebook_close, -5.0),
	"interact/pencil_check.ogg": (pencil_check, -6.0),
}


def main() -> None:
	print("D-3 — interactions")
	for path, (fn, peak) in SOUNDS.items():
		write(path, fn(), peak_db=peak)


if __name__ == "__main__":
	main()
