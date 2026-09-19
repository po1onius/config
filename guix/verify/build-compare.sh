#!/usr/bin/env bash
# Compare two evaluations of the same operating-system config:
#
#   1. baseline - the pre-change config with the ESP and root UUIDs spelled out
#                 as (uuid "…") literals (taken from git history);
#   2. current  - the config as it is now, whose (uuid-by-label …) calls look
#                 the BOOT/ROOT labels up on disk at evaluation time.
#
# Both are pointed at tiny ext4/FAT images carrying *this machine's* UUIDs.  If
# the two evaluations yield the same system derivation, the labels resolve to
# exactly the UUIDs that used to be hard-coded.
#
# Usage (the script must live in the repo it checks):
#   bash ~/config/guix/verify/build-compare.sh [work-dir]
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="${1:-${TMPDIR:-/tmp}/guix-uuid-verify}"

root_uuid="8644af7e-f898-439f-87a6-5590b990c1b5"   # this machine's root ext4
boot_uuid="9074-DBF7"                              # this machine's ESP FAT

export PATH="/run/current-system/profile/bin:/run/current-system/profile/sbin:$PATH"
mkdir -p "$work"
cd "$work"

echo "== 测试镜像（标签 ROOT / BOOT，UUID 用本机真实值）=="
[ -f root.img ] || { truncate -s 32M root.img
                     mke2fs -q -t ext4 -U "$root_uuid" -L ROOT -F root.img; }
[ -f boot.img ] || { truncate -s 8M boot.img
                     mkfs.fat -F 32 -i "${boot_uuid/-/}" -n BOOT boot.img; }
blkid -s LABEL -s UUID -o value root.img
blkid -s LABEL -s UUID -o value boot.img

echo
echo "== baseline：改写前那份写死 UUID 的配置（从 git 历史取）=="
base=""
for c in $(git -C "$repo" log --format=%H -20); do
  if git -C "$repo" show "$c:guix/system.scm" | grep -q 'uuid "8644af7e'; then
    base="$c"; break
  fi
done
if [ -z "$base" ]; then
  echo "在最近 20 个提交里找不到写死 UUID 的 guix/system.scm" >&2
  exit 1
fi
git -C "$repo" show "$base:guix/system.scm" > baseline.scm
grep -n 'uuid "' baseline.scm | head

echo
echo "== current：现在的配置，把两个文件系统重定向到镜像 =="
guile --no-auto-compile "$here/redirect-to-images.scm" \
      "$repo/guix/system.scm" "$work/root.img" "$work/boot.img" > current-img.scm
grep -n "uuid-by-label" current-img.scm | head

echo
echo "== 分别求值 =="
a="$(guix system build --no-grafts --dry-run --derivation current-img.scm 2>/dev/null | tail -1)"
b="$(guix system build --no-grafts --dry-run --derivation baseline.scm 2>/dev/null | tail -1)"
echo "current : $a"
echo "baseline: $b"

if [ -n "$a" ] && [ "$a" = "$b" ]; then
  echo
  echo "OK: 两条配置算出同一个 system derivation —— 标签解析出的 UUID 和原来写死的一致"
else
  echo
  echo "MISMATCH 或求值失败" >&2
  exit 1
fi
