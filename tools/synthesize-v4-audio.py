"""Original deterministic sound design, mono 22.05 kHz PCM."""
from pathlib import Path
import math
import random
import struct
import wave

out = Path(__file__).resolve().parents[1] / "assets/audio"
out.mkdir(parents=True, exist_ok=True)
rate = 22050
random.seed(417)
for name, duration in {"TransitDrone": 8, "FloodAmbience": 8, "StalkerBreath": 4,
                       "StalkerThreat": 1.5, "ElevatorTravel": 5, "ObjectiveChime": 1}.items():
    samples = []
    noise = 0
    for index in range(int(rate * duration)):
        t = index / rate
        noise = noise * .93 + random.uniform(-1, 1) * .07
        edge = min(t * 8, (duration - t) * 8, 1)
        if name == "TransitDrone":
            value = .17 * math.sin(t * math.tau * 48) + .09 * math.sin(t * math.tau * 73) + noise * .6
            value *= .75 + .25 * math.cos(math.tau * t / duration)
        elif name == "FloodAmbience":
            value = noise * (1.8 + math.sin(t * 3)) + .04 * math.sin(300 * t + math.sin(7 * t))
        elif name == "StalkerBreath":
            pulse = max(0, math.sin(t * math.pi)) ** 2
            value = pulse * (noise * 2.5 + .2 * math.sin(math.tau * 57 * t + 2 * math.sin(t * 24)))
        elif name == "StalkerThreat":
            value = (noise * 2 + .3 * math.sin(math.tau * (72 * t - 11 * t * t))) * math.exp(-t * 1.3)
        elif name == "ElevatorTravel":
            value = (.15 * math.sin(math.tau * (42 * t + 3 * t * t)) + noise) * math.sin(math.pi * t / duration)
        else:
            value = (.28 * math.sin(math.tau * 660 * t) + .16 * math.sin(math.tau * 990 * t)) * math.exp(-t * 5)
        samples.append(struct.pack("<h", int(max(-.95, min(.95, value * edge)) * 32767)))
    with wave.open(str(out / (name + ".wav")), "wb") as audio:
        audio.setparams((1, 2, rate, 0, "NONE", "not compressed"))
        audio.writeframes(b"".join(samples))
print("Created six original sound assets")
