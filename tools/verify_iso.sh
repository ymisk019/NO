#!/usr/bin/env bash
# Verifies that the ISO is a real bootable image containing a Multiboot kernel.
set -euo pipefail
ISO="${1:?usage: verify_iso.sh <file.iso>}"

echo "[*] Checking ISO 9660 + El Torito boot record..."
xorriso -indev "$ISO" -report_el_torito plain 2>&1 | tee /tmp/eltorito.txt
grep -qi "El Torito" /tmp/eltorito.txt || { echo "[!] No El Torito boot record"; exit 1; }

echo "[*] Extracting kernel from ISO and checking Multiboot header..."
rm -rf /tmp/isocheck && mkdir /tmp/isocheck
xorriso -osirrox on -indev "$ISO" -extract /boot/kernel.bin /tmp/isocheck/kernel.bin >/dev/null 2>&1
test -s /tmp/isocheck/kernel.bin || { echo "[!] /boot/kernel.bin missing from ISO"; exit 1; }
grub-file --is-x86-multiboot /tmp/isocheck/kernel.bin || { echo "[!] Kernel is not Multiboot"; exit 1; }

echo "[+] ISO verification passed."
