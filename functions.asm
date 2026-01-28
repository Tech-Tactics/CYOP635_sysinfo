; functions.asm
; Author: Joseph Black (helper routines for "sysinfo" CYOP 635 lab)
; Description:
;   Minimal helper functions for 32-bit Linux NASM programs using int 0x80.
;   Provides: quit, sprint, sprintLF, iprintLF, atoi
;
; Assemble (only if linking as an object file):
;   nasm -f elf functions.asm -o functions.o
; 
; Typical use (most common in this course):
;   Place functions.asm in the same folder and include it from your program:
;     %include "functions.asm"
;   Then assemble only your main program, since NASM inserts this code directly.

SECTION .data
; A single newline byte used by sprintLF and iprintLF.
newline db 0x0A

SECTION .bss
; Temporary buffer used by iprintLF when converting an integer to text.
; 12 bytes is enough for: "-2147483648" (11 chars) plus the null terminator.
intbuf  resb  12

SECTION .text
; Exported labels (these are callable from your other .asm files)
global quit
global sprint
global sprintLF
global iprintLF
global atoi

; ------------------------------------------------------------
; quit
; Purpose: cleanly exit the program with status code 0
; Inputs:  none
; Output:  program terminates
; Notes:   Linux i386 syscall interface uses:
;          eax = syscall number, ebx = first argument
quit:
    mov eax, 1              ; sys_exit
    xor ebx, ebx            ; status = 0
    int 0x80

; ------------------------------------------------------------
; strlen (internal helper)
; Purpose: calculate length of a null-terminated string
; Inputs:  eax = address of string (must end with byte 0)
; Outputs: edx = length (number of bytes before the null)
; Clobbers: eax, edx
; Notes:   This is not exported with "global", it is local to this file.
strlen:
    xor edx, edx            ; edx will be our counter (starts at 0)
.len_loop:
    ; Check the next byte: if it is 0, we reached the end of the string.
    cmp byte [eax + edx], 0
    je .len_done
    inc edx                 ; count one more character
    jmp .len_loop
.len_done:
    ret

; ------------------------------------------------------------
; sprint
; Purpose: print a null-terminated string to STDOUT
; Inputs:  eax = address of string
; Outputs: none (writes to terminal)
; Notes:   Uses sys_write(1, string, length)
sprint:
    ; Save the string pointer, strlen will overwrite eax.
    push eax
    call strlen             ; returns edx = length
    pop ecx                 ; ecx = string pointer (sys_write arg)
    mov ebx, 1              ; STDOUT file descriptor
    mov eax, 4              ; sys_write
    int 0x80
    ret

; ------------------------------------------------------------
; sprintLF
; Purpose: print a string followed by a newline
; Inputs:  eax = address of string
; Outputs: none
sprintLF:
    call sprint
    ; Write a single newline character.
    mov eax, 4              ; sys_write
    mov ebx, 1              ; STDOUT
    mov ecx, newline
    mov edx, 1
    int 0x80
    ret

; ------------------------------------------------------------
; atoi
; Purpose: convert an ASCII integer string to a 32-bit signed integer
; Inputs:  eax = address of string (optional leading '+' or '-')
; Outputs: eax = integer value
; Notes:
;   - Stops converting at the first non-digit.
;   - Does not handle overflow detection (kept simple for this course).
atoi:
    ; Preserve registers we use so caller is not surprised.
    push ebx
    push ecx
    push edx
    push esi

    mov esi, eax            ; esi = string pointer
    xor eax, eax            ; eax = result accumulator
    xor ebx, ebx            ; ebx = sign flag (0 = positive, 1 = negative)

    ; Optional sign handling
    mov cl, [esi]
    cmp cl, '-'
    jne .check_plus
    mov bl, 1
    inc esi
    jmp .digits

.check_plus:
    cmp cl, '+'
    jne .digits
    inc esi

.digits:
    mov cl, [esi]
    cmp cl, 0               ; end of string
    je .done
    cmp cl, '0'             ; below '0' means not a digit
    jb .done
    cmp cl, '9'             ; above '9' means not a digit
    ja .done

    ; eax = eax * 10 + (digit)
    imul eax, eax, 10
    sub cl, '0'
    movzx edx, cl
    add eax, edx

    inc esi
    jmp .digits

.done:
    ; Apply sign if original string began with '-'
    cmp bl, 1
    jne .restore
    neg eax

.restore:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; ------------------------------------------------------------
; iprintLF
; Purpose: print a signed integer followed by a newline
; Inputs:  eax = integer
; Outputs: none
; How it works (high level):
;   - Convert the integer to characters in intbuf from right to left.
;   - Then print the resulting string with sprintLF.
iprintLF:
    ; Preserve registers we use so the caller is not affected.
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    ; EDI will point inside intbuf. We build the number backwards.
    mov edi, intbuf
    add edi, 11             ; last byte position in buffer
    mov byte [edi], 0       ; null terminator
    dec edi                 ; move left to start writing digits

    ; Save original value in ebx so we can detect negative numbers.
    mov ebx, eax
    cmp eax, 0
    jge .convert
    neg eax                 ; make value positive for division loop

.convert:
    mov ecx, 10             ; base 10 conversion

.conv_loop:
    xor edx, edx            ; required before div, edx:eax is the dividend
    div ecx                 ; eax = eax / 10, edx = remainder
    add dl, '0'             ; remainder becomes an ASCII digit
    mov [edi], dl
    dec edi
    test eax, eax
    jnz .conv_loop

    ; Add '-' if the original number was negative.
    cmp ebx, 0
    jge .print
    mov byte [edi], '-'
    dec edi

.print:
    inc edi                 ; point to first character of the final string
    mov eax, edi
    call sprintLF

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
