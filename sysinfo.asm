; sysinfo.asm
; Author: Joseph Black
; Description:
;   Prints basic system fingerprinting information using uname(2):
;   sysname, nodename (hostname), release, version, machine.
;   Uses 32-bit Linux syscall interface (int 0x80) and helper
;   string routines from functions.asm (sprintLF, quit).
;
; Assemble: nasm -f elf sysinfo.asm
; Link:     ld -m elf_i386 sysinfo.o -o sysinfo
; Run:      ./sysinfo
;
; Notes:
;   The uname syscall returns strings independent of program bitness (32 or 64).

%include "functions.asm"

SECTION .data
title_msg       db "=== System Info (uname) ===", 0
sysname_lbl     db "sysname:  ", 0
nodename_lbl    db "hostname: ", 0
release_lbl     db "release:  ", 0
version_lbl     db "version:  ", 0
machine_lbl     db "machine:  ", 0

fail_msg        db "uname() failed.", 0

SECTION .bss
; uname() writes a struct utsname into our buffer.
; Common Linux layout: each text field is 65 bytes (64 chars + null byte).
; Offsets assume 65-byte fields placed back-to-back.
; This reserves extra to be safe (390 bytes covers 6 fields of 65 bytes)
utsbuf          resb 390

SECTION .text
global _start

_start:
    ; Print a title
    mov eax, title_msg
    call sprintLF

    ; uname(utsbuf)
    ; syscall number (i386): 122
    ; EBX holds the pointer to the output buffer.
    mov eax, 122
    mov ebx, utsbuf
    int 0x80

    ; If uname fails, EAX will be negative.
    cmp eax, 0
    jl .uname_failed

    ; Offsets in struct utsname (common layout, 65-byte arrays):
    ; sysname  = utsbuf + 0
    ; nodename = utsbuf + 65
    ; release  = utsbuf + 130
    ; version  = utsbuf + 195
    ; machine  = utsbuf + 260
    ;
    ; Note on LEA:
    ;   LEA computes an address without reading memory.
    ;   Example: lea eax, [utsbuf + 65] sets EAX to the address of nodename.

    ; Print: sysname
    mov eax, sysname_lbl
    call sprintLF
    mov eax, utsbuf
    call sprintLF

    ; Print: hostname (nodename)
    mov eax, nodename_lbl
    call sprintLF
    lea eax, [utsbuf + 65]
    call sprintLF

    ; Print: release
    mov eax, release_lbl
    call sprintLF
    lea eax, [utsbuf + 130]
    call sprintLF

    ; Print: version
    mov eax, version_lbl
    call sprintLF
    lea eax, [utsbuf + 195]
    call sprintLF

    ; Print: machine
    mov eax, machine_lbl
    call sprintLF
    lea eax, [utsbuf + 260]
    call sprintLF

    call quit

.uname_failed:
    ; Keep the error path simple and consistent with the rest of the program.
    ; We print a message and exit cleanly.
    mov eax, fail_msg
    call sprintLF
    call quit
