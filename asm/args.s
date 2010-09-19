.text
.global _start

_start:
    pop %ecx

args:
    call __printsu
    pop  %ebx
    loop args
    
/* void __printsu (unsigned short number) */
__printsu:
    push    %ebp
    mov     %esp, %ebp
    sub     $8, %esp
    push    %ebx
    push    %ecx
    push    %edx

    movzwl  8(%ebp), %eax
    movl    $0, %ecx
    movl    $0, %edx

    __printsu_loop_1:
        mov     $10, %ebx
        divl    %ebx
        push    %edx
        movl    $0, %edx
        incl    %ecx

        cmp     $0, %eax
        jne     __printsu_loop_1
    __printsu_loop_end_1:

    movl    %ecx, -4(%ebp)

    __printsu_loop_2:
        movl    $4, %eax
        movl    $1, %ebx

        pop     %ecx
        addl    $0x30, %ecx
        movl    %ecx, -8(%ebp)
        lea     -8(%ebp), %ecx

        movl    $1, %edx
        
        int     $0x80

        decl    -4(%ebp)
        cmpl    $0, -4(%ebp)
        jne     __printsu_loop_2
    __printsu_loop_end_2:

    pop     %edx
    pop     %ecx
    pop     %ebx
    addl    $8, %esp
    pop     %ebp
    ret

