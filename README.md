# bed-mat-openscad

Parametric OpenSCAD generator for custom truck bed mat organizer attachments.
Compatible with TMat and similar X-pattern snap-in bed mat systems.

*Not affiliated with or endorsed by TMat. TMat is a trademark of its
respective owner.*

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

Requires [OpenSCAD](https://openscad.org/).

### OpenSCAD GUI

Open `bed_mat_interface.scad` in OpenSCAD and set parameters in the
Customizer panel (Window > Customizer). Render (F6) and export STL.

### Command line (`generate.sh`)

`generate.sh` wraps the OpenSCAD CLI with named flags and writes a
descriptively named STL:

```bash
./generate.sh -t straight -u 4            # 2U straight wall
./generate.sh -t corner -x 2 -y 2         # corner, 1U legs
./generate.sh -t tee --joint              # T with interface at the joint
./generate.sh -t post -H 20 -c -0.1       # short test post, slightly tighter
./generate.sh -t plug -m PETG -o ~/stls   # hole plug in PETG
./generate.sh --help                      # full flag reference
```

Anything without a dedicated flag can be passed straight through with
`-D 'name=value'`, and `--dry-run` prints the OpenSCAD command instead
of running it.

For persistent local defaults (output directory, material, OpenSCAD
path, etc.), copy `.env.example` to `.env` and edit. CLI flags always
override `.env`.

Plain OpenSCAD works too:

```bash
openscad -D 'part_type="straight"; height=50; straight_half_units=3' \
    bed_mat_interface.scad -o my_wall.stl
```

### Key Parameters

| Parameter | Default | Notes |
|-----------|---------|-------|
| Part type | `straight` | post, straight, corner, tee, plug |
| Height | 64mm | Above the mat surface; OEM pieces are 63.5mm (2.5") |
| Wall width | 0 (auto) | 0 matches the interface profile width |
| Half-units | varies | Length in 0.5U steps (1 = 0.5U, 2 = 1U, ...) |
| Interface spacing | diagonal | `diagonal` (OEM) or `dense` (every recess) |
| Material | ASA | PLA, PETG, ASA, ABS, Custom — sets shrinkage compensation |
| Fit clearance | 0 | mm per side; negative = tighter, positive = looser |
| Lock bumps | on | Partial spheres at the arm tips that engage the drainage cutouts |
| Ribs | off | Optional vertical friction ribs on the arm sides |

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

**Straight walls** place interfaces at whole-unit positions only, with
the body centered over them. For example, `straight_half_units=3`
(1.5U) has two interfaces 1U apart, and the extra 0.5U of body is split
evenly, extending 0.25U past each end interface.

**Corner and T legs** place an interface at every recess along each
leg, measured from the joint: every half-unit in diagonal mode, every
whole unit in dense mode (dense half-units fall between recesses). The
joint interface is off by default. A part with no interfaces at all
(e.g. a dense 1x1 corner with no joint) renders with a warning.
Stock OEM corner and T pieces are 1 half-unit per leg with no joint
interface.

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

The default `fit_clearance=0` is tuned for an ideal friction fit based
on test prints across PLA, PETG, and ASA. A built-in base offset
accounts for the difference between first-party male piece dimensions
and the slightly larger female recesses. Shrinkage compensation is
applied automatically based on the selected material.

Lock bumps are enabled by default and engage the drainage cutouts in
each recess for positive retention under vibration.

To dial in the fit for your specific mat and printer:

1. Print a **post** at `height=20` with default settings
2. Adjust `fit_clearance` in 0.05mm increments (negative = tighter,
   positive = looser)
3. Optionally enable ribs (`add_ribs=true`) for additional friction
4. Tune `lock_bump_protrusion` if lock engagement is too strong or weak

Fit will vary by printer calibration and individual mat tolerances.

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
