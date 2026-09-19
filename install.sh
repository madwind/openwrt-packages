#!/bin/sh
set -eu

REPOSITORY='madwind/openwrt-packages'
BRANCH='repo'
SERIES='25.12'
RAW_BASE="https://raw.githubusercontent.com/${REPOSITORY}/${BRANCH}"
KEY_PATH='/etc/apk/keys/madwind.pem'
FEEDS_PATH='/etc/apk/repositories.d/customfeeds.list'

fail() {
    echo "openwrt-packages: $*" >&2
    exit 1
}

[ "$(id -u)" = '0' ] || fail 'run this installer as root'
command -v apk >/dev/null 2>&1 || fail 'OpenWrt apk package manager is required'
command -v wget >/dev/null 2>&1 || fail 'wget is required'

release=''
if [ -r /etc/openwrt_release ]; then
    # shellcheck disable=SC1091
    . /etc/openwrt_release
    release="${DISTRIB_RELEASE:-}"
fi

case "$release" in
    25.12*) ;;
    *) fail "unsupported OpenWrt release: ${release:-unknown}; this repository currently targets 25.12" ;;
esac

# Use apk's configured package architecture. apk --print-arch may report only
# the generic CPU architecture (for example aarch64) on OpenWrt.
arch="$(head -n 1 /etc/apk/arch 2>/dev/null | tr -d '\r' || true)"
[ -n "$arch" ] || arch="$(apk --print-arch 2>/dev/null || true)"

case "$arch" in
    x86_64|aarch64_generic) ;;
    *) fail "unsupported package architecture: ${arch:-unknown}" ;;
esac

key_url="${RAW_BASE}/keys/madwind.pem"
feed_url="${RAW_BASE}/${SERIES}/${arch}/packages.adb"
key_tmp="/tmp/madwind-apk-key.$$"
feeds_tmp="/tmp/madwind-apk-feeds.$$"
trap 'rm -f "$key_tmp" "$feeds_tmp"' EXIT INT TERM

mkdir -p /etc/apk/keys /etc/apk/repositories.d

wget -O "$key_tmp" "$key_url" || fail "unable to download repository key from $key_url"
grep -q '^-----BEGIN PUBLIC KEY-----$' "$key_tmp" || fail 'downloaded repository key is invalid'
grep -q '^-----END PUBLIC KEY-----$' "$key_tmp" || fail 'downloaded repository key is invalid'
chmod 0644 "$key_tmp"
mv "$key_tmp" "$KEY_PATH"

if [ -f "$FEEDS_PATH" ]; then
    grep -v 'raw.githubusercontent.com/madwind/openwrt-packages/repo/' "$FEEDS_PATH" > "$feeds_tmp" || true
else
    : > "$feeds_tmp"
fi
printf '%s\n' "$feed_url" >> "$feeds_tmp"
cat "$feeds_tmp" > "$FEEDS_PATH"
rm -f "$feeds_tmp"

apk update

echo "openwrt-packages: repository configured for OpenWrt ${SERIES} / ${arch}"
if [ "$arch" = 'aarch64_generic' ]; then
    echo 'openwrt-packages: install with: apk add luci-app-nftflow luci-app-wloc'
else
    echo 'openwrt-packages: install with: apk add luci-app-nftflow'
fi
