/***************************************************************************/ 
/* WTFPL                                                                   */
/***************************************************************************/
/* as --32 -o file.o file.s                                                */
/* ld -melf_i386 -o file file.o                                            */
/***************************************************************************/

.data
    /* Data */
    length: .long 0

    /* Constants */
    mona:  .string "MONA"
    deco:  .string "*"
    endl:  .string "\n"
    space: .string " "

    ed:   .string "\n*"
    de:   .string "*\n"
    deds: .string "*\n* "
    sded: .string " *\n*"
    
.bss
    .macro __print string, length
        movl    $4, %eax
        movl    $1, %ebx
        movl    \string, %ecx
        movl    \length, %edx
        int     $0x80
    .endm

.text
.global _start

_start:
    pop  %ecx
    decl %ecx

    addl $4, %esp

    cmpl $0, %ecx
    jne  passed_argument
    
    push $mona
    incl %ecx

passed_argument:
    call __strlen
    movl %eax, length

/* top border */
    movl %eax, %ecx
    addl $4, %ecx

border_top:
    push    %ecx
    __print $deco, $1
    pop     %ecx
    loop border_top

    __print $ed, $2

/* top spaces */
    movl length, %ecx
    addl $2, %ecx

space_top:
    push    %ecx
    __print $space, $1
    pop     %ecx
    loop space_top

    __print $deds, $4

/* phrase */
    pop  %ecx
    __print %ecx, length

    __print $sded, $4

/* bottom spaces */
    movl length, %ecx
    addl $2, %ecx

space_bottom:
    push    %ecx
    __print $space, $1
    pop     %ecx
    loop space_bottom

    __print $de, $2

/* bottom border */
    movl length, %ecx
    addl $4, %ecx

border_bottom:
    push    %ecx
    __print $deco, $1
    pop     %ecx
    loop border_bottom
    __print $endl, $1

exit:
    movl $1, %eax
    movl $0, %ebx
    int  $0x80

/* int __strlen (char* str) */
__strlen:
    push    %ebp
    movl    %esp, %ebp
    push    %edi
    push    %ecx

    movl    8(%ebp), %edi
    movl    $0, %eax
    movl    $0, %ecx
    notl    %ecx
    cld
    repne   scasb
    notl    %ecx
    decl    %ecx

    movl    %ecx, %eax

    pop     %ecx
    pop     %edi
    pop     %ebp
    ret

