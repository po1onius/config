#!/usr/bin/env bash
# Compare two evaluations of the very same operating-system config:
#
#   1. baseline   - the pre-change config, with the ESP and root UUIDs spelled
#                   out as (uuid "…") literals (taken from git history);
#   2. autodetect - the current config, whose (detect-uuid …) calls read the
#                   real superblocks at evaluation time.
#
# Both are pointed at tiny ext4/FAT images carrying *this machine's* UUIDs
# (image files stand in for the block devices, which only root can read).
# If the two evaluations produce the same system derivation, the detected
# UUIDs are exactly the ones that used to be hard-coded.
#
# Usage, from anywhere (the script must live in the repo it checks):
#   bash ~/config/guix/verify/build-compare.sh [work-dir]
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="${1:-${TMPDIR:-/tmp}/guix-uuid-verify}"

root_uuid="8644af7e-f898-439f-87a6-5590b990c1b5"   # this machine's root ext4
esp_uuid="9074-DBF7"                               # this machine's ESP FAT

mkdir -p "$work"
cd "$work"

echo "== test images with this machine's UUIDs =="
if [ ! -f root.img ]; then
  truncate -s 32M root.img
  mke2fs -q -t ext4 -U "$root_uuid" -L GUIX_ROOT -F root.img
fi
if [ ! -f esp.img ]; then
  truncate -s 8M esp.img
  mkfs.fat -F 32 -i "${esp_uuid/-/}" -n GUIX_ESP esp.img
fi
blkid -s UUID -s LABEL -o value root.img
blkid -s UUID -s LABEL -o value esp.img

echo
echo "== baseline config (hard-coded UUIDs, from git history) =="
# The commit that introduced detect-uuid is the first one whose parent still
# has the literal UUIDs; take its parent explicitly.
base_commit="$(git -C "$repo" log --format=%H --reverse \
                --grep='detect file system UUIDs' | head -1)"
base_commit="${base_commit:-$(git -C "$repo" rev-parse HEAD)}"
git -C "$repo" show "${base_commit}~1:guix/system.scm" > baseline.scm
grep -n 'uuid "' baseline.scm | head

echo
echo "== autodetect config, pointed at the images =="
guile --no-auto-compile -c "
(use-modules (ice-9 pretty-print))
(define (read-all port)
  (let loop ((forms '()))
    (let ((form (read port)))
      (if (eof-object? form) (reverse forms) (loop (cons form forms))))))
(define (image-detect fs)
  (let* ((point (cadr (assq 'mount-point (cdr fs))))
         (img (cond ((equal? point \"/\") \"$work/root.img\")
                    ((equal? point \"/boot/efi\") \"$work/esp.img\")
                    (else #f)))
         (type (if (equal? point \"/\") 'ext4 'fat32)))
    (if img
        (map (lambda (f)
               (if (and (pair? f) (eq? (car f) 'device))
                   (list 'device (list 'detect-uuid (list 'quote type) #:device img))
                   f))
             fs)
        fs)))
(define (rewrite x)
  (cond ((and (list? x) (pair? x) (eq? (car x) 'file-system)) (image-detect x))
        ((list? x) (map rewrite x))
        (else x)))
(for-each (lambda (f) (pretty-print (rewrite f)) (newline))
          (read-all (open-input-file \"$repo/guix/system.scm\")))
" > autodetect.scm
grep -n "detect-uuid '" autodetect.scm

echo
echo "== evaluating both =="
a="$(guix system build --no-grafts --dry-run --derivation autodetect.scm 2>/dev/null | tail -1)"
b="$(guix system build --no-grafts --dry-run --derivation baseline.scm 2>/dev/null | tail -1)"
echo "autodetect: $a"
echo "baseline  : $b"

if [ "$a" = "$b" ]; then
  echo
  echo "OK: identical system derivation - detected UUIDs == hard-coded UUIDs"
else
  echo
  echo "MISMATCH: the evaluations differ" >&2
  exit 1
fi
