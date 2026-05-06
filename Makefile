# Config
FOLDER = revelata-deepkpi
ZIP_NAME = deepkpi-skills.zip
REPO_URL = https://github.com/revelata/deepkpi-agents
GITHUB_API = https://api.github.com
GITHUB_UPLOADS = https://uploads.github.com
PLUGIN_JSON = .claude-plugin/plugin.json

# install.sh is the single source of truth for the bundle build. We invoke it
# with DEEPKPI_ZIP_OUT_DIR to redirect the ZIP into ./dist, then rename to
# $(ZIP_NAME) (preserves the historic releases/latest/download URL that
# install.sh's curl-fallback uses).

# Derive owner/repo (e.g. revelata/deepkpi-agents) from REPO_URL.
# Note: sed uses '|' as delimiter because '#' starts a comment in GNU Make.
REPO_OWNER_REPO := $(shell echo "$(REPO_URL)" | sed -E 's|^https?://github\.com/||; s|\.git$$||; s|/+$$||')

# Auto-detect the local git remote that points at the PUBLIC repo (REPO_URL).
# - Internal devs cloning the private fork: usually `upstream`.
# - External devs cloning the public repo:  usually `origin`.
# Override with `make release RELEASE_REMOTE=<name>` if needed.
ifndef RELEASE_REMOTE
RELEASE_REMOTE := $(shell \
  for r in `git remote 2>/dev/null`; do \
    u=`git remote get-url $$r 2>/dev/null | sed -E 's|^https?://github\.com/||; s|^git@github\.com:||; s|\.git$$||; s|/+$$||'`; \
    if [ "$$u" = "$(REPO_OWNER_REPO)" ]; then echo "$$r"; break; fi; \
  done)
endif

# Branch we release from. Override with `make release RELEASE_BRANCH=<name>`.
RELEASE_BRANCH ?= main

# Optional explicit version: `make release VERSION=v1.0.16`.
# If unset, autobump the patch number from the latest local tag.
VERSION ?=

# Set ALLOW_VERSION_MISMATCH=1 to proceed when the tag version differs from
# the version declared in $(PLUGIN_JSON). Default behavior is to abort.
ALLOW_VERSION_MISMATCH ?= 0

.PHONY: package release clean

package:
	@echo "Packaging $(FOLDER)..."
	@rm -rf dist
	@mkdir -p dist
	@DEEPKPI_ZIP_OUT_DIR="$(CURDIR)/dist" ./install.sh claude-desktop >/dev/null
	@mv "dist/$(FOLDER).zip" "$(ZIP_NAME)"
	@echo "Wrote $(ZIP_NAME)"

# Preflight + package + tag + push + GitHub Release.
# Pushes the tag to RELEASE_REMOTE (the remote that points at REPO_URL).
release:
	@set -e; \
	echo "=== Preflight ==="; \
	current_branch="$$(git symbolic-ref --short HEAD 2>/dev/null || echo "")"; \
	if [ "$$current_branch" != "$(RELEASE_BRANCH)" ]; then \
		echo "Error: must be on '$(RELEASE_BRANCH)' to release. Currently on: $${current_branch:-<detached HEAD>}"; \
		echo "Switch with 'git checkout $(RELEASE_BRANCH)', or override with RELEASE_BRANCH=<name>."; \
		exit 1; \
	fi; \
	if [ -z "$(RELEASE_REMOTE)" ]; then \
		echo "Error: no git remote points at $(REPO_URL)."; \
		echo "Add an 'upstream' (private-fork devs) or use a clone of the public repo,"; \
		echo "or set RELEASE_REMOTE=<name> explicitly."; \
		exit 1; \
	fi; \
	token="$${GITHUB_TOKEN:-$${GH_TOKEN:-}}"; \
	if [ -z "$$token" ]; then \
		echo "Error: GITHUB_TOKEN (or GH_TOKEN) is required to create a GitHub Release."; \
		echo "Set one of those env vars to a token with 'repo' scope, then re-run."; \
		exit 1; \
	fi; \
	if [ -n "$(VERSION)" ]; then \
		next="$(VERSION)"; \
		case "$$next" in v*) ;; *) next="v$$next" ;; esac; \
		if git rev-parse -q --verify "refs/tags/$$next" >/dev/null; then \
			echo "Error: tag $$next already exists locally. Delete it or pick a different VERSION."; \
			exit 1; \
		fi; \
		if git ls-remote --tags --exit-code $(RELEASE_REMOTE) "refs/tags/$$next" >/dev/null 2>&1; then \
			echo "Error: tag $$next already exists on $(RELEASE_REMOTE). Pick a different VERSION."; \
			exit 1; \
		fi; \
		echo "Using supplied version: $$next"; \
	else \
		latest="$$(git describe --tags --abbrev=0 2>/dev/null || echo v0.0.0)"; \
		next="$$(echo "$$latest" | awk -F. '{print $$1 "." $$2 "." $$3+1}')"; \
		while git rev-parse -q --verify "refs/tags/$$next" >/dev/null; do \
			next="$$(echo "$$next" | awk -F. '{print $$1 "." $$2 "." $$3+1}')"; \
		done; \
		echo "Bumping version: $$latest -> $$next"; \
	fi; \
	tag_version="$${next#v}"; \
	plugin_version="$$(python3 -c 'import json; print(json.load(open("$(PLUGIN_JSON)"))["version"])' 2>/dev/null || echo "")"; \
	if [ -z "$$plugin_version" ]; then \
		echo "Warning: could not read version from $(PLUGIN_JSON); skipping mismatch check."; \
	elif [ "$$plugin_version" != "$$tag_version" ]; then \
		echo "Warning: $(PLUGIN_JSON) version ($$plugin_version) != tag version ($$tag_version)."; \
		if [ "$(ALLOW_VERSION_MISMATCH)" != "1" ]; then \
			echo "Aborting. Either:"; \
			echo "  - update $(PLUGIN_JSON) version to $$tag_version, commit, and re-run, or"; \
			echo "  - re-run with ALLOW_VERSION_MISMATCH=1 to proceed anyway."; \
			exit 1; \
		fi; \
		echo "ALLOW_VERSION_MISMATCH=1 set; proceeding despite mismatch."; \
	else \
		echo "Version check OK: $(PLUGIN_JSON) version matches tag ($$tag_version)."; \
	fi; \
	echo "Releasing $$next via remote '$(RELEASE_REMOTE)' -> $(REPO_OWNER_REPO)"; \
	echo ""; \
	echo "=== Building package ==="; \
	$(MAKE) package; \
	echo ""; \
	echo "=== Tagging and pushing ==="; \
	git tag -a "$$next" -m "Release $$next"; \
	git push $(RELEASE_REMOTE) "$$next"; \
	echo ""; \
	echo "=== Creating GitHub release ==="; \
	echo "Creating GitHub release $$next for $(REPO_OWNER_REPO)..."; \
	release_json="$$(curl -fsSL -X POST \
		-H "Authorization: Bearer $$token" \
		-H "Accept: application/vnd.github+json" \
		"$(GITHUB_API)/repos/$(REPO_OWNER_REPO)/releases" \
		-d "$$(printf '{"tag_name":"%s","name":"Release %s","body":"Automated update of DeepKPI agent skills.","draft":false,"prerelease":false}' "$$next" "$$next")" \
	)"; \
	upload_path="$$(echo "$$release_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["upload_url"].split("{")[0])')"; \
	echo "Uploading $(ZIP_NAME)..."; \
	curl -fsSL -X POST \
		-H "Authorization: Bearer $$token" \
		-H "Accept: application/vnd.github+json" \
		-H "Content-Type: application/zip" \
		"$$upload_path?name=$(ZIP_NAME)" \
		--data-binary "@$(ZIP_NAME)" >/dev/null; \
	echo "--------------------------------------------------"; \
	echo "Done!"; \
	echo "Tag pushed: $$next -> $(RELEASE_REMOTE) ($(REPO_OWNER_REPO))"; \
	echo "Asset built: $(ZIP_NAME)"; \
	echo "Stable download link:"; \
	echo "$(REPO_URL)/releases/latest/download/$(ZIP_NAME)"; \
	echo "Optional GitHub release page:"; \
	echo "$(REPO_URL)/releases/tag/$$next"

clean:
	@rm -rf dist
	@rm -f $(ZIP_NAME)