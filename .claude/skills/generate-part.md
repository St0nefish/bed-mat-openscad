# generate-part

Generate STL files from the bed mat interface OpenSCAD model.

## When to use

When the user asks to generate, render, export, or create a bed mat part/STL.
Trigger phrases: "generate a", "make me a", "render a", "create a", "export a",
"I need a", followed by part type keywords (post, wall, straight, corner, tee,
plug, divider, pillar).

## Instructions

Use the OpenSCAD CLI to render `bed_mat_interface.scad` with the requested
parameters. The OpenSCAD binary location may vary by system — check for
`openscad` in PATH first, then common locations like `/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD`.

### Parameter Reference

**Part type** (`part_type`): `"post"`, `"straight"`, `"corner"`, `"tee"`, `"plug"`

**Shared parameters:**

- `height` — height above mat surface in mm (default: 40)
- `wall_width` — body width in mm, 0 = auto match profile (default: 0)
- `fit_clearance` — mm per side, negative = tighter (default: 0)
- `add_ribs` — boolean, vertical friction ribs (default: true)
- `rib_radius` — mm, semicircle rib radius (default: 0.3)
- `lock_bumps` — boolean, locking hemispheres at arm tips (default: false)
- `lock_bump_radius` — mm (default: 1.5)
- `lock_bump_depth` — mm from surface (default: 13.1)
- `interface_spacing` — `"diagonal"` (OEM, every other) or `"dense"` (every recess)

**Straight wall:**

- `straight_half_units` — length in half-units, min 2 (default: 2 = 1U)
- `straight_wall_offset` — mm offset from center (default: 0)

**Corner/L-shape:**

- `corner_half_units_x` / `corner_half_units_y` — leg lengths in half-units (default: 1)
- `corner_interface_at_joint` — boolean (default: false)
- `corner_wall_position` — `"none"`, `"inside"`, `"outside"` (default: "none")

**T-shape:**

- `tee_half_units_x` / `tee_half_units_y` — crossbar per-side / stem in half-units (default: 1)
- `tee_interface_at_joint` — boolean (default: false)
- `tee_stem_position` — `"none"`, `"left"`, `"right"` (default: "none")

**Plug:**

- `plug_cap_thickness` — mm (default: 3)
- `plug_finger_notch` — boolean (default: true)
- `plug_notch_radius` — mm (default: 5)
- `plug_notch_depth` — mm (default: 1.5)

### Rendering

Build the `-D` flags from the user's request and run:

```bash
openscad -D 'param1=value1; param2=value2' bed_mat_interface.scad -o output.stl
```

String parameters need inner quotes: `-D 'part_type="corner"'`

Multiple `-D` flags or semicolon-separated in one flag both work.

After rendering, report:

- Output file path
- Key parameters used
- Genus (from OpenSCAD output) — 0 is clean, nonzero may have cosmetic
  artifacts but typically slices fine

### Naming Convention

Name output files descriptively with key parameters:
`bed_mat_{type}_{units}u_h{height}[_c{clearance}][_r{rib_radius}].stl`

Examples:

- `bed_mat_straight_2u_h40.stl`
- `bed_mat_corner_1x1_h30_c-0.1.stl`
- `bed_mat_post_h20_ribs.stl`

### Sizing Notes

- Grid pitch = 50.8mm (2 inches) between adjacent recesses
- `interface_spacing="diagonal"` (default): 1 unit = 101.6mm (skips one recess)
- `interface_spacing="dense"`: 1 unit = 50.8mm (every recess)
- Half-units allow 0.5U increments for overhang beyond last interface
- Interfaces only placed at whole-unit positions
- Stock corner/T pieces use 1 half-unit per leg (no interface at joint)
- Larger pieces can enable `*_interface_at_joint` for extra support

### Print Recommendations

If the user asks about print settings, refer to the README. Key points:

- Print upside down (interface on top)
- 0.6mm nozzle recommended
- ASA for outdoor UV, PETG for prototyping
- 15-20% infill, gyroid or adaptive cubic
- Min rib radius = half the nozzle diameter
