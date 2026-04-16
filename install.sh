#!/usr/bin/env bash
# Unified installer for deepkpi-agents — single bundled skill (revelata-deepkpi).
# The repo root SKILL.md is the master controller; subfolders hold reference docs.
# Supports Claude Desktop, Claude.ai (web), and OpenClaw.
#
# Usage:
#   ./install.sh              Interactive — prompts for platform
#   ./install.sh openclaw     Skip prompt, go straight to OpenClaw install
#   curl ... | bash -s openclaw   Fetch from GitHub and install for OpenClaw
set -euo pipefail

GITHUB_CODELOAD="https://codeload.github.com/revelata/deepkpi-agents/tar.gz/main"

# Installed folder name (OpenClaw skills dir and Claude zip root).
BUNDLE_DIR_NAME="revelata-deepkpi"

# Reference-doc folders copied into the bundle (repo root layout; no skills/ prefix).
BUNDLE_SUBDIRS=(
  deepkpi-api
  company-summary-segments
  retrieve-kpi-data
  retrieve-sec-filing
  derive-implied-metric
  format-deepkpi-for-excel
  analyze-seasonality
  analyst-report-pressure-test
)

# Must match `name:` in root SKILL.md (same as install folder basename).
OPENCLAW_SKILL_ENTRY_KEY="${BUNDLE_DIR_NAME}"

OPENCLAW_SKILLS_ROOT="${OPENCLAW_SKILLS_ROOT:-${HOME}/.openclaw/skills}"
CONFIG_FILE="${HOME}/.openclaw/openclaw.json"

die() { echo "Error: $*" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
if [[ -z "$SCRIPT_DIR" ]]; then
  die "could not resolve script directory"
fi

# Local clone = repo root SKILL.md present (layout after skills/ → root move).
if [[ -f "${SCRIPT_DIR}/SKILL.md" ]]; then
  HAS_LOCAL=true
  DEFAULT_REPO_ROOT="$SCRIPT_DIR"
else
  HAS_LOCAL=false
  DEFAULT_REPO_ROOT=""
fi

TMP_EXTRACT=""
TMP_BUNDLE=""
cleanup() {
  [[ -n "${TMP_EXTRACT}" && -d "${TMP_EXTRACT}" ]] && rm -rf "${TMP_EXTRACT}"
  [[ -n "${TMP_BUNDLE}" && -d "${TMP_BUNDLE}" ]] && rm -rf "${TMP_BUNDLE}"
}
trap cleanup EXIT

# ── Helpers ──────────────────────────────────────────────────────────────────

default_zip_out_dir() {
  if [[ -d "${HOME}/Desktop" ]]; then
    echo "${HOME}/Desktop/deepkpi-skills"
  elif [[ -d "${HOME}/Downloads" ]]; then
    echo "${HOME}/Downloads/deepkpi-skills"
  else
    echo "${HOME}/deepkpi-skills"
  fi
}

# Download and extract GitHub tarball; print absolute repo root path on stdout.
fetch_repo_root_from_github() {
  TMP_EXTRACT="$(mktemp -d)"
  echo "Downloading repository tarball from GitHub..." >&2
  (
    cd "$TMP_EXTRACT"
    curl -fsSL "$GITHUB_CODELOAD" | tar -xz
  )
  shopt -s nullglob
  local topdirs=( "$TMP_EXTRACT"/* )
  shopt -u nullglob
  if [[ ${#topdirs[@]} -ne 1 || ! -d "${topdirs[0]}" ]]; then
    die "unexpected archive layout (expected exactly one top-level directory)"
  fi
  echo "${topdirs[0]}"
}

# Resolve directory containing SKILL.md and all BUNDLE_SUBDIRS.
resolve_repo_root() {
  if $HAS_LOCAL; then
    echo "$DEFAULT_REPO_ROOT"
    return
  fi
  fetch_repo_root_from_github
}

# Build ${dest_parent}/${BUNDLE_DIR_NAME} from repo root.
build_bundle_at() {
  local repo_root="$1"
  local dest_parent="$2"
  local bundle_root="${dest_parent}/${BUNDLE_DIR_NAME}"

  [[ -f "${repo_root}/SKILL.md" ]] || die "SKILL.md not found in ${repo_root}"

  rm -rf "$bundle_root"
  mkdir -p "$bundle_root"
  cp "${repo_root}/SKILL.md" "${bundle_root}/SKILL.md"

  local d
  for d in "${BUNDLE_SUBDIRS[@]}"; do
    [[ -d "${repo_root}/${d}" ]] || die "missing folder ${d}/ under ${repo_root}"
    cp -R "${repo_root}/${d}" "${bundle_root}/"
  done
}

# Stage bundle in a temp dir; echo absolute path to .../revelata-deepkpi
stage_bundle() {
  local repo_root
  repo_root="$(resolve_repo_root)"
  TMP_BUNDLE="$(mktemp -d)"
  build_bundle_at "$repo_root" "$TMP_BUNDLE"
  echo "${TMP_BUNDLE}/${BUNDLE_DIR_NAME}"
}

zip_bundle_for_claude() {
  local bundle_path="$1"
  local out_dir="$2"
  local parent
  parent="$(dirname "$bundle_path")"
  [[ "$(basename "$bundle_path")" == "$BUNDLE_DIR_NAME" ]] || die "zip_bundle_for_claude: wrong bundle path"

  mkdir -p "$out_dir"
  rm -f "${out_dir}/${BUNDLE_DIR_NAME}.zip"
  echo "Writing: ${out_dir}/${BUNDLE_DIR_NAME}.zip"
  (cd "$parent" && zip -qr "${out_dir}/${BUNDLE_DIR_NAME}.zip" "$BUNDLE_DIR_NAME")
}

install_openclaw_bundle() {
  local bundle_path="$1"
  mkdir -p "$OPENCLAW_SKILLS_ROOT"
  echo "Installing bundled skill into: ${OPENCLAW_SKILLS_ROOT}/${BUNDLE_DIR_NAME}"
  rm -rf "${OPENCLAW_SKILLS_ROOT}/${BUNDLE_DIR_NAME}"
  cp -R "$bundle_path" "${OPENCLAW_SKILLS_ROOT}/${BUNDLE_DIR_NAME}"
  echo "  ✓ ${BUNDLE_DIR_NAME}"
  echo ""
}

configure_openclaw() {
  echo "─── OpenClaw configuration ───"
  echo ""
  printf 'Need an Account? \e]8;;https://www.revelata.com/signup?product_id=0\ahttps://www.revelata.com/signup?product_id=0\e]8;;\a\n'
  printf 'Have an Account? Retrieve your API key here: \e]8;;https://www.revelata.com/ai-credits\ahttps://www.revelata.com/ai-credits\e]8;;\a\n\n'
  read -r -p "Paste your deepKPI API key (dk_...): " DEEPKPI_API_KEY </dev/tty
  if [[ -z "${DEEPKPI_API_KEY}" ]]; then
    echo "No API key provided, aborting."
    exit 1
  fi

  mkdir -p "$(dirname "${CONFIG_FILE}")"

  local entry_key="$OPENCLAW_SKILL_ENTRY_KEY"

  if [[ ! -f "${CONFIG_FILE}" ]]; then
    cat > "${CONFIG_FILE}" <<CFGEOF
{
  "skills": {
    "entries": {
      "${entry_key}": {
        "enabled": true,
        "env": {
          "DEEPKPI_API_KEY": "${DEEPKPI_API_KEY}"
        }
      }
    },
    "load": {
      "extraDirs": ["${OPENCLAW_SKILLS_ROOT}"],
      "watch": true
    }
  }
}
CFGEOF
    echo "Created ${CONFIG_FILE}."
  else
    python3 - <<PYEOF
import json
import pathlib

cfg_path = pathlib.Path("${CONFIG_FILE}")
data = json.loads(cfg_path.read_text())

skills = data.setdefault("skills", {})
entries = skills.setdefault("entries", {})

# Migrate env from legacy keys (old skill ids / per-folder install).
entry = entries.setdefault("${entry_key}", {})
for legacy_key in ("deepkpi-api", "deepkpi"):
    legacy = entries.pop(legacy_key, None)
    if isinstance(legacy, dict):
        entry.setdefault("enabled", legacy.get("enabled", True))
        old_env = legacy.get("env") or {}
        new_env = entry.setdefault("env", {})
        for k, v in old_env.items():
            new_env.setdefault(k, v)
entry["enabled"] = True
env = entry.setdefault("env", {})
env["DEEPKPI_API_KEY"] = "${DEEPKPI_API_KEY}"

load = skills.setdefault("load", {})
extra = load.setdefault("extraDirs", [])
skills_dir = "${OPENCLAW_SKILLS_ROOT}"
if skills_dir not in extra:
    extra.append(skills_dir)
load.setdefault("watch", True)

cfg_path.write_text(json.dumps(data, indent=2))
PYEOF
    echo "Updated ${CONFIG_FILE}."
  fi

  echo ""
  read -r -p "Restart the OpenClaw gateway now? [y/N] " RESTART_CHOICE </dev/tty
  if [[ "${RESTART_CHOICE}" =~ ^[Yy]$ ]]; then
    if command -v openclaw >/dev/null 2>&1; then
      echo "Restarting OpenClaw gateway..."
      openclaw gateway restart || {
        echo "Failed to restart. Please restart OpenClaw manually."
        exit 1
      }
      echo "Gateway restarted."
    else
      echo "'openclaw' CLI not found. Please restart the gateway manually."
    fi
  else
    echo "Skipping restart. Restart OpenClaw manually to pick up the new skills."
  fi
}

# ── Main ─────────────────────────────────────────────────────────────────────

MODE="${1:-}"

if [[ -z "$MODE" ]]; then
  echo ""
  echo "deepkpi-agents skill installer"
  echo ""
  echo "Where will you use this skill?"
  echo "  1) Claude Desktop"
  echo "  2) Claude.ai (web)"
  echo "  3) OpenClaw"
  echo ""
  read -r -p "Enter 1, 2, or 3: " choice </dev/tty || true
  case "${choice:-}" in
    1) MODE="claude-desktop" ;;
    2) MODE="claude-web" ;;
    3) MODE="openclaw" ;;
    *) die "invalid choice (expected 1, 2, or 3)" ;;
  esac
fi

case "$MODE" in
  claude-desktop)
    BUNDLE_PATH="$(stage_bundle)"
    OUT="$(default_zip_out_dir)"
    zip_bundle_for_claude "$BUNDLE_PATH" "$OUT"
    echo ""
    echo "Next steps (Claude Desktop):"
    echo "  1. Open Claude Desktop and sign in."
    echo '  2. Settings → Capabilities → enable "Code execution and file creation".'
    echo "  3. Customize → Skills → + → Upload a skill."
    echo "  4. Upload this single ZIP:"
    echo "       ${OUT}/${BUNDLE_DIR_NAME}.zip"
    echo "  5. Enable the skill with its toggle."
    echo ""
    echo "Packaging rules: https://support.claude.com/en/articles/12512198-creating-custom-skills"
    ;;

  claude-web)
    BUNDLE_PATH="$(stage_bundle)"
    OUT="$(default_zip_out_dir)"
    zip_bundle_for_claude "$BUNDLE_PATH" "$OUT"
    echo ""
    echo "Next steps (Claude.ai):"
    echo "  1. Sign in at https://claude.ai"
    echo '  2. Settings → Capabilities → enable "Code execution and file creation".'
    echo "  3. Open Customize → Skills: https://claude.ai/customize/skills"
    echo "  4. Click + → Upload a skill, and upload:"
    echo "       ${OUT}/${BUNDLE_DIR_NAME}.zip"
    echo "  5. Enable the skill with its toggle."
    echo ""
    echo "Help: https://support.claude.com/en/articles/12512180-using-skills-in-claude"
    ;;

  openclaw)
    echo ""
    echo "deepkpi-agents — OpenClaw installer"
    echo ""
    BUNDLE_PATH="$(stage_bundle)"
    install_openclaw_bundle "$BUNDLE_PATH"
    configure_openclaw
    echo ""
    echo "Installed bundled skill:"
    echo "  • ${BUNDLE_DIR_NAME}/"
    echo ""
    echo "Verify: openclaw skills list"
    echo "Docs:   https://github.com/revelata/deepkpi-agents"
    ;;

  *)
    die "unknown mode: ${MODE} (expected: openclaw, claude-desktop, claude-web, or run without arguments for interactive)"
    ;;
esac

echo ""
echo "Done."
