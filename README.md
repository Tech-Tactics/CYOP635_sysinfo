# CYOP635_sysinfo

## Overview
sysinfo.asm is a 32-bit NASM assembly program that retrieves basic system
fingerprinting information using the Linux uname system call. It displays
kernel name, hostname, release, version, and machine architecture using
direct system calls without relying on high-level libraries.

## Why This Program
This project was created for a cybersecurity course to demonstrate how
low-level assembly code can be used for system reconnaissance. Information
such as OS version, kernel release, and architecture is commonly collected
during enumeration phases of security assessments.

## Architecture
- Target architecture: x86 (32-bit)
- OS tested: Linux (x86_64 kernel)
- Assembler: NASM
- Interface: Linux int 0x80 system calls

## Files
- `sysinfo.asm` – Main program
- `functions.asm` – Helper routines for string and integer output

## Output Example
=== System Info (uname) === <br/>
sysname:  Linux <br/>
hostname: kali <br/>
release:  6.x.x <br/>
version:  #1 SMP <br/>
machine:  x86_64 <br/>

## Build and Run
```bash
nasm -f elf sysinfo.asm
nasm -f elf functions.asm
ld -m elf_i386 sysinfo.o -o sysinfo
./sysinfo


