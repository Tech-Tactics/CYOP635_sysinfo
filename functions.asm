; functions.asm
; Author: Joseph Black (adapted helper routines for CYOP 635 lab use)
; Description:
;   Minimal helper functions for 32-bit Linux NASM programs using int 0x80.
;   Provides: quit, sprint, sprintLF, iprintLF, atoi
;
; Assemble: nasm -f elf functions.asm -o functions.o

SECTION .data
newline db 0x0A

SECTION .bss
intbuf  resb  12            ; enough for -2147483648 plus null

SECTION .text
global quit
global sprint
global sprintLF
global iprintLF
global atoi

; ---------------------------------------
; quit: exit(0)
quit:
    mov eax, 1              ; sys_exit
    xor ebx, ebx            ; status = 0
    int 0x80

; ---------------------------------------
; strlen: EAX = pointer to null-terminated string
; returns: EDX = length
; clobbers: EAX, EDX
strlen:
    xor edx, edx
.len_loop:
    cmp byte [eax + edx], 0
    je .len_done
    inc edx
    jmp .len_loop
.len_done:
    ret

; ---------------------------------------
; sprint: print null-terminated string at EAX
; uses: sys_write(1, eax, len)
; preserves: none
sprint:
    push eax
    call strlen             ; EDX = length
    pop ecx                 ; ECX = string pointer
    mov ebx, 1              ; STDOUT
    mov eax, 4              ; sys_write
    int 0x80
    ret

; ---------------------------------------
; sprintLF: print string at EAX then newline
sprintLF:
    call sprint
    mov eax, 4              ; sys_write
    mov ebx, 1              ; STDOUT
    mov ecx, newline
    mov edx, 1
    int 0x80
    ret

; ---------------------------------------
; atoi: convert ASCII integer string to EAX
; input:  EAX = pointer to string (optional leading + or -)
; output: EAX = integer value
; notes:  stops at first non-digit
atoi:
    push ebx
    push ecx
    push edx
    push esi

    mov esi, eax            ; ESI = ptr
    xor eax, eax            ; result
    xor ebx, ebx            ; sign flag (0 = +, 1 = -)

    ; handle optional sign
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
    cmp cl, 0
    je .done
    cmp cl, '0'
    jb .done
    cmp cl, '9'
    ja .done

    ; eax = eax * 10 + (cl - '0')
    imul eax, eax, 10
    sub cl, '0'
    movzx edx, cl
    add eax, edx

    inc esi
    jmp .digits

.done:
    cmp bl, 1
    jne .restore
    neg eax

.restore:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; ---------------------------------------
; iprintLF: print signed integer in EAX then newline
; input: EAX = integer
iprintLF:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov edi, intbuf
    add edi, 11             ; point to end
    mov byte [edi], 0       ; null terminator
    dec edi

    mov ebx, eax            ; copy value for sign check
    cmp eax, 0
    jge .convert
    neg eax                 ; make positive for conversion

.convert:
    mov ecx, 10
.conv_loop:
    xor edx, edx
    div ecx                 ; EAX = EAX / 10, EDX = remainder
    add dl, '0'
    mov [edi], dl
    dec edi
    test eax, eax
    jnz .conv_loop

    ; add sign if original was negative
    cmp ebx, 0
    jge .print
    mov byte [edi], '-'
    dec edi

.print:
    inc edi                 ; point to first char
    mov eax, edi
    call sprintLF

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
