; Prints out the asked amount of pseudo-random, even numbers greater than 0.
; Seeded by CPU timer
; 
; 
; Assemble and run:
;
; nasm -f elf64 -o rand.o rand.s
; ld -o rand rand.o
; ./rand
;

bits 64

; Used in modulo operation
; values will be between 0 to (RAND_MAX - 1) 
; but we don't print out 0 
RAND_MAX equ 21

section .data
    prompt: db "How many numbers?: ",0x0
    promptlen: equ $ - prompt

    error: db "I'm sorry, I'm afraid I can't let you do that", 0xA, 0x0
    errorlen: equ $ - error

    space: db " "
    spacelen: equ $ - space

    nl: db 0xA
    nlen: equ $ - nl
    

section .bss
    ; Input and output buffers
    ; Oversized but whatever
    input: resb 64
    output: resb 64

section .text
    global _start

_start:
    push rbx

    ; Print out prompt
    mov rsi, prompt
    mov rdx, promptlen
    call write

    ; Read in input
    mov rsi, input
    mov rdx, 64
    call read

    ; Go convert it
    mov rdi, input
    call toint

    test rax, rax   ; did we get a 0?
    jz .end         ; we did, just end

    ; Loop for the asked number of times
    mov rbx, rax

    .loop:
    test rbx, rbx
    jz .end

    ; Get random number
    rdtsc
    mov edi, eax
    call rand

    test rax, 0x1   ; even number?
    jnz  .loop      ; no, loop again and get the next one

    test rax, rax   ; 0?
    jz  .loop       ; yes, loop again

    ; print it out
    mov rdi, rax
    call printnum

    mov rsi, output
    mov rdx, rax
    call write

    ; with a space after
    mov rsi, space
    mov rdx, spacelen
    call write

    ; and go again
    sub ebx, 1
    jmp .loop


    .end:
    pop rbx

    mov rsi, nl
    mov rdx, nlen
    call write

exit:
    mov rax, 60
    xor rdi, rdi
    syscall

; rdi = number to use as seed
rand:
    imul rdi, 7481      ; multiply by a prime
    lea rax, [rdi+5669] ; then add another prime
    mov esi, RAND_MAX   ; we want numbers smaller than RAND_MAX
    xor edx, edx        ; clear out edx
    idiv esi            ; rax % RAND_MAX
    mov eax, edx        ; return remainder
    ret

; rdi = pointer to string that should be converted
; rax = returned conversion
toint:
    xor ecx, ecx
    xor eax, eax

    .loop:
    ; check for NUL and newline
    cmp byte [rdi + rcx], 0
    cmp byte [rdi + rcx], 0xA
    jz .end

    ; Wasn't NUL
    imul    rax, 10                 ; multiply our rax by 10
    movzx   edx, byte [rdi + rcx]   ; get next value to rdx
    add     rcx, 1                  ; and point to the next one
    lea     rdx, [rdx - 0x30]       ; convert ASCII to value 
    lea     rax, [rax + rdx]        ; and put it in rax

    jmp .loop


.end:
    ret

    
; rdi = number to print
printnum:
    ; just zero out our temp string
    ; yes this is hacky and sucks but whatever
    mov rsi, output
    mov qword [rsi], 0

    ; Set up counter, divisor and number in rax
    xor ecx, ecx
    mov rsi, 10
    mov rax, rdi

    .div_loop:
    xor edx, edx    ; clear remainder
    idiv rsi        ; rax / 10
    add ecx, 1      ; increment counter
    push rdx        ; push remainder to stack
    test rax, rax   ; all done?
    jnz .div_loop   ; no, go again

    mov rax, output ; yes, set up rax to output buffer
    xor rsi, rsi    ; clear out rsi for counter

    .print_loop:
    test ecx, ecx   ; counted all the way?
    jz .end         ; yes, go to end

    pop rdx                 ; no, get next remainder from stack
    add rdx, '0'            ; convert to ascii value
    mov byte [rax+rsi], dl  ; store at buffer

    sub rcx, 1              ; decrement counter
    add rsi, 1              ; and increment offset
    jmp .print_loop

    .end:
    mov rax, rsi            ; return counter value if we want to use it in something
    ret


; rsi = char *buff, rdx = size_t count
read:
    ; zeroing out lower register clears upper bits too
    xor eax, eax    ; sys_read
    xor edi, edi    ; fd 0 STDIN
    syscall
    ret
    

; rsi = char *buff, rdx = size_t count
write:
    mov eax, 1      ; sys_write
    mov edi, 1      ; fd 1 STDOUT
    syscall
    ret


    


    

