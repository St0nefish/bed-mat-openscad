# bed-mat-openscad

Parametric OpenSCAD generator for custom truck bed mat organizer attachments.
Compatible with TMat and similar X-pattern snap-in bed mat systems.

## What is this?

Truck bed mats like TMat have a grid of X-shaped recesses that accept
snap-in organizer pieces (walls, corners, T-connectors) to divide the
bed into sections and keep cargo from sliding around.

The factory attachment selection is limited (straight, corner, T) and
expensive. This project generates custom attachments with full control
over size, fit, and configuration.

## Part Types

| Type | Description |
|------|-------------|
| **Post/Pillar** | Single interface with a vertical post — useful for point stops |
| **Straight Wall** | N interfaces connected by a wall — dividers and barriers |
| **Corner/L-Shape** | Two legs at 90 degrees — corner containment |
| **T-Shape** | Crossbar with perpendicular stem — mid-section dividers |
| **Hole Plug** | Caps unused holes to keep them clean |

## Usage

Open `bed_mat_interface.scad` in OpenSCAD. All parameters are in the
Customizer panel (Window > Customizer) or can be set on the command line:

```bash
openscad -D 'part_type="straight"; height=50; straight_half_units=3' \
    bed_mat_interface.scad -o my_wall.stl
```

### Key Parameters

- **Part Type**: post, straight, corner, tee, plug
- **Height**: wall height above the mat surface (mm)
- **Wall Width**: body width (0 = auto-match interface profile)
- **Half-Units**: sizing in 0.5x pitch increments (1 = 0.5U, 2 = 1U, etc.)
- **Interface Spacing**: diagonal (OEM default) or dense (every recess)
- **Fit Clearance**: tune snugness (negative = tighter, positive = looser)
- **Ribs**: optional vertical friction ribs on the interface
- **Lock Bumps**: hemispheres at arm tips that engage drainage cutouts

### Grid Layout

The mat has a uniform grid of X-shaped recesses at **50.8mm (2 inch)**
spacing in both X and Y.

```text
X 0 X 0 X
0 X 0 X 0
X 0 X 0 X
```

OEM attachments use a **diagonal pattern** — interfaces in every other
recess, skipping adjacent ones. This means the effective interface pitch
is 101.6mm (4 inches) along each axis:

```text
OEM straight:      [I]---101.6mm---[I]
OEM corner:        [I]
                    |  (diagonal)
                   [I]
OEM T-shape:       [I]---[I]
                          |
                         [I]
```

The `interface_spacing` parameter controls this:

- `"diagonal"` (default) — OEM pattern, interfaces every 101.6mm
- `"dense"` — every recess, interfaces every 50.8mm (more anchor points)

### Sizing

Lengths are specified in **half-units** where 1 unit = one interface
pitch (101.6mm in diagonal mode, 50.8mm in dense mode). This allows
0.5U increments for bodies that extend beyond the last interface to
catch larger items.

Interfaces are placed at every whole-unit position. For example, a
straight with `straight_half_units=3` (1.5U) has interfaces at 0 and
1U, with the body extending an extra 0.5U past the second interface.

## Printing

### Orientation

All parts print **upside down** — the flat top/cap sits on the build
plate, interfaces point upward. This gives a smooth visible surface on
top and avoids supports for the interface geometry.

### Recommended Settings

| Setting | Value |
|---------|-------|
| Nozzle | 0.6mm recommended (speed, strength) |
| Layer height | 0.2-0.3mm |
| Walls | 4-6 |
| Top/bottom layers | 4-6 |
| Infill | 15-20% gyroid or adaptive cubic |
| Material | ASA (outdoor UV) or PETG (prototyping) |

### Minimum Rib Radius by Nozzle Size

Ribs must be at least one nozzle width in diameter to print reliably:

| Nozzle | Min rib radius |
|--------|---------------|
| 0.4mm | 0.2mm |
| 0.6mm | 0.3mm |
| 0.8mm | 0.4mm |

## Fit Tuning

The interface geometry is derived from caliper measurements of
first-party attachments and the mat recesses. At `fit_clearance=0` the
profile matches the first-party male dimensions exactly.

To dial in the fit for your specific mat and printer:

1. Print a **post** at `height=20` with `add_ribs=false` and
   `fit_clearance=0` as a baseline
2. Adjust `fit_clearance` in -0.05mm increments until snug
3. Optionally enable ribs (`add_ribs=true`) and tune `rib_radius`
4. Optionally enable `lock_bumps` for positive retention

Fit will vary by material (ASA shrinks more than PETG), printer
calibration, and individual mat tolerances.

## Interface Dimensions

Measured from first-party attachments and mat recesses with digital
calipers:

| Dimension | Source | Value |
|-----------|--------|-------|
| Grid pitch | Female recess | 50.8mm (2 inches), uniform X/Y |
| Arm width | Male piece | 12.1mm |
| Arm tip shape | Male piece | Semicircle (r=6.05mm) |
| Bounding box | Male piece | 37.69mm square |
| Tip-to-tip diagonal | Male piece | 48.19mm |
| Center crack-to-crack | Male piece | 20.8mm |
| Recess depth | Female recess | 17.4mm |
| Tip-to-tip gap (adjacent) | Female recess | 12.81mm |
| Concavity-to-concavity gap | Female recess | 28.96mm |

## License

MIT
