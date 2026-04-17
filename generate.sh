#!/usr/bin/env bash
#
# generate.sh — Render bed mat interface parts to STL
#
# Wrapper around OpenSCAD CLI for bed_mat_interface.scad. Pass part parameters
# as flags and get a named STL file in the output directory.
#
# Usage:
#   ./generate.sh [options]
#
# Examples:
#   # Basic straight wall, 2U long, 40mm tall
#   ./generate.sh -t straight -u 4 -H 50
#
#   # Corner piece for PETG with tighter fit
#   ./generate.sh -t corner -m PETG -c -0.2
#
#   # Post with lock bumps, custom protrusion
#   ./generate.sh -t post -H 20 --lock --lock-protrusion 0.4
#
#   # Test fit post: short, no ribs, specific clearance
#   ./generate.sh -t post -H 20 --no-ribs -c -0.25
#
#   # Dense spacing corner with joint interface
#   ./generate.sh -t corner --spacing dense --joint -x 2 -y 2
#
#   # Plug with custom cap thickness
#   ./generate.sh -t plug --cap-thickness 4
#
#   # Pass arbitrary OpenSCAD -D flags for parameters not covered by flags
#   ./generate.sh -t post -D 'lock_bump_depth=12' -D 'wall_thickness=4'
#
# Options:
#   -t, --type TYPE        Part type: post, straight, corner, tee, plug (required)
#   -o, --output DIR       Output directory (default: current directory)
#   -n, --name NAME        Output filename (default: auto-generated)
#   -H, --height MM        Height above mat surface (default: 40)
#   -w, --wall-width MM    Body wall width, 0 = auto (default: 0)
#   -m, --material MAT     Material: PLA, PETG, ASA, ABS, Custom (default: PLA)
#   -c, --clearance MM     Fit clearance per side, negative = tighter (default: 0)
#   -s, --shrinkage PCT    Override shrinkage % (-1 = use material default)
#
#   Straight wall:
#   -u, --units N          Half-units length (2 = 1U, 3 = 1.5U, ...) (default: 2)
#   --wall-offset MM       Wall offset from center (default: 0)
#
#   Corner / T-shape:
#   -x, --units-x N        X leg half-units (default: 1)
#   -y, --units-y N        Y leg half-units (default: 1)
#   --joint                Add interface at corner/tee joint
#   --no-joint             Force joint interface off (override .env)
#   --wall-position POS    Corner: none, inside, outside (default: none)
#   --stem-position POS    Tee: none, left, right (default: none)
#
#   Plug:
#   --cap-thickness MM     Top cap thickness (default: 3)
#   --no-notch             Disable finger notch
#
#   Fit features:
#   --no-ribs              Disable friction ribs
#   --rib-radius MM        Rib radius (default: 0.3)
#   --lock                 Enable lock bumps
#   --no-lock              Disable lock bumps (override .env/default)
#   --lock-radius MM       Lock bump sphere radius (default: 1.5)
#   --lock-protrusion MM   Lock bump protrusion (default: 0.5)
#   --lock-depth MM        Lock bump depth from surface (default: 13.1)
#
#   Grid:
#   --spacing MODE         Interface spacing: diagonal, dense (default: diagonal)
#
#   Advanced:
#   -D 'key=value'         Pass raw OpenSCAD -D flag (repeatable)
#   --dry-run              Print the OpenSCAD command without running it
#   -h, --help             Show this help message
#
# Configuration:
#   A .env file next to this script is sourced before arg parsing. Any variable
#   used below (OUTPUT_DIR, MATERIAL, HEIGHT, LOCK_BUMPS, etc.) can be set
#   there. CLI flags always override .env. See .env.example for the full list.

set -euo pipefail

# --- Defaults ---
PART_TYPE=""
OUTPUT_DIR="."
OUTPUT_NAME=""
HEIGHT=""
WALL_WIDTH=""
MATERIAL=""
CLEARANCE=""
SHRINKAGE=""
HALF_UNITS=""
WALL_OFFSET=""
UNITS_X=""
UNITS_Y=""
JOINT=""
WALL_POSITION=""
STEM_POSITION=""
CAP_THICKNESS=""
FINGER_NOTCH=""
ADD_RIBS=""
RIB_RADIUS=""
LOCK_BUMPS=""
LOCK_RADIUS=""
LOCK_PROTRUSION=""
LOCK_DEPTH=""
SPACING=""
EXTRA_D=()
DRY_RUN=false

# --- Find .scad source ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCAD_FILE="$SCRIPT_DIR/bed_mat_interface.scad"

if [[ ! -f "$SCAD_FILE" ]]; then
  echo "Error: $SCAD_FILE not found" >&2
  exit 1
fi

# --- Load .env (non-tracked, project-local defaults; CLI flags override) ---
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/.env"
fi

# --- Find OpenSCAD (honors $OPENSCAD from .env/env if set) ---
find_openscad() {
  if [[ -n "${OPENSCAD:-}" ]]; then
    if [[ -x "$OPENSCAD" ]] || command -v "$OPENSCAD" &>/dev/null; then
      echo "$OPENSCAD"
      return
    fi
    echo "Error: OPENSCAD is set to '$OPENSCAD' but is not executable." >&2
    exit 1
  fi
  if command -v openscad &>/dev/null; then
    echo "openscad"
  elif [[ -x "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" ]]; then
    echo "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
  else
    echo "Error: OpenSCAD not found. Install it or add to PATH." >&2
    exit 1
  fi
}

# --- Usage ---
usage() {
  awk '/^# Usage:/,!/^#/' "$0" | grep '^#' | sed 's/^# \{0,1\}//'
  exit 0
}

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t | --type)
      PART_TYPE="$2"
      shift 2
      ;;
    -o | --output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -n | --name)
      OUTPUT_NAME="$2"
      shift 2
      ;;
    -H | --height)
      HEIGHT="$2"
      shift 2
      ;;
    -w | --wall-width)
      WALL_WIDTH="$2"
      shift 2
      ;;
    -m | --material)
      MATERIAL="$2"
      shift 2
      ;;
    -c | --clearance)
      CLEARANCE="$2"
      shift 2
      ;;
    -s | --shrinkage)
      SHRINKAGE="$2"
      shift 2
      ;;
    -u | --units)
      HALF_UNITS="$2"
      shift 2
      ;;
    --wall-offset)
      WALL_OFFSET="$2"
      shift 2
      ;;
    -x | --units-x)
      UNITS_X="$2"
      shift 2
      ;;
    -y | --units-y)
      UNITS_Y="$2"
      shift 2
      ;;
    --joint)
      JOINT=true
      shift
      ;;
    --no-joint)
      JOINT=false
      shift
      ;;
    --wall-position)
      WALL_POSITION="$2"
      shift 2
      ;;
    --stem-position)
      STEM_POSITION="$2"
      shift 2
      ;;
    --cap-thickness)
      CAP_THICKNESS="$2"
      shift 2
      ;;
    --no-notch)
      FINGER_NOTCH=false
      shift
      ;;
    --no-ribs)
      ADD_RIBS=false
      shift
      ;;
    --rib-radius)
      RIB_RADIUS="$2"
      shift 2
      ;;
    --lock)
      LOCK_BUMPS=true
      shift
      ;;
    --no-lock)
      LOCK_BUMPS=false
      shift
      ;;
    --lock-radius)
      LOCK_RADIUS="$2"
      shift 2
      ;;
    --lock-protrusion)
      LOCK_PROTRUSION="$2"
      shift 2
      ;;
    --lock-depth)
      LOCK_DEPTH="$2"
      shift 2
      ;;
    --spacing)
      SPACING="$2"
      shift 2
      ;;
    -D)
      EXTRA_D+=("$2")
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h | --help) usage ;;
    *)
      echo "Error: Unknown option: $1" >&2
      echo "Run with --help for usage" >&2
      exit 1
      ;;
  esac
done

# --- Validate ---
if [[ -z "$PART_TYPE" ]]; then
  echo "Error: --type is required" >&2
  echo "Run with --help for usage" >&2
  exit 1
fi

case "$PART_TYPE" in
  post | straight | corner | tee | plug) ;;
  *)
    echo "Error: Invalid part type '$PART_TYPE'. Must be: post, straight, corner, tee, plug" >&2
    exit 1
    ;;
esac

# --- Build -D flags ---
D_FLAGS=()

add_d() {
  # $1 = OpenSCAD variable name, $2 = value
  D_FLAGS+=("-D" "$1=$2")
}

add_d_str() {
  # $1 = OpenSCAD variable name, $2 = value (quoted as string)
  D_FLAGS+=("-D" "$1=\"$2\"")
}

add_d_str "part_type" "$PART_TYPE"

[[ -n "$HEIGHT" ]] && add_d "height" "$HEIGHT"
[[ -n "$WALL_WIDTH" ]] && add_d "wall_width" "$WALL_WIDTH"
[[ -n "$MATERIAL" ]] && add_d_str "material" "$MATERIAL"
[[ -n "$CLEARANCE" ]] && add_d "fit_clearance" "$CLEARANCE"
[[ -n "$SHRINKAGE" ]] && add_d "shrinkage_override" "$SHRINKAGE"

# Straight
[[ -n "$HALF_UNITS" ]] && add_d "straight_half_units" "$HALF_UNITS"
[[ -n "$WALL_OFFSET" ]] && add_d "straight_wall_offset" "$WALL_OFFSET"

# Corner
[[ -n "$UNITS_X" ]] && add_d "corner_half_units_x" "$UNITS_X"
[[ -n "$UNITS_Y" ]] && add_d "corner_half_units_y" "$UNITS_Y"
[[ -n "$JOINT" ]] && add_d "corner_interface_at_joint" "$JOINT"
[[ -n "$WALL_POSITION" ]] && add_d_str "corner_wall_position" "$WALL_POSITION"

# Tee (reuse -x/-y and --joint)
[[ -n "$UNITS_X" ]] && add_d "tee_half_units_x" "$UNITS_X"
[[ -n "$UNITS_Y" ]] && add_d "tee_half_units_y" "$UNITS_Y"
[[ -n "$JOINT" ]] && add_d "tee_interface_at_joint" "$JOINT"
[[ -n "$STEM_POSITION" ]] && add_d_str "tee_stem_position" "$STEM_POSITION"

# Plug
[[ -n "$CAP_THICKNESS" ]] && add_d "plug_cap_thickness" "$CAP_THICKNESS"
[[ "$FINGER_NOTCH" == false ]] && add_d "plug_finger_notch" "false"

# Fit features
[[ "$ADD_RIBS" == false ]] && add_d "add_ribs" "false"
[[ -n "$RIB_RADIUS" ]] && add_d "rib_radius" "$RIB_RADIUS"
[[ -n "$LOCK_BUMPS" ]] && add_d "lock_bumps" "$LOCK_BUMPS"
[[ -n "$LOCK_RADIUS" ]] && add_d "lock_bump_radius" "$LOCK_RADIUS"
[[ -n "$LOCK_PROTRUSION" ]] && add_d "lock_bump_protrusion" "$LOCK_PROTRUSION"
[[ -n "$LOCK_DEPTH" ]] && add_d "lock_bump_depth" "$LOCK_DEPTH"

# Grid
[[ -n "$SPACING" ]] && add_d_str "interface_spacing" "$SPACING"

# Extra -D flags
for d in "${EXTRA_D[@]+"${EXTRA_D[@]}"}"; do
  D_FLAGS+=("-D" "$d")
done

# --- Auto-generate filename ---
if [[ -z "$OUTPUT_NAME" ]]; then
  NAME="${PART_TYPE}"

  [[ -n "$MATERIAL" ]] && NAME+="_$(echo "$MATERIAL" | tr '[:upper:]' '[:lower:]')"

  case "$PART_TYPE" in
    straight)
      u="${HALF_UNITS:-2}"
      NAME+="_${u}hu"
      ;;
    corner | tee)
      x="${UNITS_X:-1}"
      y="${UNITS_Y:-1}"
      NAME+="_${x}x${y}"
      ;;
  esac

  h="${HEIGHT:-40}"
  NAME+="_h${h}"
  [[ -n "$CLEARANCE" ]] && NAME+="_c${CLEARANCE}"
  if [[ "$ADD_RIBS" != false && -n "$RIB_RADIUS" ]]; then
    NAME+="_ribs-${RIB_RADIUS}"
  fi
  if [[ "$LOCK_BUMPS" == false ]]; then
    NAME+="_nolock"
  elif [[ "$LOCK_BUMPS" == true ]]; then
    LOCK_TAG="_lock"
    [[ -n "$LOCK_RADIUS" ]] && LOCK_TAG+="-${LOCK_RADIUS}"
    [[ -n "$LOCK_PROTRUSION" ]] && LOCK_TAG+="-${LOCK_PROTRUSION}"
    NAME+="$LOCK_TAG"
  fi

  OUTPUT_NAME="${NAME}.stl"
fi

# Ensure .stl extension
[[ "$OUTPUT_NAME" != *.stl ]] && OUTPUT_NAME="${OUTPUT_NAME}.stl"

OUTPUT_PATH="$OUTPUT_DIR/$OUTPUT_NAME"

# --- Build command ---
OPENSCAD="$(find_openscad)"
CMD=("$OPENSCAD" "${D_FLAGS[@]}" "$SCAD_FILE" "-o" "$OUTPUT_PATH")

if $DRY_RUN; then
  echo "Would run:"
  printf '  %q' "${CMD[@]}"
  echo
  exit 0
fi

# --- Render ---
echo "Rendering: $OUTPUT_NAME"
echo "Parameters: ${D_FLAGS[*]}"

mkdir -p "$OUTPUT_DIR"

if OUTPUT=$("${CMD[@]}" 2>&1); then
  # Extract genus from OpenSCAD output
  GENUS=$(echo "$OUTPUT" | sed -n 's/.*Genus: \([0-9]*\).*/\1/p' | tail -1)
  GENUS="${GENUS:-?}"
  echo "Done: $OUTPUT_PATH"
  echo "Genus: $GENUS"
else
  echo "Error during rendering:" >&2
  echo "$OUTPUT" >&2
  exit 1
fi
