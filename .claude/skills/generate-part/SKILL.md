---
description: Generate STL files from the bed mat interface OpenSCAD model
---

# generate-part

## When to use

When the user asks to generate, render, export, or create a bed mat part/STL.
Trigger phrases: "generate a", "make me a", "render a", "create a", "export a",
"I need a", followed by part type keywords (post, wall, straight, corner, tee,
plug, divider, pillar).

## Instructions

Use `generate.sh` in the project root. It wraps the OpenSCAD CLI with typed
flags and auto-generates descriptive filenames.

**Only pass flags that differ from defaults.** The defaults are already tuned
from test prints. Do not pass `--lock`, `--lock-radius`, `--lock-protrusion`,
or `-m ASA` unless the user wants non-default values for these.

### Defaults (do NOT pass these as flags)

- Material: ASA
- Lock bumps: on (r=2.0, p=0.4)
- Ribs: off
- Height: 64mm
- Fit clearance: 0 (tested ideal fit)
- Spacing: diagonal (OEM pattern)

### Quick Reference

```bash
# Minimal — just type and size
./generate.sh -t post -H 20
./generate.sh -t straight -u 4
./generate.sh -t corner -x 2 -y 2
./generate.sh -t tee -x 1 -y 1 --joint
./generate.sh -t plug

# Override material for prototyping
./generate.sh -t straight -u 4 -m PETG

# Tweak fit
./generate.sh -t post -c -0.1

# Output to specific directory
./generate.sh -t post -o /path/to/output

# Disable locks for a specific part
./generate.sh -t straight -u 4 -D 'lock_bumps=false'
```

Run `./generate.sh --help` for full flag reference.

### Key Flags

| Flag | Description | Default |
|------|-------------|---------|
| `-t, --type` | post, straight, corner, tee, plug (required) | — |
| `-H, --height` | Height above mat surface (mm) | 64 |
| `-m, --material` | PLA, PETG, ASA, ABS, Custom | ASA |
| `-c, --clearance` | mm per side, 0 = ideal fit | 0 |
| `-u, --units` | Straight half-units (2 = 1U) | 2 |
| `-x, --units-x` | X leg half-units | 1 |
| `-y, --units-y` | Y leg half-units | 1 |
| `--joint` | Add interface at corner/tee joint | off |
| `--lock` | Enable lock bumps | on |
| `--lock-radius` | Lock sphere radius (mm) | 2.0 |
| `--lock-protrusion` | Bump protrusion (mm) | 0.4 |
| `--no-ribs` | Disable friction ribs | already off |
| `--rib-radius` | Rib radius if ribs enabled (mm) | 0.3 |
| `--spacing` | diagonal or dense | diagonal |
| `-o, --output` | Output directory | cwd |
| `-n, --name` | Override auto filename | — |
| `-D` | Raw OpenSCAD -D flag (repeatable) | — |
| `--dry-run` | Print command without running | — |

### Auto Filename Format

`{type}[_material][_{size}]_h{height}[_c{clearance}][_ribs-{radius}][_lock[-{radius}][-{protrusion}]].stl`

Only non-default features appear in the filename.

### After Rendering

Report the output file path and key non-default parameters used.

### Sizing Notes

- Grid pitch = 50.8mm (2 inches) between adjacent recesses
- `--spacing diagonal` (default): 1 unit = 101.6mm (skips one recess)
- `--spacing dense`: 1 unit = 50.8mm (every recess)
- Half-units allow 0.5U increments for overhang beyond last interface
- Interfaces only placed at whole-unit positions
- Stock corner/T pieces use 1 half-unit per leg (no interface at joint)

### Print Recommendations

If the user asks about print settings, refer to the README. Key points:

- Print upside down (interface on top)
- 0.6mm nozzle recommended
- ASA for outdoor UV, PETG for prototyping
- 15-20% infill, gyroid or adaptive cubic
- Min rib radius = half the nozzle diameter
