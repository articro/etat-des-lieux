"""D-2 — Sons de l'appareil photo (priorité 1 du jeu).

Modèle : un appareil instantané des années 90 (Polaroid 600 / Instax).
Quatre sons portent tout le jeu :
  camera_shutter  le clac du déclencheur (sec, mécanique, pas de lumière)
  camera_flash    le « clac » du flash : décharge + résonance + queue de salle
  photo_slide     le moteur qui éjecte la photo (le plus long, le plus identifiable)
  flash_charge    le sifflement qui monte (condensateur) + clic « prêt »

Référence de conception : aucune violence gratuite. Le flash doit être
*impressionnant* parce qu'il est bref, clair et qu'il laisse entendre la pièce
(la queue de réverbération), pas parce qu'il est fort.
"""

from __future__ import annotations

import numpy as np

from common import (
	SR, bp, click, exp_decay, hp, lp, make_ir, noise, norm, reverb,
	rng_for, sweep, t_axis, tone, write,
)


def place(dst: np.ndarray, x: np.ndarray, t0: float, sr: int = SR) -> np.ndarray:
	"""Ajoute le son x dans dst à partir de t0 secondes."""
	i = int(t0 * sr)
	if i >= len(dst):
		return dst
	j = min(len(dst), i + len(x))
	dst[i:j] += x[: j - i]
	return dst


# --------------------------------------------------------------- déclencheur

def camera_shutter() -> np.ndarray:
	"""Clac du déclencheur : pré-course, clac sec, rideau, puis la pièce."""
	rng = rng_for(1101)
	n = int(0.34 * SR)
	out = np.zeros(n)

	# Pré-course du bouton (très court, très sec).
	place(out, click(int(0.02 * SR), rng, tau=0.0035, lo=2500, hi=11000, amp=0.16), 0.000)

	# Clac principal : bruit + modes de la coque + un peu de masse.
	dur = int(0.12 * SR)
	body = click(dur, rng, tau=0.010, lo=1200, hi=9500, amp=0.80)
	body += tone([2050, 3620, 5300, 7400], [0.52, 0.32, 0.19, 0.10],
				 [0.019, 0.013, 0.008, 0.005], dur, rng)
	body += tone([168, 322], [0.30, 0.15], [0.030, 0.019], dur, rng)
	place(out, body, 0.010)

	# Rideau qui passe : un souffle très court, juste après.
	h = bp(noise(int(0.07 * SR), rng), 3000, 9500, order=2) * exp_decay(int(0.07 * SR), 0.016)
	place(out, 0.09 * h, 0.026)

	# La pièce (courte : un clac, pas un coup de feu).
	ir = make_ir(0.30, 0.095, bright=5200, rng=rng_for(303))
	return reverb(out, ir, mix=0.14)


# -------------------------------------------------------------------- flash

def camera_flash() -> np.ndarray:
	"""Le clac du flash : étincelle HF, corps, grésillement, queue de salle."""
	rng = rng_for(1202)
	n = int(0.55 * SR)
	t = t_axis(n)
	out = np.zeros(n)

	# 1. Décharge : une étincelle très brillante (3-16 kHz), 4 ms.
	spark = click(int(0.05 * SR), rng, tau=0.0028, lo=3500, hi=16000, amp=1.00)
	place(out, spark, 0.000)

	# 2. Le « clac » : le corps de l'appareil encaisse la décharge.
	dur = int(0.16 * SR)
	body = click(dur, rng, tau=0.018, lo=700, hi=8000, amp=0.50)
	body += tone([880, 1520, 2650, 4100], [0.48, 0.38, 0.26, 0.15],
				 [0.045, 0.032, 0.020, 0.012], dur, rng)
	place(out, body, 0.003)

	# Présence (2-5 kHz) : le clac doit s'entendre dans le grave de la pièce.
	place(out, click(int(0.05 * SR), rng, tau=0.004, lo=2000, hi=5000, amp=0.30), 0.004)

	# 3. Grésillement de l'arc : instable, très aigu, 130 ms.
	sizzle = bp(noise(int(0.14 * SR), rng), 5000, 14000, order=2)
	sizzle *= exp_decay(int(0.14 * SR), 0.042)
	flick = 0.55 + 0.45 * np.abs(np.sin(2 * np.pi * 61.0 * t[: int(0.14 * SR)] + rng.uniform(0, 6)))
	place(out, 0.085 * sizzle * flick, 0.006)

	# 4. Le tube sonne (bip amorti qui descend légèrement).
	ring = sweep(1480, 1380, int(0.20 * SR)) * exp_decay(int(0.20 * SR), 0.075)
	place(out, 0.085 * ring, 0.008)

	# 5. Le « whump » : ce que le flash donne dans le ventre.
	low = tone([95, 190], [0.16, 0.08], [0.070, 0.045], int(0.22 * SR), rng)
	place(out, low, 0.004)

	# 6. La pièce, éclairée une fraction de seconde : queue plus claire.
	ir = make_ir(0.45, 0.135, bright=6500, rng=rng_for(404),
				 taps=[(0.009, 0.45), (0.017, 0.34), (0.029, 0.26), (0.043, 0.17), (0.062, 0.10)])
	return reverb(out, ir, mix=0.24)


# ------------------------------------------------------------------ moteur

def photo_slide() -> np.ndarray:
	"""Le moteur qui éjecte la photo : engage, ronronne, crache le papier, bute."""
	rng = rng_for(1303)
	n = int(1.45 * SR)
	t = t_axis(n)
	out = np.zeros(n)

	# 1. Le moteur s'engage : un à-coup.
	dur = int(0.12 * SR)
	place(out, click(dur, rng, tau=0.008, lo=500, hi=6000, amp=0.34)
		  + tone([420, 900, 1900], [0.40, 0.26, 0.15], [0.050, 0.030, 0.016], dur, rng), 0.0)

	# 2. Ronronnement : fondamentale + harmoniques + wow & flutter.
	nm = int(1.02 * SR)
	tm = t_axis(nm)
	f0 = 104.0 * (1.0 + 0.017 * np.sin(2 * np.pi * 1.7 * tm) + 0.006 * np.sin(2 * np.pi * 11.3 * tm))
	phase = 2 * np.pi * np.cumsum(f0) / SR
	motor = np.zeros(nm)
	for k in range(1, 13):
		motor += (0.50 / k ** 1.15) * np.sin(k * phase + rng.uniform(0, 6.28))

	# Engrenages : bruit résonant modulé à la fréquence de denture (33 Hz).
	gear = bp(noise(nm, rng), 2300, 3400, order=2) * (0.65 + 0.35 * np.sin(2 * np.pi * 33.0 * tm))
	# Friction des rouleaux : modulation plus lente (22,5 Hz).
	fric = bp(noise(nm, rng), 900, 7000, order=2) * (0.75 + 0.25 * np.sin(2 * np.pi * 22.5 * tm))

	env = np.ones(nm)
	a = int(0.035 * SR)
	env[:a] = np.linspace(0.0, 1.0, a)
	env *= 0.92 + 0.16 * np.sin(np.pi * np.clip(tm / 1.05, 0, 1))   # léger crescendo
	d = int(0.10 * SR)
	env[-d:] *= np.linspace(1.0, 0.55, d)
	core = (0.40 * motor + 0.10 * gear + 0.20 * fric) * env
	place(out, core, 0.020)

	# 3. La photo glisse hors de la fente : deux bandes qui se croisent
	#    (ça monte en luminosité, ça s'entend comme du papier).
	npz = int(0.52 * SR)
	tp = t_axis(npz)
	sn = noise(npz, rng)
	lo_b = bp(sn, 500, 2500, order=2)
	hi_b = bp(sn, 2500, 9000, order=2)
	slide_env = np.clip((tp - 0.02) / 0.10, 0, 1) * np.clip((0.50 - tp) / 0.30, 0, 1)
	slide = (lo_b * (1.0 - 0.75 * np.clip(tp / 0.45, 0, 1)) + hi_b * 0.85 * np.clip(tp / 0.40, 0, 1))
	slide *= slide_env
	slide *= 0.85 + 0.15 * np.sin(2 * np.pi * 170.0 * tp)      # grain du papier
	place(out, 0.30 * slide, 0.760)

	# 4. Butée de fin de course.
	dur = int(0.14 * SR)
	place(out, click(dur, rng, tau=0.006, lo=400, hi=5000, amp=0.30)
		  + tone([300, 720, 1600], [0.38, 0.24, 0.13], [0.055, 0.032, 0.018], dur, rng), 1.175)

	# 5. La photo qui pend : un dernier frôlement, très discret.
	f = bp(noise(int(0.16 * SR), rng), 1500, 7000, order=2) * exp_decay(int(0.16 * SR), 0.05)
	place(out, 0.05 * f, 1.235)

	ir = make_ir(0.38, 0.13, bright=4200, rng=rng_for(505))
	return reverb(out, ir, mix=0.13)


# ------------------------------------------------------------ charge du flash

def flash_charge() -> np.ndarray:
	"""Le sifflement qui monte : le condensateur se charge. Monte en accélérant,
	puis se coupe net sur un clic « prêt »."""
	rng = rng_for(1404)
	T = 1.42
	n = int((T + 0.16) * SR)
	t = t_axis(n)
	out = np.zeros(n)

	# Fréquence : monte de plus en plus vite (le condensateur se remplit).
	nt = int(T * SR)
	tt = t_axis(nt)
	f0, f1 = 1150.0, 5600.0
	freq = f0 * (f1 / f0) ** ((tt / T) ** 1.35)
	phase = 2 * np.pi * np.cumsum(freq) / SR

	# Amplitude : attaque douce puis montée avec la fréquence.
	amp = np.clip(tt / 0.10, 0, 1) * (0.62 + 0.38 * (tt / T) ** 1.5)
	# Instabilité de l'inverseur : petit trémolo.
	amp *= 1.0 + 0.05 * np.sin(2 * np.pi * 7.5 * tt) + 0.02 * np.sin(2 * np.pi * 23.0 * tt)

	whine = 0.55 * np.sin(phase)
	whine += 0.15 * np.sin(2 * phase + 0.7)        # harmonique 2 : timbre fin
	whine += 0.045 * np.sin(3 * phase + 1.9)       # harmonique 3 : un peu métallique
	whine += 0.03 * np.sin(0.5 * phase)            # sous-harmonique : épaisseur
	whine *= amp

	# Sifflement de l'inverseur (bruit électrique qui suit la montée).
	hiss = bp(noise(nt, rng), 2000, 9000, order=2) * amp * 0.035

	seg = whine + hiss
	# Coupure nette à la fin de la charge, pas de fondu.
	cut = int(0.004 * SR)
	seg[-cut:] *= np.linspace(1.0, 0.0, cut)
	out[:nt] += seg

	# Clic « prêt » : le relais tombe, l'appareil est armé.
	place(out, click(int(0.04 * SR), rng, tau=0.005, lo=2000, hi=9000, amp=0.28), T + 0.004)
	place(out, 0.09 * tone([2400, 3900], [1.0, 0.4], [0.030, 0.018], int(0.06 * SR), rng), T + 0.006)

	ir = make_ir(0.20, 0.06, bright=6000, rng=rng_for(606))
	return reverb(out, ir, mix=0.06)


# -------------------------------------------------------- lever / baisser

def camera_raise() -> np.ndarray:
	"""On lève l'appareil : dépliage, clac, verrou, petit ressort."""
	rng = rng_for(1505)
	n = int(0.60 * SR)
	out = np.zeros(n)

	# Frottement du corps contre les mains.
	place(out, bp(noise(int(0.06 * SR), rng), 400, 3000, order=2)
		  * exp_decay(int(0.06 * SR), 0.028) * 0.16, 0.0)

	# Clac du dépliage.
	dur = int(0.18 * SR)
	place(out, click(dur, rng, tau=0.010, lo=800, hi=9000, amp=0.40)
		  + tone([760, 1650, 2900, 4400], [0.40, 0.30, 0.19, 0.10],
				 [0.040, 0.026, 0.016, 0.010], dur, rng), 0.050)

	# Verrou qui se met en place.
	dur2 = int(0.08 * SR)
	place(out, click(dur2, rng, tau=0.005, lo=2500, hi=12000, amp=0.28)
		  + tone([3200, 5400], [0.16, 0.08], [0.020, 0.012], dur2, rng), 0.170)

	# Ressort qui se stabilise.
	place(out, 0.055 * tone([1500, 2400], [1.0, 0.5], [0.050, 0.030], int(0.12 * SR), rng), 0.245)
	place(out, 0.16 * tone([210, 430], [1.0, 0.35], [0.060, 0.035], int(0.14 * SR), rng), 0.320)

	ir = make_ir(0.30, 0.10, bright=4500, rng=rng_for(707))
	return reverb(out, ir, mix=0.13)


def camera_lower() -> np.ndarray:
	"""On baisse l'appareil : plus sourd, moins de métal."""
	rng = rng_for(1606)
	n = int(0.40 * SR)
	out = np.zeros(n)

	place(out, bp(noise(int(0.08 * SR), rng), 200, 1800, order=2)
		  * exp_decay(int(0.08 * SR), 0.045) * 0.28, 0.0)
	dur = int(0.16 * SR)
	place(out, click(dur, rng, tau=0.007, lo=500, hi=6000, amp=0.28)
		  + tone([560, 1150, 2100], [0.38, 0.24, 0.12], [0.045, 0.028, 0.016], dur, rng), 0.015)
	place(out, click(int(0.04 * SR), rng, tau=0.004, lo=1500, hi=9000, amp=0.16), 0.100)

	ir = make_ir(0.26, 0.09, bright=3000, rng=rng_for(808))
	return reverb(out, ir, mix=0.10)


# ------------------------------------------------------------------- à vide

def camera_dry() -> np.ndarray:
	"""Plus de film : un clac décevant, creux, et aucun moteur derrière."""
	rng = rng_for(1707)
	n = int(0.30 * SR)
	out = np.zeros(n)

	place(out, click(int(0.05 * SR), rng, tau=0.006, lo=800, hi=7000, amp=0.45), 0.0)
	dur = int(0.18 * SR)
	place(out, tone([520, 1080], [0.40, 0.20], [0.040, 0.024], dur, rng), 0.002)
	# Corps vide : ça résonne creux et ça s'éteint.
	place(out, tone([195, 320], [0.22, 0.30], [0.130, 0.095], dur, rng), 0.004)
	# Ressort mort : un petit « boing » qui descend.
	place(out, 0.055 * sweep(760, 655, int(0.12 * SR)) * exp_decay(int(0.12 * SR), 0.055), 0.010)

	ir = make_ir(0.28, 0.09, bright=3600, rng=rng_for(909))
	return reverb(out, ir, mix=0.10)


def photo_ready() -> np.ndarray:
	"""La photo a fini de se développer : un frôlement de papier, très doux."""
	rng = rng_for(1808)
	n = int(0.60 * SR)
	t = t_axis(n)
	out = bp(noise(n, rng), 1800, 8000, order=2)
	env = np.clip((t - 0.06) / 0.12, 0, 1) * np.clip((0.58 - t) / 0.34, 0, 1)
	out *= env
	# Micro-craquements : le papier qui bouge dans la main.
	for _ in range(14):
		ti = rng.uniform(0.10, 0.52)
		place(out, click(int(0.02 * SR), rng, tau=0.002, lo=2500, hi=9000,
						 amp=rng.uniform(0.04, 0.13)), ti)
	return 0.5 * out


# ---------------------------------------------------------------------- main

SOUNDS = {
	"camera/camera_shutter.ogg": camera_shutter,
	"camera/camera_flash.ogg": camera_flash,
	"camera/photo_slide.ogg": photo_slide,
	"camera/flash_charge.ogg": flash_charge,
	"camera/camera_raise.ogg": camera_raise,
	"camera/camera_lower.ogg": camera_lower,
	"camera/camera_dry.ogg": camera_dry,
	"camera/photo_ready.ogg": photo_ready,
}


def main() -> None:
	print("D-2 — sons de l'appareil photo")
	for path, fn in SOUNDS.items():
		write(path, fn())


if __name__ == "__main__":
	main()
