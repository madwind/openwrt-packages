# OpenWrt Packages

Signed APK repository for packages maintained by `madwind` on OpenWrt 25.12.

## Packages

- `luci-app-nftflow`
- `luci-app-wloc`

Runtime dependencies such as `xray-core` are not mirrored here. They remain managed by the official OpenWrt repositories.

## Supported architectures

- `x86_64`: `luci-app-nftflow`
- `aarch64_generic`: `luci-app-nftflow` and `luci-app-wloc`

`luci-app-nftflow` is architecture-independent. `luci-app-wloc` is currently published only for `aarch64_generic`.

## Add the repository

After the first repository publish succeeds:

```sh
wget -O- https://raw.githubusercontent.com/madwind/openwrt-packages/main/install.sh | sh
```

Then install the packages available for your architecture:

```sh
apk add luci-app-nftflow
```

On `aarch64_generic`, WLOC is also available:

```sh
apk add luci-app-wloc
```

To refresh package metadata and upgrade installed packages, use `apk update` followed by `apk add --upgrade <package>`.

The installer adds the repository public key to `/etc/apk/keys/` and adds the architecture-specific `packages.adb` URL to `/etc/apk/repositories.d/customfeeds.list`.

## Repository layout

The generated `repo` branch is the package repository:

```text
keys/
  madwind.pem
25.12/
  x86_64/
    packages.adb
    luci-app-nftflow-*.apk
  aarch64_generic/
    packages.adb
    luci-app-nftflow-*.apk
    luci-app-wloc-*-aarch64_generic.apk
```

The publish workflow downloads the latest stable GitHub Release APKs from `madwind/luci-app-nftflow` and `madwind/luci-app-wloc`, builds signed APK v3 indexes, and replaces the generated `repo` branch only when its contents change.

## Signing setup

Generate one persistent NIST P-256 private key locally:

```sh
umask 077
openssl ecparam -name prime256v1 -genkey -noout -out madwind-apk.pem
```

Add the complete contents of `madwind-apk.pem` as the repository Actions secret `APK_SIGNING_KEY`.

Keep that private key backed up securely. Do not commit it. The workflow derives and publishes only the corresponding public key.

After adding the secret, run **Actions → Publish APK repository → Run workflow** once. The workflow also checks for new releases every six hours.
