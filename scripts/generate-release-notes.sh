#!/usr/bin/env bash

set -euo pipefail

RELEASE_TAG="${1:?Usage: generate-release-notes.sh <tag> <output-path>}"
OUTPUT_PATH="${2:?Usage: generate-release-notes.sh <tag> <output-path>}"
REPOSITORY="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
CUSTOM_NOTES_PATH=".github/release-notes/${RELEASE_TAG}.md"

generated_notes="$(
    gh api \
        --method POST \
        "repos/${REPOSITORY}/releases/generate-notes" \
        --raw-field "tag_name=${RELEASE_TAG}" \
        --jq '.body'
)"

formatted_notes="$(
    printf '%s\n' "$generated_notes" \
        | sed \
            -e 's|^## What'\''s Changed$|## 更新内容 / What'\''s Changed|' \
            -e 's|^## New Contributors$|## 新贡献者 / New Contributors|' \
            -e 's|^\*\*Full Changelog\*\*|**完整变更 / Full Changelog**|' \
            -e 's|^\* feat:|\* 新功能 / Feature:|' \
            -e 's|^\* fix:|\* 问题修复 / Fix:|' \
            -e 's|^\* perf:|\* 性能优化 / Performance:|' \
            -e 's|^\* docs:|\* 文档 / Documentation:|' \
            -e 's|^\* chore:|\* 维护 / Maintenance:|'
)"

{
    printf '# Bye.DS_Store %s\n\n' "$RELEASE_TAG"
    printf '> 本更新说明由工作流自动生成，每项变更会标注对应贡献者。\n'
    printf '> These release notes are generated automatically, with contributors credited on each change.\n\n'

    if [[ -f "$CUSTOM_NOTES_PATH" ]]; then
        printf '## 版本亮点 / Highlights\n\n'
        sed '1{/^# /d;}' "$CUSTOM_NOTES_PATH"
        printf '\n\n'
    fi

    printf '%s\n' "$formatted_notes"
} > "$OUTPUT_PATH"

printf 'Generated bilingual release notes at %s\n' "$OUTPUT_PATH"
