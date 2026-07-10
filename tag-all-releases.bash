#!/usr/bin/env bash

set -euo pipefail

git log --reverse --grep="import sqlite release" --format="%H %s" | while read -r COMMIT_HASH COMMIT_TITLE; do

    VERSION="${COMMIT_TITLE##* }"
    TAG_NAME="v${VERSION}"

    if [[ ! "${VERSION}" =~ ^[0-9] ]]; then
        echo "❌ Version '${VERSION}' is not valid. Skipping."
        continue
    fi

    if git rev-parse "${TAG_NAME}" >/dev/null 2>&1; then
        echo "⚠️ Tag ${TAG_NAME} already exists. Skipping."
        continue
    fi

    git tag "${TAG_NAME}" "${COMMIT_HASH}" -m "SQLite Release ${VERSION}" &&
    echo "✅ Tag ${TAG_NAME} successfully created!"

done
