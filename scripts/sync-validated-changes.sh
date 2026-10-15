#!/usr/bin/env bash
#
# Downloads the latest CI-validated changes from the remote repository.
#
# Usage:
#   ./scripts/sync-validated-changes.sh [branch]
#
# Defaults to "main". The branch must have passed the `dotnet-ci.yml` workflow.

set -euo pipefail

BRANCH="${1:-main}"

echo "==> Fetching latest refs from origin (prune deleted branches)..."
git fetch --all --prune

echo "==> Switching to '${BRANCH}'..."
git checkout "${BRANCH}"

echo "==> Fast-forward pulling the validated commits..."
git pull --ff-only origin "${BRANCH}"

echo ""
echo "Done. You are on '${BRANCH}' at commit: $(git rev-parse --short HEAD)"
echo "Artifacts from the last green CI run are available under the GitHub Actions run page."
