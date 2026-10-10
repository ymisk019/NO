#!/usr/bin/env python3
"""
Yazan Game OS - ISO builder.

Builds the real kernel with the Makefile, then packs it into a bootable
ISO 9660 image with GRUB (grub-mkrescue). The ISO contains the real
Multiboot kernel, not a placeholder. Any failure stops the build.

Usage: python3 tools/build_iso.py [output.iso]
"""

import os
import shutil
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ISO_DIR = os.path.join(ROOT, "isodir")
GRUB_CFG = """set timeout=0
set default=0

menuentry "Yazan Game OS" {
    multiboot /boot/kernel.bin
    boot
}
"""


def run(cmd):
    print("[*] " + " ".join(cmd))
    subprocess.run(cmd, cwd=ROOT, check=True)


def main():
    out_iso = sys.argv[1] if len(sys.argv) > 1 else "yazan-game-os.iso"
    out_iso = os.path.abspath(out_iso)

    # 1. Build the real kernel (fails the script if compilation fails)
    run(["make", "kernel.bin"])

    # 2. Confirm the kernel really has a Multiboot header
    run(["grub-file", "--is-x86-multiboot", "kernel.bin"])

    # 3. Lay out the ISO tree
    if os.path.isdir(ISO_DIR):
        shutil.rmtree(ISO_DIR)
    os.makedirs(os.path.join(ISO_DIR, "boot", "grub"))
    shutil.copy(os.path.join(ROOT, "kernel.bin"), os.path.join(ISO_DIR, "boot", "kernel.bin"))
    with open(os.path.join(ISO_DIR, "boot", "grub", "grub.cfg"), "w", encoding="ascii") as f:
        f.write(GRUB_CFG)

    # 4. Create the bootable ISO with GRUB (El Torito + hybrid MBR)
    if os.path.exists(out_iso):
        os.remove(out_iso)
    run(["grub-mkrescue", "-o", out_iso, ISO_DIR])

    size = os.path.getsize(out_iso)
    print(f"[+] Bootable ISO created: {out_iso} ({size / (1024 * 1024):.2f} MB)")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as e:
        print(f"[!] Build step failed with exit code {e.returncode}", file=sys.stderr)
        sys.exit(e.returncode)
