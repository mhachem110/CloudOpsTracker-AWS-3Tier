#!/usr/bin/env bash
set -euo pipefail
case "${1:?tool name required}" in
  gitleaks)
    repository=gitleaks/gitleaks; version=8.30.1
    archive=gitleaks_8.30.1_linux_x64.tar.gz
    digest=551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb ;;
  actionlint)
    repository=rhysd/actionlint; version=1.7.12
    archive=actionlint_1.7.12_linux_amd64.tar.gz
    digest=8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8 ;;
  *) echo "Unsupported tool"; exit 1 ;;
esac
tool_dir="${RUNNER_TEMP:?}/cloudops-tools"
mkdir -p "$tool_dir"
curl --fail --silent --show-error --location \
  "https://github.com/$repository/releases/download/v$version/$archive" -o "$tool_dir/$archive"
printf '%s  %s\n' "$digest" "$tool_dir/$archive" | sha256sum --check -
tar -xzf "$tool_dir/$archive" -C "$tool_dir" "$1"
echo "$tool_dir" >> "$GITHUB_PATH"
