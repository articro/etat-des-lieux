"""D-6 — Musique de fin.

Deux morceaux, un par fin. Sobres : un bourdon, un piano très lent, un pad qui
s'ouvre, puis le silence. Aucune mélodie entêtante, aucun crescendo héroïque :
le jeu se termine sur un inventaire, pas sur une victoire.

Synthèse : piano = partiels inharmoniques + marteau + extinction différenciée ;
pad = harmoniques qui entrent les unes après les autres (filtre qui s'ouvre) ;
bourdon = deux graves accordés. Le tout dans une réverbération longue.
"""

from __future__ import annotations

import numpy as np

from common import SR, bp, click, exp_decay, lp, make_ir, noise, reverb, rng_for, t_axis, write

DUR = 66.0


def _place(dst: np.ndarray, x: np.ndarray, t0: float) -> np.ndarray:
	i = max(int(t0 * SR), 0)
	j = min(len(dst), i + len(x))
	if i < len(dst):
		dst[i:j] += x[: j - i]
	return dst


def piano(freq: float, dur: float, rng, amp: float = 1.0, bright: float = 0.82) -> np.ndarray:
	"""Une note de piano (vertical droit, un peu désaccordé)."""
	n = int(dur * SR)
	t = t_axis(n)
	sig = np.zeros(n)
	B = 0.0005                      # inharmonicité des cordes
	for k in range(1, 11):
		fk = freq * k * np.sqrt(1.0 + B * k * k)
		if fk > SR * 0.45:
			break
		a = (1.0 / k ** 1.35) * (bright ** (k - 1))
		tau = dur / (2.6 + 0.75 * (k - 1))     # les aigus meurent plus vite
		sig += a * np.sin(2 * np.pi * fk * t + rng.uniform(0, 6.28)) * np.exp(-t / tau)
	# Le marteau : un petit choc feutré.
	sig += 0.05 * click(n, rng, tau=0.004, lo=1500, hi=7000, amp=1.0)
	# Sympathie : la corde voisine vibre un peu.
	sig += 0.03 * np.sin(2 * np.pi * freq * 1.5 * t) * np.exp(-t / (dur / 2.0))
	sig *= np.clip(t / 0.005, 0, 1)
	sig *= np.clip((dur - t) / 0.08, 0, 1)     # pas de coupure sèche
	return amp * sig


def pad(freq: float, dur: float, t0: float, rng, amp: float = 1.0, n_max: int = 6) -> np.ndarray:
	"""Nappe : les harmoniques entrent les unes après les autres (filtre
	qui s'ouvre lentement), deux voix légèrement désaccordées."""
	n = int(dur * SR)
	t = t_axis(n)
	u = np.clip(t / dur, 0, 1)
	sig = np.zeros(n)
	for k in range(1, 13):
		# L'harmonique k apparaît quand le filtre passe au-dessus de sa fréquence.
		opening = np.clip(u * (n_max + 2) - k + 1.0, 0.0, 1.0)
		opening = opening * opening * (3.0 - 2.0 * opening)      # smoothstep
		a = (1.0 / k ** 1.1) * opening
		for det, g in ((-0.0012, 0.6), (0.0012, 0.4)):
			sig += g * a * np.sin(2 * np.pi * freq * k * (1.0 + det) * t + rng.uniform(0, 6.28))
	# Respiration lente de la nappe.
	swell = 0.55 + 0.45 * np.sin(np.pi * np.clip(u * 1.05, 0, 1))
	sig *= swell
	sig *= np.clip(t / 1.2, 0, 1) * np.clip((dur - t) / 3.0, 0, 1)
	return amp * sig


def drone(freq: float, dur: float, amp: float = 1.0, detune: float = 0.0) -> np.ndarray:
	n = int(dur * SR)
	t = t_axis(n)
	sig = np.zeros(n)
	sig += 0.5 * np.sin(2 * np.pi * freq * t)
	sig += 0.35 * np.sin(2 * np.pi * freq * (1.0 + detune) * t + 1.1)
	sig += 0.18 * np.sin(2 * np.pi * freq * 2.0 * t + 0.4)
	sig += 0.09 * np.sin(2 * np.pi * freq * 3.0 * t + 2.2)
	sig *= np.clip(t / 1.5, 0, 1) * np.clip((dur - t) / 8.0, 0, 1)
	return amp * sig


def _track(notes, low_freq: float, pad_freq: float, pad_t0: float, pad_dur: float,
		   seed: int, room: float = 2.8) -> np.ndarray:
	rng = rng_for(seed)
	n = int(DUR * SR)
	out = np.zeros(n)
	# Bourdon : il tient tout le morceau et s'éteint à la fin.
	_place(out, 0.30 * drone(low_freq, DUR, 1.0, detune=0.0015), 0.0)
	# Nappe : elle entre doucement, une seule fois.
	_place(out, 0.10 * pad(pad_freq, pad_dur, pad_t0, rng), pad_t0)
	# Piano : une note toutes les ~3 s, jamais pressée.
	for t0, freq, dur, amp in notes:
		_place(out, 0.34 * piano(freq, dur, rng, amp), t0)
	# Souffle de la pièce (le silence n'est jamais vide).
	air = lp(noise(n, rng), 320, order=2) * 0.012
	out += air
	ir = make_ir(room, 0.85, bright=2600, rng=rng_for(seed + 1),
				 taps=[(0.023, 0.35), (0.041, 0.26), (0.067, 0.18), (0.098, 0.11)])
	return reverb(out, ir, mix=0.38)


def music_ending_closed() -> np.ndarray:
	"""Inventaire clos : Camille devient la ligne 61. La mineure ne résout pas."""
	A2, C4, E4, B3, G3, F3, A3 = 110.0, 261.63, 329.63, 246.94, 196.00, 174.61, 220.00
	notes = [
		(4.0, A3, 7.0, 0.9), (11.0, C4, 7.5, 0.85), (18.5, E4, 7.0, 0.8),
		(25.5, B3, 7.5, 0.85), (33.0, A3, 7.0, 0.8), (40.0, G3, 7.5, 0.85),
		(47.5, F3, 8.0, 0.9), (55.5, A3, 10.0, 0.75),
	]
	return _track(notes, A2, A3, 2.0, 52.0, 9101)


def music_ending_ashes() -> np.ndarray:
	"""Cendres : elle sort à l'aube. La majeur, et ça s'éteindre en paix."""
	A2, A3, CS4, E4, FS4, D4, A4 = 110.0, 220.0, 277.18, 329.63, 369.99, 293.66, 440.00
	notes = [
		(4.0, A3, 7.0, 0.85), (11.5, CS4, 7.5, 0.8), (19.0, E4, 7.0, 0.85),
		(26.0, A4, 7.0, 0.7), (33.0, FS4, 7.5, 0.8), (40.5, D4, 8.0, 0.85),
		(48.0, A3, 9.0, 0.8), (56.0, E4, 10.0, 0.7),
	]
	return _track(notes, A2, E4, 3.0, 50.0, 9201, room=3.2)


SOUNDS = {
	"music/music_ending_closed.ogg": (music_ending_closed, -2.5),
	"music/music_ending_ashes.ogg": (music_ending_ashes, -2.5),
}


def main() -> None:
	print("D-6 — musique de fin")
	for path, (fn, peak) in SOUNDS.items():
		write(path, fn(), peak_db=peak, floor_db=-80.0)


if __name__ == "__main__":
	main()
