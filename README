# sanzOS

A minimal x86 operating system built from scratch in real mode (16-bit), written entirely in NASM assembly with no reliance on standard C libraries. This project focuses on low-level system bring-up: booting from a virtual floppy disk, reading sectors directly off the disk via BIOS interrupts, and loading a kernel into memory — the same fundamental steps every x86 OS performs before any high-level code runs.

## What it does

1. The BIOS loads the first 512-byte sector (the bootloader) into memory at `0x7C00` and jumps to it.
2. The bootloader initializes the segment registers and stack, then reads the kernel from disk using a custom LBA→CHS (Logical Block Addressing to Cylinder-Head-Sector) translation routine, since the BIOS disk interrupt (`int 13h`) expects CHS addressing.
3. Disk reads include retry logic (up to 3 attempts) and a disk-controller reset routine, with a dedicated error handler if all retries fail.
4. Once loaded, the kernel prints a message to the screen via BIOS video interrupts (`int 10h`) and halts the CPU.
5. The disk image itself is formatted as FAT12, matching the boot sector's embedded BIOS Parameter Block (BPB) — the same low-level format used by real MS-DOS floppy disks.

## Why it's built this way

- **No standard library, no OS underneath**: every routine (string printing, disk I/O, address translation) is written directly against BIOS interrupts and raw memory addresses. There is no runtime to fall back on.
- **Real mode addressing**: the CPU starts in 16-bit real mode, so the code works directly with segment:offset addressing and the constraints that come with it (640KB conventional memory, no protected-mode features).
- **FAT12 compliance**: the boot sector's header follows the exact BPB layout required for the image to be mountable and readable as a standard FAT12 floppy, not just a raw binary blob.

## Build & run

Requires `nasm`, `qemu-system-x86_64` (or `bochs`), and the `mtools` package (for `mkfs.fat` / `mcopy`). A `shell.nix` is included for a reproducible Nix development environment.

```bash
make floppy_image   # builds bootloader.bin, kernel.bin, and assembles the FAT12 floppy image
make run             # boots the image in QEMU
make debug           # boots the image in Bochs with the debugger UI (see bochsrc)
```

## Debugging approach

The project is set up to run under **Bochs** (`bochsrc` config included) in addition to QEMU. Bochs is used specifically for its instruction-level debugger — register inspection, memory dumps, and step-by-step execution — which QEMU's default setup doesn't expose as directly. This was essential for verifying the LBA→CHS conversion math and confirming the BPB fields were being read correctly by the BIOS.

## Project structure

```
src/
  bootloader/
    boot.asm     # Stage 1: BIOS-loaded boot sector, disk read, kernel handoff
  kernel/
    main.asm     # Minimal kernel entry point
Makefile          # Build, run (QEMU), and debug (Bochs) targets
bochsrc           # Bochs emulator configuration
shell.nix         # Reproducible Nix dev environment
```

## Status & next steps

This is an active, incremental project. Current state: working bootloader with reliable FAT12 disk reads and kernel handoff. Planned next milestones:

- Basic memory manager
- Transition from 16-bit real mode to 32-bit protected mode
- Applying the same bare-metal, register-level approach to ARM Cortex-M (STM32) as a parallel embedded-systems track

## Background

Built independently, outside of coursework, as a way to understand the hardware/software boundary from the very first instruction the CPU executes — before any operating system, driver, or abstraction exists.