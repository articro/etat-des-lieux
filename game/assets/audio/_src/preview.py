"""Aperçu visuel d'un son généré : forme d'onde + spectrogramme.

Usage :
    python3 game/assets/audio/_src/preview.py camera/camera_flash.ogg [...]

Les PNG sont écrits dans /tmp/preview/ (jamais dans le dépôt).
"""

from __future__ import annotations

import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import soundfile as sf
from scipy import signal

from common import AUDIO_ROOT

OUT = Path("/tmp/preview")


def plot(path: str) -> None:
	full = AUDIO_ROOT / path
	if not full.exists():
		print("absent : %s" % full)
		return
	x, sr = sf.read(str(full), dtype="float32")
	if x.ndim > 1:
		x = x.mean(axis=1)
	fig, axes = plt.subplots(2, 1, figsize=(11, 5), constrained_layout=True)
	t = np.arange(len(x)) / sr
	axes[0].plot(t, x, linewidth=0.5, color="#1f77b4")
	axes[0].set_ylim(-1.05, 1.05)
	axes[0].set_ylabel("amp")
	axes[0].set_title("%s  —  %.3f s, %d Hz" % (path, len(x) / sr, sr))
	axes[0].grid(alpha=0.25)
	f, ts, Sxx = signal.spectrogram(x, sr, nperseg=512, noverlap=448)
	S = 10 * np.log10(Sxx + 1e-12)
	vmin = np.max(S) - 85
	axes[1].pcolormesh(ts, f, S, shading="auto", cmap="magma", vmin=vmin, vmax=np.max(S))
	axes[1].set_ylim(0, min(16000, sr // 2))
	axes[1].set_ylabel("Hz")
	axes[1].set_xlabel("s")
	OUT.mkdir(parents=True, exist_ok=True)
	name = path.replace("/", "__").replace(".ogg", ".png")
	fig.savefig(OUT / name, dpi=95)
	plt.close(fig)
	print("%s -> /tmp/preview/%s" % (path, name))


if __name__ == "__main__":
	args = sys.argv[1:] or ["camera/camera_flash.ogg"]
	for a in args:
		plot(a)
