#!/usr/bin/env bash
# Unified installer for deepkpi-agents skills.
# Supports Claude Desktop, Claude.ai (web), and OpenClaw.
#
# Usage:
#   ./install.sh              Interactive — prompts for platform
#   ./install.sh openclaw     Skip prompt, go straight to OpenClaw install
#   curl ... | bash -s openclaw   Fetch from GitHub and install for OpenClaw
set -euo pipefail

GITHUB_RAW="https://raw.githubusercontent.com/revelata/deepkpi-agents/main"

SKILL_NAMES=(
  deepkpi-api
  retrieve-kpi-data
  derive-implied-metric
  format-deepkpi-for-excel
  analyze-seasonality
)

CLAUDE_SKILL_NAMES=(
  retrieve-kpi-data
  derive-implied-metric
  format-deepkpi-for-excel
  analyze-seasonality
)

OPENCLAW_SKILLS_ROOT="${OPENCLAW_SKILLS_ROOT:-${HOME}/.openclaw/skills}"
CONFIG_FILE="${HOME}/.openclaw/openclaw.json"

die() { echo "Error: $*" >&2; exit 1; }

# Detect whether we're running from a local clone.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
LOCAL_SKILLS_DIR="${SCRIPT_DIR}/skills"
if [[ -d "$LOCAL_SKILLS_DIR" ]]; then
  HAS_LOCAL=true
else
  HAS_LOCAL=false
fi

# ── Helpers ──────────────────────────────────────────────────────────────────

TMPDIR_SKILLS=""

default_zip_out_dir() {
  if [[ -d "${HOME}/Desktop" ]]; then
    echo "${HOME}/Desktop/deepkpi-skills"
  elif [[ -d "${HOME}/Downloads" ]]; then
    echo "${HOME}/Downloads/deepkpi-skills"
  else
    echo "${HOME}/deepkpi-skills"
  fi
}

ensure_skills_dir() {
  if $HAS_LOCAL; then
    SKILLS_SRC="$LOCAL_SKILLS_DIR"
  else
    TMPDIR_SKILLS="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR_SKILLS"' EXIT
    SKILLS_SRC="$TMPDIR_SKILLS"
    local names=("$@")
    echo "Downloading skills from GitHub..."
    for name in "${names[@]}"; do
      mkdir -p "${TMPDIR_SKILLS}/${name}"
      curl -fsSL "${GITHUB_RAW}/skills/${name}/SKILL.md" \
        -o "${TMPDIR_SKILLS}/${name}/SKILL.md" || {
        echo "  ✗ Failed to download ${name}"
        exit 1
      }
      echo "  ✓ ${name}"
    done
    echo ""
  fi
}

zip_skills_to() {
  local out="$1"
  shift
  local names=("$@")
  mkdir -p "$out"
  echo "Writing ZIPs to: $out"
  (
    cd "$SKILLS_SRC"
    for name in "${names[@]}"; do
      rm -f "${out}/${name}.zip"
      zip -qr "${out}/${name}.zip" "$name"
      echo "  - ${name}.zip"
    done
  )
}

install_openclaw_skills() {
  ensure_skills_dir "${SKILL_NAMES[@]}"
  mkdir -p "$OPENCLAW_SKILLS_ROOT"
  echo "Installing skills into: ${OPENCLAW_SKILLS_ROOT}"
  echo ""

  for name in "${SKILL_NAMES[@]}"; do
    rm -rf "${OPENCLAW_SKILLS_ROOT}/${name}"
    cp -R "${SKILLS_SRC}/${name}" "${OPENCLAW_SKILLS_ROOT}/${name}"
    echo "  ✓ ${name}"
  done

  echo ""
}

configure_openclaw() {
  echo "─── OpenClaw configuration ───"
  echo ""
  echo "Need an Account? https://www.revelata.com/signup?product_id=0"
  echo "Have an Account? Retrieve your API key here: https://www.revelata.com/ai-credits"
  echo ""
  read -r -p "Paste your deepKPI API key (dk_...): " DEEPKPI_API_KEY </dev/tty
  if [[ -z "${DEEPKPI_API_KEY}" ]]; then
    echo "No API key provided, aborting."
    exit 1
  fi

  mkdir -p "$(dirname "${CONFIG_FILE}")"

  if [[ ! -f "${CONFIG_FILE}" ]]; then
    cat > "${CONFIG_FILE}" <<CFGEOF
{
  "skills": {
    "entries": {
      "deepkpi-api": {
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
import json, os, pathlib

cfg_path = pathlib.Path("${CONFIG_FILE}")
data = json.loads(cfg_path.read_text())

skills = data.setdefault("skills", {})
entries = skills.setdefault("entries", {})
api_entry = entries.setdefault("deepkpi-api", {})
api_entry["enabled"] = True
env = api_entry.setdefault("env", {})
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
  echo "Where will you use these skills?"
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
    ensure_skills_dir "${CLAUDE_SKILL_NAMES[@]}"
    OUT="$(default_zip_out_dir)"
    zip_skills_to "$OUT" "${CLAUDE_SKILL_NAMES[@]}"
    echo ""
    echo "Next steps (Claude Desktop):"
    echo "  1. Open Claude Desktop and sign in."
    echo '  2. Settings → Capabilities → enable "Code execution and file creation".'
    echo "  3. Customize → Skills → + → Upload a skill."
    echo "  4. Upload each ZIP from:"
    echo "       ${OUT}/"
    echo "  5. Enable each skill with its toggle."
    echo ""
    echo "Packaging rules: https://support.claude.com/en/articles/12512198-creating-custom-skills"
    ;;

  claude-web)
    ensure_skills_dir "${CLAUDE_SKILL_NAMES[@]}"
    OUT="$(default_zip_out_dir)"
    zip_skills_to "$OUT" "${CLAUDE_SKILL_NAMES[@]}"
    echo ""
    echo "Next steps (Claude.ai):"
    echo "  1. Sign in at https://claude.ai"
    echo '  2. Settings → Capabilities → enable "Code execution and file creation".'
    echo "  3. Open Customize → Skills: https://claude.ai/customize/skills"
    echo "  4. Click + → Upload a skill, and upload each ZIP from:"
    echo "       ${OUT}/"
    echo "  5. Enable each skill with its toggle."
    echo ""
    echo "Help: https://support.claude.com/en/articles/12512180-using-skills-in-claude"
    ;;

  openclaw)
    echo ""
    echo "deepkpi-agents — OpenClaw installer"
    echo ""
    install_openclaw_skills
    configure_openclaw
    echo ""
    echo "Installed skills:"
    for name in "${SKILL_NAMES[@]}"; do
      echo "  • ${name}"
    done
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
