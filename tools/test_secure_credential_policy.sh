#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_root="$(mktemp -d /tmp/busymark-credential-policy.XXXXXX)"
trap 'rm -rf "$fixture_root"' EXIT
"${CXX:-c++}" -std=c++17 -Wall -Wextra -Werror \
  "$project_root/tools/secure_credential_policy_probe.cc" \
  -I"$project_root/linux/runner" -o "$fixture_root/probe"
"$fixture_root/probe"
