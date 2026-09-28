#!/bin/bash
# Several checks deliberately pass single-quoted scripts to an inner bash.
# shellcheck disable=SC2016
#
# Smoke tests for the kjake/base image. Run inside a container built from it:
#
#   docker run --rm -v "$PWD/tests:/tests:ro" kjake/base bash /tests/smoke.sh
#
# Set SMOKE_OFFLINE=1 to skip the checks that need to reach the Debian mirrors.

set -o nounset -o pipefail

failures=0

pass() { printf 'ok   - %s\n' "$1"; }
fail() { printf 'FAIL - %s\n' "$1"; failures=$((failures + 1)); }

# check "description" command [args...]
check() {
  local desc=$1
  shift
  if "$@" >/tmp/smoke.out 2>&1; then
    pass "$desc"
  else
    fail "$desc"
    sed 's/^/       /' /tmp/smoke.out
  fi
}

SOURCES=/etc/apt/sources.list.d/debian.sources

## Apt configuration
check "deb822 source list is present" test -f "$SOURCES"
check "no legacy /etc/apt/sources.list" test ! -e /etc/apt/sources.list
check "sources use https" grep -q '^URIs: https://deb.debian.org/debian$' "$SOURCES"
check "sources track testing" grep -q '^Suites: testing testing-updates$' "$SOURCES"
check "sources include testing-security" grep -q '^Suites: testing-security$' "$SOURCES"
check "no plain http sources remain" bash -c "! grep -q 'http://' '$SOURCES'"
check "contrib and non-free components enabled" \
  bash -c "[ \"\$(grep -c '^Components: main contrib non-free non-free-firmware$' '$SOURCES')\" -eq 2 ]"
check "apt package lists were cleaned" bash -c '[ -z "$(ls -A /var/lib/apt/lists | grep -v -e ^lock$ -e ^partial$ -e ^auxfiles$)" ]'
check "build-time dpkg speedup removed" test ! -e /etc/dpkg/dpkg.cfg.d/02apt-speedup

if [ "${SMOKE_OFFLINE:-0}" != 1 ]; then
  check "apt-get update succeeds for every repository" apt-get -qq update --error-on=any
  for component in main contrib non-free non-free-firmware; do
    check "testing/$component index is available" bash -c "apt-cache policy | grep -q ' testing/$component '"
  done
  # testing-security usually carries no packages, so it publishes no indexes;
  # check that its signed release file was fetched instead.
  check "testing-security release file was fetched" \
    bash -c 'ls /var/lib/apt/lists/*debian-security_dists_testing-security_InRelease'
  rm -rf /var/lib/apt/lists/*
fi

## Installed tooling
for pkg in apt-utils ca-certificates diffutils patch locales debconf-utils vim-tiny less; do
  check "package $pkg installed" bash -c "dpkg-query -W -f='\${Status}' $pkg | grep -q 'install ok installed'"
done
check "vim points at vim.tiny" test "$(readlink /usr/bin/vim)" = /usr/bin/vim.tiny
check "ischroot is diverted to true" /usr/bin/ischroot
check "INITRD disabled for container" test "$(cat /etc/container_environment/INITRD)" = no

## Environment
check "DEBIAN_FRONTEND is noninteractive" test "${DEBIAN_FRONTEND:-}" = noninteractive
check "LC_ALL is C.UTF-8" test "${LC_ALL:-}" = C.UTF-8
check "C.UTF-8 locale is usable" bash -c 'locale 2>&1 | grep -vq "Cannot set"'

## /app layout
check "bootstrap removed itself" test ! -e /app/bin/bootstrap.sh
check "common.sh available to child images" test -r /app/lib/common.sh
check "common.sh MSG prints" bash -c '. /app/lib/common.sh; MSG hello | grep -q hello'
check "common.sh ERR prints to stderr" bash -c '. /app/lib/common.sh; ERR oops 2>&1 >/dev/null | grep -q oops'
check "common.sh CHECK_BIN accepts existing program" bash -c '. /app/lib/common.sh; CHECK_BIN bash'
check "common.sh CHECK_BIN rejects missing program" bash -c '! (. /app/lib/common.sh; CHECK_BIN no-such-program) 2>/dev/null'
check "common.sh CHECK_VAR accepts defined variable" bash -c '. /app/lib/common.sh; FOO=1; CHECK_VAR FOO'
check "common.sh CHECK_VAR rejects undefined variable" bash -c '! (. /app/lib/common.sh; CHECK_VAR NOT_DEFINED) 2>/dev/null'

## Interactive shell
check "bash.bashrc loads cleanly in an interactive shell" \
  bash -c 'out=$(bash -i -c "echo loaded; declare -p PROMPT_COMMAND" 2>&1 </dev/null); echo "$out"; [ "$(echo "$out" | grep -cv -e ^loaded -e PROMPT_COMMAND= -e "cannot set terminal process group" -e "no job control")" -eq 0 ]'

echo
if [ "$failures" -ne 0 ]; then
  echo "$failures check(s) failed"
  exit 1
fi
echo "all checks passed"
