"""D-4 — Le soundscape de la maison.

Deux familles :
1. Les « ticks » : craquements et tuyaux, joués en 3D autour du joueur à
   intervalles aléatoires (l'AudioManager choisit et place).
2. Les couches (set_layer) : nappes bouclées sans couture, pilotées par
   `house_attention_changed` :
     house_base    la maison au repos (0-20)
     house_unease  l'inquiétude (20-45)
     house_dread   la cave (45+)
     exterior      dehors : vent, bruine, cour

Aucune nappe ne doit attirer l'attention par elle-même : tout est en dessous
du dialogue et des pas. Le but est qu'on ne remarque le silence que quand il
s'arrête.
"""

from __future__ import annotations

import numpy as np

from common import (
	SR, bp, click, exp_decay, hp, lp, loopitize, make_ir, noise, reverb,
	rng_for, sweep, t_axis, tone, write,
)

LOOP_S = 12.0
FADE = int(1.5 * SR)


def _place(dst: np.ndarray, x: np.ndarray, t0: float) -> np.ndarray:
	i = max(int(t0 * SR), 0)
	j = min(len(dst), i + len(x))
	if i < len(dst):
		dst[i:j] += x[: j - i]
	return dst


# ------------------------------------------------------------- les craquements

def _creak(seed: int, f_start: float, f_end: float, dur: float, rattle: float, amp: float) -> np.ndarray:
	"""Craquement de bois : un stick-slip qui glisse et tremble."""
	rng = rng_for(seed)
	n = int(dur * SR)
	t = t_axis(n)
	x = sweep(f_start, f_end, n, curve="lin")
	# Le tremblement : c'est ce qui fait entendre « du bois qui travaille ».
	trem = 0.45 + 0.55 * np.abs(np.sin(2 * np.pi * rattle * t + rng.uniform(0, 6)))
	# Des micro-accrocs irréguliers.
	for _ in range(int(rattle * dur * 1.6)):
		ti = rng.uniform(0, dur * 0.95)
		i = int(ti * SR)
		j = min(n, i + int(0.012 * SR))
		if j > i:
			x[i:j] *= np.linspace(1.0, 0.25, j - i)[: j - i]
	x *= trem * exp_decay(n, dur * 0.42)
	x += 0.30 * bp(noise(n, rng), 300, 2600, order=2) * exp_decay(n, dur * 0.30)
	_place_out = x * amp
	return _place_out


def house_creak_01() -> np.ndarray:
	"""Long grincement : une poutre, quelque part au-dessus."""
	return _creak(6101, 165, 232, 1.25, 13.0, 0.9)


def house_creak_02() -> np.ndarray:
	"""Craquement sec : un plancher, net."""
	rng = rng_for(6102)
	x = _creak(6102, 320, 260, 0.32, 34.0, 1.0)
	n = int(0.45 * SR)
	out = np.zeros(n)
	_place(out, click(int(0.06 * SR), rng, tau=0.006, lo=700, hi=5000, amp=0.42), 0.0)
	_place(out, x, 0.005)
	_place(out, tone([190, 430], [0.22, 0.12], [0.09, 0.05], int(0.30 * SR), rng), 0.01)
	return out


def house_creak_03() -> np.ndarray:
	"""Gémissement grave : la charpente, très lent."""
	return _creak(6103, 96, 118, 2.10, 7.0, 1.0)


def _pipe_knock(seed: int) -> np.ndarray:
	"""Coup de marteau dans une canalisation : ça sonne et ça résonne."""
	rng = rng_for(seed)
	n = int(1.30 * SR)
	out = np.zeros(n)
	d = int(0.5 * SR)
	# Le choc, métallique.
	_place(out, click(d, rng, tau=0.004, lo=1500, hi=9000, amp=0.55), 0.0)
	# Les modes du tuyau (partiels non harmoniques).
	partials = [1.0, 2.41, 3.86, 5.12, 6.83]
	amps = [0.5, 0.34, 0.22, 0.13, 0.07]
	taus = [0.55, 0.38, 0.26, 0.18, 0.12]
	f0 = rng.uniform(340, 430)
	sig = np.zeros(d)
	t = t_axis(d)
	for p, a, tau in zip(partials, amps, taus):
		sig += a * np.sin(2 * np.pi * f0 * p * t + rng.uniform(0, 6)) * exp_decay(d, tau)
	_place(out, 0.55 * sig, 0.0)
	# L'eau qui repart dans le tuyau : un glouglou amorti.
	gurg = bp(noise(int(0.55 * SR), rng), 200, 1400, order=2) * exp_decay(int(0.55 * SR), 0.20)
	gurg *= 0.6 + 0.4 * np.sin(2 * np.pi * 9.0 * t_axis(int(0.55 * SR)))
	_place(out, 0.16 * gurg, 0.06)
	ir = make_ir(0.85, 0.26, bright=3200, rng=rng_for(seed + 1))
	return reverb(out, ir, mix=0.24)


def house_pipe_01() -> np.ndarray:
	return _pipe_knock(6201)


def house_pipe_02() -> np.ndarray:
	"""Variante : plus aiguë, plus courte, plus sèche."""
	rng = rng_for(6202)
	n = int(0.85 * SR)
	out = np.zeros(n)
	d = int(0.35 * SR)
	_place(out, click(d, rng, tau=0.003, lo=2200, hi=11000, amp=0.50), 0.0)
	t = t_axis(d)
	f0 = 620.0
	sig = np.zeros(d)
	for p, a, tau in zip([1.0, 2.58, 4.10], [0.45, 0.26, 0.12], [0.30, 0.20, 0.12]):
		sig += a * np.sin(2 * np.pi * f0 * p * t + rng.uniform(0, 6)) * exp_decay(d, tau)
	_place(out, 0.5 * sig, 0.0)
	ir = make_ir(0.60, 0.18, bright=4200, rng=rng_for(6203))
	return reverb(out, ir, mix=0.22)


def clock_chime_distant() -> np.ndarray:
	"""Une pendule sonne dans une autre pièce : deux coups, étouffés."""
	rng = rng_for(6301)
	n = int(4.60 * SR)
	out = np.zeros(n)
	for t0 in (0.0, 1.45):
		d = int(2.4 * SR)
		t = t_axis(d)
		f0 = 523.25 * (1.0 + rng.uniform(-0.004, 0.004))
		# Cloche : partiels inharmoniques.
		partials = [1.0, 2.0, 2.76, 5.40, 8.93]
		amps = [0.34, 0.30, 0.42, 0.18, 0.09]
		taus = [1.30, 0.95, 0.80, 0.45, 0.28]
		sig = np.zeros(d)
		for p, a, tau in zip(partials, amps, taus):
			sig += a * np.sin(2 * np.pi * f0 * p * t) * exp_decay(d, tau)
		sig += 0.10 * click(d, rng, tau=0.004, lo=3000, hi=12000, amp=0.5)  # le marteau
		_place(out, sig, t0)
	# Étouffé par la distance et les murs : passe-bas + réverbe lointaine.
	out = lp(out, 1900, order=2)
	ir = make_ir(1.60, 0.45, bright=1600, rng=rng_for(6302))
	return reverb(out, ir, mix=0.40)


# ----------------------------------------------------------------- les nappes

def _loop(n_more: float = 1.6):
	"""Fabrique le buffer d'une nappe : LOOP_S secondes + marge de bouclage."""
	return int((LOOP_S + n_more) * SR)


def amb_house_base() -> np.ndarray:
	"""La maison au repos : un souffle grave, le 50 Hz de l'installation
	électrique, le vent dehors, et presque rien d'autre."""
	rng = rng_for(6401)
	n = _loop()
	t = t_axis(n)
	out = np.zeros(n)
	# Grondement de fond (la maison, le vent lointain).
	rumble = lp(noise(n, rng), 110, order=2)
	rumble *= 0.85 + 0.15 * np.sin(2 * np.pi * 0.07 * t) + 0.08 * np.sin(2 * np.pi * 0.023 * t)
	out += 0.55 * rumble
	# Léger courant d'air dans les pièces.
	air = bp(noise(n, rng), 180, 900, order=2)
	air *= 0.7 + 0.3 * np.sin(2 * np.pi * 0.041 * t + 1.1)
	out += 0.20 * air
	# Le 50 Hz du réseau : très bas, il donne la sensation « ça vit ».
	out += 0.030 * np.sin(2 * np.pi * 50.0 * t) + 0.014 * np.sin(2 * np.pi * 100.0 * t)
	out += 0.008 * np.sin(2 * np.pi * 150.0 * t)
	# Deux ou trois micro-bruits de structure dans la boucle.
	for _ in range(3):
		ti = rng.uniform(0.5, LOOP_S - 0.5)
		_place(out, 0.10 * _creak(int(rng.uniform(1, 9999)), 150, 190, 0.5, 11.0, 0.5), ti)
	return loopitize(out, int(LOOP_S * SR), FADE)


def amb_house_unease() -> np.ndarray:
	"""L'inquiétude : la maison respire un peu trop fort. Des lentes montées,
	un battement grave, un tic-tac à peine audible."""
	rng = rng_for(6501)
	n = _loop()
	t = t_axis(n)
	out = np.zeros(n)
	# Nappe qui monte et descend très lentement.
	swell = bp(noise(n, rng), 90, 700, order=2)
	env = 0.45 + 0.55 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.055 * t - 1.2))
	out += 0.42 * swell * env
	# Battement : deux graves très proches.
	beat = np.sin(2 * np.pi * 47.0 * t) + np.sin(2 * np.pi * 48.6 * t)
	out += 0.055 * beat * (0.6 + 0.4 * np.sin(2 * np.pi * 0.031 * t))
	# Souffle aigu : presque un sifflement d'oreille.
	hiss = bp(noise(n, rng), 2600, 6500, order=2)
	hiss *= 0.25 + 0.75 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.037 * t + 2.0))
	out += 0.030 * hiss
	# Un tic-tac lointain et irrégulier (ce n'est pas une horloge fiable).
	for k in range(9):
		ti = 0.4 + k * 1.31 + rng.uniform(-0.06, 0.06)
		if ti > LOOP_S - 0.2:
			break
		_place(out, 0.05 * click(int(0.02 * SR), rng, tau=0.0015, lo=1800, hi=7000, amp=1.0), ti)
	return loopitize(out, int(LOOP_S * SR), FADE)


def amb_house_dread() -> np.ndarray:
	"""La cave : un infra-grave, un métal qui travaille, un souffle rauque.
	C'est la couche la plus présente — mais jamais agressive."""
	rng = rng_for(6601)
	n = _loop()
	t = t_axis(n)
	out = np.zeros(n)
	# Infra : ça se sent plus que ça ne s'entend.
	out += 0.30 * np.sin(2 * np.pi * 31.0 * t + 0.3)
	out += 0.22 * np.sin(2 * np.pi * 38.7 * t + 1.7) * (0.7 + 0.3 * np.sin(2 * np.pi * 0.045 * t))
	out += 0.10 * lp(noise(n, rng), 55, order=2)
	# Bas-médium : pour qu'on l'entende aussi sur un portable (chez soi,
	# l'infra de 31 Hz passe à la trappe).
	out += 0.085 * bp(noise(n, rng), 150, 430, order=2) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.045 * t))
	out += 0.05 * np.sin(2 * np.pi * 78.0 * t + 2.2) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.021 * t))
	# Souffle rauque, comme une respiration lointaine.
	breath = bp(noise(n, rng), 120, 1100, order=2)
	env = np.clip(np.sin(2 * np.pi * 0.075 * t), 0, 1) ** 1.5
	out += 0.16 * breath * env
	# Un métal qui travaille : un grincement très étiré.
	out += 0.05 * sweep(190, 210, n, curve="lin") * (0.4 + 0.6 * np.abs(np.sin(2 * np.pi * 0.019 * t)))
	# Gouttes d'eau, rares.
	for _ in range(4):
		ti = rng.uniform(0.5, LOOP_S - 0.5)
		_place(out, 0.10 * click(int(0.05 * SR), rng, tau=0.004, lo=900, hi=5000, amp=0.7), ti)
	return loopitize(out, int(LOOP_S * SR), FADE)


def amb_exterior() -> np.ndarray:
	"""Dehors : le vent dans les arbres, une bruine, la cour. Et le calme
	relatif : c'est le seul endroit où la maison ne vous regarde pas."""
	rng = rng_for(6701)
	n = _loop()
	t = t_axis(n)
	out = np.zeros(n)
	# Vent : bruit filtré, lentement modulé.
	wind = bp(noise(n, rng), 120, 1800, order=2)
	env = 0.35 + 0.65 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.043 * t))
	env *= 0.8 + 0.2 * np.sin(2 * np.pi * 0.017 * t + 2.0)
	out += 0.45 * wind * env
	# Rafales : le vent passe dans les branches.
	gust = bp(noise(n, rng), 700, 5000, order=2)
	genv = np.clip(np.sin(2 * np.pi * 0.028 * t + 0.6), 0, 1) ** 2
	out += 0.16 * gust * genv
	# Bruine : un crépitement très fin et continu.
	rain = hp(noise(n, rng), 3200, order=2)
	out += 0.055 * rain
	# Un chien, très loin ? Non : juste une branche, de temps en temps.
	for _ in range(2):
		ti = rng.uniform(1.0, LOOP_S - 1.0)
		_place(out, 0.10 * _creak(int(rng.uniform(1, 9999)), 240, 300, 0.35, 26.0, 0.5), ti)
	return loopitize(out, int(LOOP_S * SR), FADE)


SOUNDS = {
	"house/house_creak_01.ogg": (house_creak_01, -4.0),
	"house/house_creak_02.ogg": (house_creak_02, -4.0),
	"house/house_creak_03.ogg": (house_creak_03, -4.0),
	"house/house_pipe_01.ogg": (house_pipe_01, -5.0),
	"house/house_pipe_02.ogg": (house_pipe_02, -6.0),
	"house/clock_chime_distant.ogg": (clock_chime_distant, -8.0),
	"house/amb_house_base.ogg": (amb_house_base, -14.0),
	"house/amb_house_unease.ogg": (amb_house_unease, -16.0),
	"house/amb_house_dread.ogg": (amb_house_dread, -16.0),
	"house/amb_exterior.ogg": (amb_exterior, -14.0),
}


def main() -> None:
	print("D-4 — soundscape de la maison")
	for path, (fn, peak) in SOUNDS.items():
		write(path, fn(), peak_db=peak, floor_db=-75.0)


if __name__ == "__main__":
	main()
