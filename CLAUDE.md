# Project Guide

## Overview

Parametric OpenSCAD generator for truck bed mat organizer attachments.
Compatible with TMat and similar X-pattern snap-in bed mat systems.

Single-file project: `bed_mat_interface.scad` generates all part types
via OpenSCAD Customizer parameters or CLI `-D` flags.

## Architecture

The interface profile is built from two capsule (stadium) shapes crossed
at 45 degrees, plus a center circle. This is derived from caliper
measurements of first-party parts:

- Two capsules at ±45°: arm_width=12.1mm, semicircle tips (r=6.05mm)
- Center circle: r=10.4mm (from 20.8mm crack-to-crack measurement)
- Bounding box: 37.69mm square
- Interface depth: 17.4mm (from female recess measurement)

The profile is defined in 2D (`outer_profile()` module), then extruded
to create 3D interfaces. All part types (post, straight, corner, tee,
plug) compose the same interface module with different body geometries.

## Grid System

The mat has X-shaped recesses on a uniform 50.8mm (2 inch) grid.
OEM attachments use a diagonal pattern — every other recess — giving
an effective 101.6mm (4 inch) interface pitch. The `interface_spacing`
parameter switches between diagonal (OEM) and dense (every recess).

Sizing uses **half-units** where 1 unit = one interface pitch. This
allows 0.5U body extensions beyond the last interface.

## Key Modules

- `outer_profile()` — 2D X-shape with fit_clearance applied
- `hollow_x_with_ribs()` / `hollow_x_no_ribs()` — 2D hollow cross section
- `interface_3d_with_ribs()` / `interface_3d_no_ribs()` — 3D interface with optional lock bumps
- `capped_interface(cap)` — interface + optional solid cap when wall < profile width
- `interface_column(height, filled)` — full column: cap + body + interface (used by post)
- `leg_interfaces(n, h, cap)` — place interfaces along a leg at half-unit intervals

## Rendering

```bash
# Requires OpenSCAD CLI
openscad -D 'part_type="straight"' bed_mat_interface.scad -o output.stl
```

Check `Genus` in output — 0 is clean manifold. Nonzero typically still
slices fine but indicates CGAL boolean artifacts (common when narrow
bodies intersect the X profile).

## Fit Tuning

`fit_clearance=0` is the tested ideal fit. A built-in base offset
(-0.25mm) accounts for the difference between caliper measurements of
first-party male pieces and the slightly larger female recesses.
Shrinkage compensation is applied automatically per material.

Default fit features:

- `lock_bumps=true` — r=2.0mm spheres, 0.4mm protrusion, engaging drainage cutouts
- `add_ribs=false` — optional vertical friction bumps on arm sides

## Files

- `bed_mat_interface.scad` — the generator (all parameters at top)
- `generate.sh` — CLI wrapper for rendering STLs
- `README.md` — user documentation, measurements, print settings
- `LICENSE` — MIT
- `.claude/skills/generate-part.md` — Claude Code skill for CLI generation
