# generate-part

Generate STL files from the bed mat interface OpenSCAD model.

## When to use

When the user asks to generate, render, export, or create a bed mat part/STL.
Trigger phrases: "generate a", "make me a", "render a", "create a", "export a",
"I need a", followed by part type keywords (post, wall, straight, corner, tee,
plug, divider, pillar).

## Instructions

Use `generate.sh` in the project root. It wraps the OpenSCAD CLI with typed
flags and auto-generates descriptive filenames.

Run `./generate.sh --help` for full flag reference.

### Quick Reference

```bash
# Basic examples
./generate.sh -t post -H 20
./generate.sh -t straight -u 4 -H 50
./generate.sh -t corner -x 2 -y 2 -m PETG -c -0.2
./generate.sh -t tee -x 1 -y 1 --joint
./generate.sh -t plug --cap-thickness 4

# Output to specific directory
./generate.sh -t post -H 20 -o /path/to/output

# Lock bumps
./generate.sh -t post --lock --lock-radius 2.0 --lock-protrusion 0.4

# Pass raw OpenSCAD variables not covered by flags
./generate.sh -t post -D 'wall_thickness=4'
```

### Key Flags

| Flag | OpenSCAD Variable | Description |
|------|-------------------|-------------|
| `-t, --type` | `part_type` | post, straight, corner, tee, plug (required) |
| `-H, --height` | `height` | Height above mat surface in mm |
| `-m, --material` | `material` | PLA, PETG, ASA, ABS, Custom |
| `-c, --clearance` | `fit_clearance` | mm per side, negative = tighter |
| `-u, --units` | `straight_half_units` | Straight length in half-units |
| `-x, --units-x` | `corner/tee_half_units_x` | X leg half-units |
| `-y, --units-y` | `corner/tee_half_units_y` | Y leg half-units |
| `--joint` | `*_interface_at_joint` | Add interface at corner/tee joint |
| `--lock` | `lock_bumps` | Enable lock bumps |
| `--lock-radius` | `lock_bump_radius` | Lock sphere radius (mm) |
| `--lock-protrusion` | `lock_bump_protrusion` | How far bump sticks out (mm) |
| `--no-ribs` | `add_ribs=false` | Disable friction ribs |
| `--spacing` | `interface_spacing` | diagonal or dense |
| `-o, --output` | — | Output directory |
| `-n, --name` | — | Override auto filename |
| `-D` | — | Raw OpenSCAD -D flag (repeatable) |
| `--dry-run` | — | Print command without running |

### Auto Filename Format

`{type}[_material][_{size}]_h{height}[_c{clearance}][_ribs-{radius}][_lock[-{radius}][-{protrusion}]].stl`

### After Rendering

Report:

- Output file path
- Key parameters used
- Genus if shown (0 = clean manifold, nonzero = cosmetic artifacts)

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
