"""D-5 — La Présence : dix sons domestiques au mauvais endroit.

Règle du GDD §9 : **jamais** de « son de monstre ». La Présence s'annonce avec
des bruits de maison — une chaise tirée à l'étage, un robinet, quelqu'un qui
tourne les pages du carnet — mais jamais au bon endroit, jamais au bon moment.

Ces sons sont déclenchés par les règles de la maison (action `sfx:<id>`), donc
par HouseDirector, qui appelle `AudioManager.play_sfx(id)` sans position :
l'AudioManager place alors les ids `*_upstairs` / `*_above` 3,1 m au-dessus du
joueur (voir docs/audio_conventions.md).
"""

from __future__ import annotations

import numpy as np

from common import (
	SR, bp, click, exp_decay, hp, lp, loopitize, make_ir, noise, reverb,
	rng_for, sweep, t_axis, tone, write,
)


def _place(dst: np.ndarray, x: np.ndarray, t0: float) -> np.ndarray:
	i = max(int(t0 * SR), 0)
	j = min(len(dst), i + len(x))
	if i < len(dst):
		dst[i:j] += x[: j - i]
	return dst


def _through_ceiling(x: np.ndarray, rng, cutoff: float = 2000.0, mix: float = 0.28) -> np.ndarray:
	"""Ce qui vient d'au-dessus : les aigus ne passent pas, le grave si."""
	out = lp(x, cutoff, order=2)
	out = out + 0.35 * lp(x, 160.0, order=2)        # transmission par le plancher
	ir = make_ir(0.55, 0.17, bright=cutoff, rng=rng)
	return reverb(out, ir, mix=mix)


# ------------------------------------------------------------ à l'étage

def chair_drag_upstairs() -> np.ndarray:
	"""Une chaise qu'on tire, au-dessus. Le bois accroche, par à-coups."""
	rng = rng_for(7101)
	n = int(1.05 * SR)
	t = t_axis(n)
	out = np.zeros(n)
	# Frottement : bruit de bois modulé par les à-coups du pied qui accroche.
	scrape = bp(noise(n, rng), 260, 2100, order=2)
	env = np.clip(t / 0.05, 0, 1) * np.clip((0.85 - t) / 0.22, 0, 1)
	stick = 0.45 + 0.55 * np.abs(np.sin(2 * np.pi * 27.0 * t + rng.uniform(0, 6)))
	out += 0.55 * scrape * env * stick
	# Résonance du pied sur le plancher.
	res = sweep(210, 265, n, curve="lin") * exp_decay(n, 0.30)
	out += 0.10 * res * env
	# Le contact final : la chaise s'arrête.
	d = int(0.14 * SR)
	_place(out, click(d, rng, tau=0.007, lo=300, hi=2600, amp=0.30)
		   + tone([120, 260], [0.30, 0.15], [0.05, 0.03], d, rng), 0.83)
	return _through_ceiling(out, rng_for(7102))


def upstairs_chair() -> np.ndarray:
	"""Quelqu'un s'assoit, au-dessus. Le bois plie sous le poids."""
	rng = rng_for(7201)
	n = int(0.65 * SR)
	out = np.zeros(n)
	# Le corps qui descend : un souffle bref, puis le bois qui travaille.
	d = int(0.35 * SR)
	_place(out, 0.10 * sweep(180, 140, d, curve="lin") * exp_decay(d, 0.20), 0.02)
	# Le poids : un bruit sourd, transmis par le plancher.
	d2 = int(0.30 * SR)
	_place(out, tone([62, 105], [0.60, 0.28], [0.09, 0.05], d2, rng)
		   + click(d2, rng, tau=0.008, lo=150, hi=1200, amp=0.22), 0.16)
	# Le dossier qui bouge encore un peu.
	_place(out, 0.07 * sweep(240, 205, int(0.25 * SR), curve="lin")
		   * exp_decay(int(0.25 * SR), 0.14), 0.30)
	return _through_ceiling(out, rng_for(7202), cutoff=1800.0)


def footsteps_above() -> np.ndarray:
	"""Cinq pas lents, au-dessus. Réguliers. Trop réguliers."""
	rng = rng_for(7301)
	n = int(3.30 * SR)
	out = np.zeros(n)
	period = 0.62
	for k in range(5):
		t0 = 0.10 + k * period + rng.uniform(-0.02, 0.02)
		d = int(0.28 * SR)
		thump = tone([78, 132], [0.55, 0.26], [0.075, 0.045], d, rng, detune=0.05)
		thump += click(d, rng, tau=0.006, lo=250, hi=2200, amp=0.26)
		_place(out, thump, t0)
		# Une lame grince, de temps en temps.
		if rng.random() < 0.55:
			c = sweep(rng.uniform(170, 230), rng.uniform(200, 270), int(0.32 * SR), curve="lin")
			_place(out, 0.055 * c * exp_decay(int(0.32 * SR), 0.16), t0 + 0.03)
		# Traînée de semelle.
		x = bp(noise(int(0.10 * SR), rng), 300, 1800, order=2) * exp_decay(int(0.10 * SR), 0.035)
		_place(out, 0.10 * x, t0 + 0.06)
	return _through_ceiling(out, rng_for(7302), cutoff=1700.0, mix=0.32)


def door_close_upstairs() -> np.ndarray:
	"""Une porte se ferme, à l'étage. Personne n'est monté."""
	rng = rng_for(7401)
	n = int(0.95 * SR)
	out = np.zeros(n)
	# L'air, puis le battant.
	air = bp(noise(int(0.22 * SR), rng), 80, 500, order=2) * exp_decay(int(0.22 * SR), 0.10)
	_place(out, 0.24 * air, 0.0)
	d = int(0.35 * SR)
	_place(out, tone([70, 128, 300], [0.65, 0.30, 0.14], [0.11, 0.06, 0.03], d, rng)
		   + click(d, rng, tau=0.010, lo=150, hi=2000, amp=0.42), 0.11)
	# Le loquet, net.
	_place(out, click(int(0.06 * SR), rng, tau=0.004, lo=900, hi=5000, amp=0.30), 0.135)
	# Le cadre qui vibre.
	_place(out, 0.12 * tone([55], [1.0], [0.22], int(0.45 * SR), rng), 0.12)
	return _through_ceiling(out, rng_for(7402), cutoff=1900.0, mix=0.34)


# ------------------------------------------------------------- dans la maison

def phone_ring() -> np.ndarray:
	"""Le téléphone sonne dans l'entrée. Une sonnerie à gongs, 1973."""
	rng = rng_for(7501)
	n = int(2.70 * SR)
	out = np.zeros(n)
	for t0 in (0.0, 1.34):
		d = int(1.05 * SR)
		t = t_axis(d)
		# Deux gongs : partiels inharmoniques, frappés ~24 fois par seconde.
		sig = np.zeros(d)
		for f0, a0 in ((1046.0, 0.34), (1318.0, 0.26)):
			for p, a, tau in zip([1.0, 2.76, 5.4], [1.0, 0.55, 0.22], [0.30, 0.20, 0.12]):
				sig += a0 * a * np.sin(2 * np.pi * f0 * p * t) * exp_decay(d, tau * 3.0)
		# Le marteau : une modulation à 24 Hz.
		env = np.clip(t / 0.02, 0, 1)
		sig *= env * (0.55 + 0.45 * np.abs(np.sin(2 * np.pi * 24.0 * t)))
		_place(out, sig, t0)
		_place(out, 0.05 * click(int(0.03 * SR), rng, tau=0.002, lo=2000, hi=11000, amp=0.4), t0)
	ir = make_ir(0.75, 0.22, bright=4200, rng=rng_for(7502),
				 taps=[(0.014, 0.40), (0.031, 0.28), (0.052, 0.18)])
	return reverb(out, ir, mix=0.30)


def water_drip() -> np.ndarray:
	"""Un robinet goutte. Quatre gouttes, bien séparées, bien nettes."""
	rng = rng_for(7601)
	n = int(1.95 * SR)
	out = np.zeros(n)
	for k in range(4):
		t0 = 0.05 + k * 0.44 + rng.uniform(-0.03, 0.03)
		d = int(0.16 * SR)
		# Une goutte : la hauteur monte très vite, puis ça s'éteint.
		plink = sweep(rng.uniform(820, 1150), rng.uniform(1450, 1900), d, curve="exp")
		plink *= exp_decay(d, 0.045) ** 1.0
		_place(out, 0.42 * plink, t0)
		_place(out, 0.08 * click(int(0.02 * SR), rng, tau=0.0018, lo=2500, hi=11000, amp=0.5), t0)
		# Le petit « floc » dans la bassine.
		_place(out, 0.06 * tone([240, 520], [1.0, 0.4], [0.05, 0.03], int(0.08 * SR), rng), t0 + 0.005)
	ir = make_ir(0.50, 0.14, bright=5000, rng=rng_for(7602))
	return reverb(out, ir, mix=0.24)


def paper_turn() -> np.ndarray:
	"""Quelqu'un tourne les pages du carnet. Le carnet est dans VOS mains.
	Ce son est sec et proche : pas de réverbération, c'est ce qui le rend
	insupportable."""
	rng = rng_for(7701)
	n = int(1.65 * SR)
	out = np.zeros(n)
	for k in range(3):
		t0 = 0.02 + k * 0.52 + rng.uniform(0.0, 0.04)
		d = int(0.42 * SR)
		t = t_axis(d)
		# Le plat de la main qui soulève la page.
		grab = bp(noise(d, rng), 700, 5000, order=2)
		_place(out, 0.22 * grab * np.clip(t / 0.04, 0, 1) * exp_decay(d, 0.06), t0)
		# La page qui tourne : le bruit monte puis retombe.
		turn = bp(noise(d, rng), 1400, 8500, order=2)
		env = np.clip((t - 0.05) / 0.10, 0, 1) * np.clip((0.34 - t + 0.05) / 0.16, 0, 1)
		turn *= env * (0.7 + 0.3 * np.abs(np.sin(2 * np.pi * 21.0 * t)))
		_place(out, 0.40 * turn, t0)
		# La page qui retombe, et le crayon qui roule un peu.
		_place(out, 0.16 * bp(noise(int(0.10 * SR), rng), 500, 3200, order=2)
			   * exp_decay(int(0.10 * SR), 0.045), t0 + 0.30)
	return out     # volontairement sec : aucun effet de salle


def breath_low() -> np.ndarray:
	"""Une respiration qui n'est pas la vôtre. Plus basse, plus proche."""
	rng = rng_for(7801)
	n = int(1.55 * SR)
	t = t_axis(n)
	x = bp(noise(n, rng), 130, 900, order=2)
	env = np.clip(t / 0.16, 0, 1) ** 1.1 * np.clip((1.42 - t) / 0.55, 0, 1) ** 1.3
	x *= env
	# C'est une expiration : la hauteur descend lentement, comme un soupir.
	x += 0.35 * sweep(320, 210, n, curve="lin") * env * 0.5
	# Une octave en dessous : c'est ce qui dit « ce n'est pas vous ».
	x += 0.22 * bp(noise(n, rng), 60, 240, order=2) * env
	# Résonance d'une cage thoracique plus grande.
	x += 0.20 * bp(x, 230, 420, order=2)
	return 1.05 * x


def hall_light_out() -> np.ndarray:
	"""Le plafonnier de l'entrée s'éteint. Le ballast descend avec lui."""
	rng = rng_for(7901)
	n = int(0.95 * SR)
	t = t_axis(n)
	out = np.zeros(n)
	# L'interrupteur.
	_place(out, click(int(0.04 * SR), rng, tau=0.003, lo=1600, hi=9000, amp=0.45), 0.0)
	# Le ballast : un bourdonnement à 100 Hz qui s'effondre.
	buzz = np.zeros(int(0.55 * SR))
	tb = t_axis(int(0.55 * SR))
	for k, a in ((1, 1.0), (2, 0.45), (3, 0.22), (4, 0.12), (5, 0.07)):
		buzz += a * np.sin(2 * np.pi * 100.0 * k * tb) * exp_decay(int(0.55 * SR), 0.16)
	buzz *= np.clip(tb / 0.012, 0, 1)
	_place(out, 0.16 * buzz, 0.02)
	# Le filament : un grésillement très bref, puis plus rien.
	fiz = bp(noise(int(0.12 * SR), rng), 1800, 9000, order=2) * exp_decay(int(0.12 * SR), 0.030)
	_place(out, 0.10 * fiz, 0.03)
	# Le silence qui suit : la pièce, sans la lumière.
	ir = make_ir(0.70, 0.20, bright=2200, rng=rng_for(7902))
	return reverb(out, ir, mix=0.20)


def cellar_light_flicker() -> np.ndarray:
	"""L'ampoule de la cave grésille. Ça va, ça vient, sans logique."""
	rng = rng_for(8001)
	n = int(2.30 * SR)
	out = np.zeros(n)
	# Un bourdonnement de fond, irrégulier.
	t = t_axis(n)
	hum = np.zeros(n)
	for k, a in ((1, 1.0), (2, 0.40), (3, 0.18)):
		hum += a * np.sin(2 * np.pi * 100.0 * k * t)
	hum *= 0.02 * (0.4 + 0.6 * (np.sin(2 * np.pi * 0.7 * t) > -0.2))
	out += hum
	# Cinq accrocs : l'ampoule claque, revient, re-claque.
	times = [0.05, 0.42, 0.78, 1.35, 1.72]
	for i, t0 in enumerate(times):
		t0 += rng.uniform(-0.03, 0.05)
		dur = rng.uniform(0.06, 0.22)
		d = int(dur * SR)
		td = t_axis(d)
		b = np.zeros(d)
		for k, a in ((1, 1.0), (2, 0.5), (3, 0.25), (4, 0.12)):
			b += a * np.sin(2 * np.pi * 100.0 * k * td)
		b *= np.clip(td / 0.006, 0, 1) * exp_decay(d, dur * 0.6)
		_place(out, 0.13 * b, t0)
		_place(out, 0.10 * click(int(0.03 * SR), rng, tau=0.002, lo=1500, hi=10000,
								 amp=rng.uniform(0.25, 0.6)), t0)
	ir = make_ir(0.60, 0.16, bright=3000, rng=rng_for(8002))
	return reverb(out, ir, mix=0.22)


def caught_impact() -> np.ndarray:
	"""Elle vous touche. Pas de cri : un choc sourd, l'air qui manque, et une
	oreille qui sonne. L'AudioManager étouffe tout le reste pendant 2,6 s."""
	rng = rng_for(8101)
	n = int(2.20 * SR)
	t = t_axis(n)
	out = np.zeros(n)
	# Le choc : très grave, très court, dans le ventre.
	d = int(0.5 * SR)
	_place(out, tone([52, 88], [0.85, 0.35], [0.16, 0.09], d, rng), 0.0)
	_place(out, 0.30 * lp(noise(int(0.20 * SR), rng), 260, order=2)
		   * exp_decay(int(0.20 * SR), 0.07), 0.0)
	# L'air qui part : un souffle vite avalé.
	air = bp(noise(int(0.45 * SR), rng), 200, 2400, order=2)
	_place(out, 0.14 * air * np.clip(t_axis(int(0.45 * SR)) / 0.04, 0, 1)
		   * exp_decay(int(0.45 * SR), 0.14), 0.03)
	# L'acouphène : une fréquence pure qui monte puis s'éteint lentement.
	ring = np.sin(2 * np.pi * 3800.0 * t) * np.clip(t / 0.15, 0, 1) * exp_decay(n, 0.85)
	out += 0.055 * ring
	out += 0.018 * np.sin(2 * np.pi * 7600.0 * t) * np.clip(t / 0.2, 0, 1) * exp_decay(n, 0.7)
	# La pièce, qui continue sans vous.
	ir = make_ir(0.90, 0.28, bright=1800, rng=rng_for(8102))
	return reverb(out, ir, mix=0.26)


def amb_presence() -> np.ndarray:
	"""Nappe de la Présence : elle est là, elle ne bouge pas beaucoup."""
	rng = rng_for(8201)
	LOOP = 10.0
	n = int((LOOP + 2.6) * SR)
	t = t_axis(n)
	out = np.zeros(n)
	# Un grave légèrement désaccordé : deux tons qui battent lentement.
	out += 0.22 * np.sin(2 * np.pi * 43.0 * t) + 0.18 * np.sin(2 * np.pi * 43.9 * t)
	out += 0.06 * np.sin(2 * np.pi * 86.0 * t + 1.0)
	# Un souffle irrégulier : ce n'est pas une respiration, mais ça y ressemble.
	br = bp(noise(n, rng), 120, 800, order=2)
	env = np.clip(np.sin(2 * np.pi * 0.13 * t - 0.4), 0, 1) ** 2
	env += 0.35 * np.clip(np.sin(2 * np.pi * 0.071 * t + 2.1), 0, 1) ** 3
	out += 0.14 * br * np.clip(env, 0, 1)
	# Un harmonique « faux » : une quinte juste au-dessus, très basse.
	out += 0.025 * np.sin(2 * np.pi * 64.5 * t + 0.7) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.037 * t))
	return loopitize(out, int(LOOP * SR), int(2.5 * SR))


SOUNDS = {
	"presence/chair_drag_upstairs.ogg": (chair_drag_upstairs, -4.0),
	"presence/upstairs_chair.ogg": (upstairs_chair, -5.0),
	"presence/footsteps_above.ogg": (footsteps_above, -4.0),
	"presence/door_close_upstairs.ogg": (door_close_upstairs, -3.0),
	"presence/phone_ring.ogg": (phone_ring, -5.0),
	"presence/water_drip.ogg": (water_drip, -8.0),
	"presence/paper_turn.ogg": (paper_turn, -6.0),
	"presence/breath_low.ogg": (breath_low, -7.0),
	"presence/hall_light_out.ogg": (hall_light_out, -4.0),
	"presence/cellar_light_flicker.ogg": (cellar_light_flicker, -6.0),
	"presence/caught_impact.ogg": (caught_impact, -1.0),
	"presence/amb_presence.ogg": (amb_presence, -16.0),
}


def main() -> None:
	print("D-5 — sons domestiques au mauvais endroit")
	for path, (fn, peak) in SOUNDS.items():
		write(path, fn(), peak_db=peak, floor_db=-75.0)


if __name__ == "__main__":
	main()
