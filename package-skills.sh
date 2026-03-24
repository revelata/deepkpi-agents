#!/usr/bin/env bash
# Package deepkpi-agents skills for Claude Desktop, Claude.ai (web), or OpenClaw.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${ROOT}/skills"
SKILL_NAMES=(
  retrieve-kpi-data
  derive-implied-metric
  format-deepkpi-for-excel
  analyze-seasonality
)

OPENCLAW_SKILLS_ROOT="${OPENCLAW_SKILLS_ROOT:-${HOME}/.openclaw/workspace/skills}"

die() { echo "Error: $*" >&2; exit 1; }

[[ -d "$SKILLS_DIR" ]] || die "missing skills directory: ${SKILLS_DIR}"

for name in "${SKILL_NAMES[@]}"; do
  [[ -f "${SKILLS_DIR}/${name}/SKILL.md" ]] || die "missing ${SKILLS_DIR}/${name}/SKILL.md"
done

default_zip_out_dir() {
  if [[ -d "${HOME}/Desktop" ]]; then
    echo "${HOME}/Desktop/deepkpi-skills"
  elif [[ -d "${HOME}/Downloads" ]]; then
    echo "${HOME}/Downloads/deepkpi-skills"
  else
    echo "${HOME}/deepkpi-skills"
  fi
}

zip_all_to() {
  local out="$1"
  mkdir -p "$out"
  echo "Writing ZIPs to: $out"
  (
    cd "$SKILLS_DIR"
    for name in "${SKILL_NAMES[@]}"; do
      rm -f "${out}/${name}.zip"
      zip -qr "${out}/${name}.zip" "$name"
      echo "  - ${name}.zip"
    done
  )
}

echo ""
echo "Where will you use these skills?"
echo "  1) Claude Desktop"
echo "  2) Claude.ai (web)"
echo "  3) OpenClaw"
echo ""
read -r -p "Enter 1, 2, or 3: " choice || true
choice="${choice:-}"

case "$choice" in
  1)
    OUT="$(default_zip_out_dir)"
    zip_all_to "$OUT"
    echo ""
    echo "Next steps (Claude Desktop):"
    echo "  1. Open Claude Desktop and sign in."
    echo "  2. Settings → Capabilities → enable “Code execution and file creation”."
    echo "  3. Customize → Skills → + → Upload a skill."
    echo "  4. Upload each ZIP from:"
    echo "       ${OUT}/"
    echo "  5. Enable each skill with its toggle."
    echo ""
    echo "Anthropic’s packaging rules: https://support.claude.com/en/articles/12512198-creating-custom-skills"
    ;;
  2)
    OUT="$(default_zip_out_dir)"
    zip_all_to "$OUT"
    echo ""
    echo "Next steps (Claude.ai):"
    echo "  1. Sign in at https://claude.ai"
    echo "  2. Settings → Capabilities → enable “Code execution and file creation”."
    echo "  3. Open Customize → Skills: https://claude.ai/customize/skills"
    echo "  4. Click + → Upload a skill, and upload each ZIP from:"
    echo "       ${OUT}/"
    echo "  5. Enable each skill with its toggle."
    echo ""
    echo "Help: https://support.claude.com/en/articles/12512180-using-skills-in-claude"
    ;;
  3)
    mkdir -p "$OPENCLAW_SKILLS_ROOT"
    echo "Installing skill directories into: ${OPENCLAW_SKILLS_ROOT}"
    for name in "${SKILL_NAMES[@]}"; do
      rm -rf "${OPENCLAW_SKILLS_ROOT}/${name}"
      cp -R "${SKILLS_DIR}/${name}" "${OPENCLAW_SKILLS_ROOT}/${name}"
      echo "  - ${name}"
    done
    echo ""
    echo "OpenClaw loads workspace skills from ~/.openclaw/workspace/skills/<name>/ (see"
    echo "https://docs.openclaw.ai/tools/creating-skills )."
    echo ""
    echo "Next steps (OpenClaw):"
    echo "  • Start a new session or run: openclaw gateway restart   (if you use the gateway)"
    echo "  • Verify: openclaw skills list"
    echo ""
    echo "These skills assume deepKPI tools or REST; set DEEPKPI_API_KEY and configure"
    echo "your connector. For the HTTP API skill (metadata.openclaw), copy Revelata’s"
    echo "OpenClaw-API-SKILL.md from vdb-query-cloud-run (mcp_server/static/) into"
    echo "  ${OPENCLAW_SKILLS_ROOT}/deepkpi/SKILL.md"
    echo "Sign up: https://www.revelata.com"
    ;;
  *)
    die "invalid choice (expected 1, 2, or 3)"
    ;;
esac

echo "Done."
