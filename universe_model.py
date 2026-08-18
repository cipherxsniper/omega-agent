#!/usr/bin/env python3
"""
universe_model.py — a single-file, multi-mode universe mapper.

Modes:
  solar   -> real solar system (scaled orbits, AU)
  stars   -> real nearest-star catalog (RA/Dec/distance -> XYZ)
  cosmic  -> procedural large-scale structure (filaments + voids)
  nbody   -> toy N-body gravity simulation (not to real scale)
  all     -> all four in one figure

Usage:
  python universe_model.py --mode all
"""

import argparse
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D  # noqa: F401

# ---------- REAL DATA: nearest stars (RA deg, Dec deg, distance ly) ----------
NEAREST_STARS = [
    ("Sol", 0, 0, 0),
    ("Proxima Centauri", 217.42, -62.68, 4.24),
    ("Alpha Centauri A", 219.90, -60.83, 4.37),
    ("Alpha Centauri B", 219.90, -60.83, 4.37),
    ("Barnard's Star", 269.45, 4.67, 5.96),
    ("Wolf 359", 164.12, 7.01, 7.86),
    ("Lalande 21185", 165.83, 35.97, 8.31),
    ("Sirius A", 101.29, -16.72, 8.66),
    ("Sirius B", 101.29, -16.72, 8.66),
    ("Luyten 726-8", 24.76, -17.95, 8.73),
    ("Ross 154", 282.46, -23.84, 9.68),
    ("Ross 248", 353.23, 44.19, 10.32),
    ("Epsilon Eridani", 53.23, -9.46, 10.52),
    ("Lacaille 9352", 341.70, -35.85, 10.74),
    ("Ross 128", 176.94, 0.80, 11.01),
    ("Procyon", 114.83, 5.22, 11.46),
]

# ---------- REAL DATA: solar system (semi-major axis AU, period yrs) ----------
PLANETS = [
    ("Mercury", 0.39, 0.24), ("Venus", 0.72, 0.62), ("Earth", 1.00, 1.00),
    ("Mars", 1.52, 1.88), ("Jupiter", 5.20, 11.86), ("Saturn", 9.58, 29.46),
    ("Uranus", 19.20, 84.01), ("Neptune", 30.05, 164.8),
]


def radec_to_xyz(ra_deg, dec_deg, dist):
    ra, dec = np.radians(ra_deg), np.radians(dec_deg)
    x = dist * np.cos(dec) * np.cos(ra)
    y = dist * np.cos(dec) * np.sin(ra)
    z = dist * np.sin(dec)
    return x, y, z


def plot_stars(ax):
    for name, ra, dec, d in NEAREST_STARS:
        x, y, z = radec_to_xyz(ra, dec, d)
        ax.scatter(x, y, z, s=40, c='gold' if d else 'orange')
        ax.text(x, y, z, name, fontsize=6)
    ax.set_title("Nearest stars (light-years)")


def plot_solar_system(ax):
    ax.scatter(0, 0, 0, c='yellow', s=200, label='Sun')
    theta = np.linspace(0, 2 * np.pi, 200)
    for name, a, _ in PLANETS:
        ax.plot(a * np.cos(theta), a * np.sin(theta), np.zeros_like(theta), lw=0.5)
        ang = np.random.uniform(0, 2 * np.pi)
        ax.scatter(a * np.cos(ang), a * np.sin(ang), 0, s=25, label=name)
    ax.set_title("Solar system (AU, static positions)")


def plot_cosmic_web(ax, n_filaments=12, points_per_filament=250, box=100):
    """Procedural large-scale structure: random-walk filaments + carved voids."""
    all_pts = []
    for _ in range(n_filaments):
        start = np.random.uniform(-box, box, 3)
        pts = [start]
        for _ in range(points_per_filament - 1):
            step = np.random.normal(0, box * 0.03, 3)
            pts.append(pts[-1] + step)
        all_pts.append(np.array(pts))
    pts = np.vstack(all_pts)
    # carve a few voids
    for _ in range(5):
        center = np.random.uniform(-box, box, 3)
        radius = np.random.uniform(box * 0.15, box * 0.3)
        mask = np.linalg.norm(pts - center, axis=1) > radius
        pts = pts[mask]
    ax.scatter(pts[:, 0], pts[:, 1], pts[:, 2], s=1, c='cyan', alpha=0.5)
    ax.set_title("Procedural cosmic web (galaxies along filaments)")


def nbody_sim(ax, n_bodies=15, steps=400, dt=0.01, G=1.0):
    """Toy leapfrog gravity sim — illustrative, not physically scaled."""
    pos = np.random.uniform(-5, 5, (n_bodies, 3))
    vel = np.random.uniform(-0.2, 0.2, (n_bodies, 3))
    mass = np.random.uniform(0.5, 3, n_bodies)
    trail = np.zeros((steps, n_bodies, 3))

    for s in range(steps):
        acc = np.zeros_like(pos)
        for i in range(n_bodies):
            diff = pos - pos[i]
            dist = np.linalg.norm(diff, axis=1)
            dist[i] = 1e9
            acc[i] = np.sum((G * mass[:, None] * diff) / (dist[:, None] ** 3 + 1e-3), axis=0)
        vel += acc * dt
        pos += vel * dt
        trail[s] = pos

    for i in range(n_bodies):
        ax.plot(trail[:, i, 0], trail[:, i, 1], trail[:, i, 2], lw=0.7)
        ax.scatter(*pos[i], s=mass[i] * 15)
    ax.set_title("Toy N-body gravity simulation")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["solar", "stars", "cosmic", "nbody", "all"], default="all")
    args = parser.parse_args()

    fig = plt.figure(figsize=(11, 9))
    modes = ["solar", "stars", "cosmic", "nbody"] if args.mode == "all" else [args.mode]
    n = len(modes)
    cols = 2 if n > 1 else 1
    rows = (n + 1) // 2 if n > 1 else 1

    fns = {"solar": plot_solar_system, "stars": plot_stars,
           "cosmic": plot_cosmic_web, "nbody": nbody_sim}

    for i, m in enumerate(modes):
        ax = fig.add_subplot(rows, cols, i + 1, projection='3d')
        fns[m](ax)

    plt.tight_layout()
    out = "universe_model.png"
    plt.savefig(out, dpi=150)
    print(f"Saved {out}")


if __name__ == "__main__":
    main()
