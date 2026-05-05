# Config
FOLDER = revelata-deepkpi
ZIP_NAME = deepkpi-skills.zip
REPO_URL = https://github.com/revelata/deepkpi-agents
GITHUB_API = https://api.github.com
GITHUB_UPLOADS = https://uploads.github.com

# install.sh is the single source of truth for the bundle build. We invoke it
# with DEEPKPI_ZIP_OUT_DIR to redirect the ZIP into ./dist, then rename to
# $(ZIP_NAME) (preserves the historic releases/latest/download URL that
# install.sh's curl-fallback uses).

.PHONY: package release clean

package:
	@echo "Packaging $(FOLDER)..."
	@rm -rf dist
	@mkdir -p dist
	@DEEPKPI_ZIP_OUT_DIR="$(CURDIR)/dist" ./install.sh claude-desktop >/dev/null
	@mv "dist/$(FOLDER).zip" "$(ZIP_NAME)"
	@echo "Wrote $(ZIP_NAME)"

# Tag + push + package (GitHub Release can be created manually from the tag)
release: package
	@set -e; \
	token="$${GITHUB_TOKEN:-$${GH_TOKEN:-}}"; \
	if [ -z "$$token" ]; then \
		echo "Error: GITHUB_TOKEN (or GH_TOKEN) is required to create a GitHub Release."; \
		echo "Set one of those env vars to a token with 'repo' scope, then re-run."; \
		exit 1; \
	fi; \
	latest="$$(git describe --tags --abbrev=0 2>/dev/null || echo v0.0.0)"; \
	next="$$(echo "$$latest" | awk -F. '{print $$1 "." $$2 "." $$3+1}')"; \
	while git rev-parse -q --verify "refs/tags/$$next" >/dev/null; do \
		next="$$(echo "$$next" | awk -F. '{print $$1 "." $$2 "." $$3+1}')"; \
	done; \
	echo "Bumping version: $$latest -> $$next"; \
	git tag -a "$$next" -m "Release $$next"; \
	git push origin "$$next"; \
	owner_repo="$$(echo "$(REPO_URL)" | sed -E 's#^https?://github.com/##' | sed -E 's#/*$$##')"; \
	echo "Creating GitHub release $$next for $$owner_repo..."; \
	release_json="$$(curl -fsSL -X POST \
		-H "Authorization: Bearer $$token" \
		-H "Accept: application/vnd.github+json" \
		"$(GITHUB_API)/repos/$$owner_repo/releases" \
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
	echo "Tag pushed: $$next"; \
	echo "Asset built: $(ZIP_NAME)"; \
	echo "Stable download link:"; \
	echo "$(REPO_URL)/releases/latest/download/$(ZIP_NAME)"; \
	echo "Optional GitHub release page:"; \
	echo "$(REPO_URL)/releases/tag/$$next"

clean:
	@rm -rf dist
	@rm -f $(ZIP_NAME)