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
=== System Info (uname) ===  
sysname:  Linux  
hostname: kali  
release:  6.x.x  
version:  #1 SMP  
machine:  x86_64  

## Build and Run
```
nasm -f elf sysinfo.asm
nasm -f elf functions.asm
ld -m elf_i386 sysinfo.o -o sysinfo
./sysinfo
```

## Brief Techincal Notes

This program demonstrates several core assembly language concepts, including system calls, memory layout, register usage, and modular code reuse. The primary operation is the ```uname``` system call, which is invoked using interrupt ```int 0x80``` with syscall number 122 on 32-bit Linux systems. The kernel fills a ```struct utsname``` structure in memory, which contains multiple null-terminated strings placed at fixed offsets.   

To store this data, the program allocates a buffer in the ```.bss``` section large enough to hold all expected fields. Each field is accessed using calculated offsets, allowing individual values such as the hostname or kernel version to be printed separately. This reinforced my understanding of how structured data is handled manually at the assembly level.  

The program uses helper functions from ```functions.asm```, such as ```sprintLF``` and ```quit```, to keep the main logic readable and focused. The modular approach makes the code easier to follow and reduce duplication. One challenge I encountered was understanding how string printing works without standard libraries, which required explicitly calculating string lengths and managing registers carefully.  

Additional system details such as CPU and network configuration could be retrieved using file reads from ```/proc```, but I intentionally limited this program to ```uname``` to keep the focus on direct kernel interaction. Overall, the program interacts directly with kernel resources without abstraction, which helped clarify how user programs communicate with the operating system at the lowest level.  


