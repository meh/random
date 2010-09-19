/***************************************************************************/ 
/*              DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE                */
/*                        Version 3, April 2009                            */
/*                                                                         */
/*  Copyleft meh.                                                          */
/*                                                                         */
/*              DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE                */
/*     TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION     */
/*                                                                         */
/*  0. You just DO WHAT THE FUCK YOU WANT TO.                              */
/*  1. ????                                                                */
/*  2. PROFIT                                                              */
/***************************************************************************/
/* This program is written in ASM x86 AT&T syntax on Linux.                */
/*                                                                         */
/* To compile it use the following commands where file is the file name.   */
/*                                                                         */
/* as --32 -o file.o file.s                                                */
/* ld -melf_i386 -o file file.o                                            */
/***************************************************************************/
/* This program gives you the ip address of the given interface.           */
/*                                                                         */
/* DO WHAT YOU WANT CAUSE A PIRATE IS FREE, YOU ARE A PIRATE!              */
/***************************************************************************/

.data
    /* Strings */
      string_usage_p1:         .string "Usage: "
    l_string_usage_p1=         .-string_usage_p1
      string_usage_p2:         .string " <interface>\n"
    l_string_usage_p2=         .-string_usage_p2
      string_general_error:    .string "Something went wrong.\n"
    l_string_general_error=    .-string_general_error
      string_no_interface:     .string "The interface doesn't exist.\n"
    l_string_no_interface=     .-string_no_interface

    dot:  .string "."
    endl: .string "\n"

    /* Arguments */
    argc:           .long   0
    program_name:   .long   0

    /* Constants */
    SIOCGIFNAME = 0x8910
    SIOCGIFADDR = 0x8915
    
    AF_INET        = 2
    SOCK_STREAM    = 1
    IPPROTO_UNSPEC = 0

    /* Data */
    sockd:     .long    0
    ifreq:     .space   40, 0
    interface: .long    0

.bss
    .macro __print string, length
        push    %ebx
        push    %ecx
        push    %edx

        movl    $4, %eax
        movl    $1, %ebx
        movl    \string, %ecx
        movl    \length, %edx
        int     $0x80

        pop     %edx
        pop     %ecx
        pop     %ebx
    .endm

.text
    .globl _start

_start:
    pop     argc
    pop     program_name

    cmp     $2, argc
    jl      usage

    pop     interface

    movl    $102, %eax
    movl    $1, %ebx

    sub     $12, %esp
    movl    $AF_INET, (%esp)
    movl    $SOCK_STREAM, 4(%esp)
    movl    $IPPROTO_UNSPEC, 8(%esp)
    mov     %esp, %ecx
    int     $0x80

    cmp     $1, %eax
    jl      general_error
    addl    $12, %esp

    movl    %eax, sockd

    push    $16
    push    interface
    push    $ifreq
    call    __strncpy
    add     $12, %esp

    movl    $54, %eax
    movl    sockd, %ebx
    movl    $SIOCGIFNAME, %ecx
    movl    $ifreq, %edx
    int     $0x80

    movl    $54, %eax
    movl    sockd, %ebx
    movl    $SIOCGIFADDR, %ecx
    movl    $ifreq, %edx
    int     $0x80

    movl    $6, %eax
    movl    sockd, %ebx
    int     $0x80

    cmp     $0, ifreq+16
    je      no_interface

    movl    ifreq+20, %ebx
    bswap   %ebx

    movl    %ebx, %ecx
    sarl    $24, %ecx
    andl    $0xff, %ecx
    push    %ecx
    call    __printl
    addl    $4, %esp

    __print $dot, $1

    movl    %ebx, %ecx
    sarl    $16, %ecx
    andl    $0xff, %ecx
    push    %ecx
    call    __printl
    addl    $4, %esp

    __print $dot, $1

    movl    %ebx, %ecx
    sarl    $8, %ecx
    andl    $0xff, %ecx
    push    %ecx
    call    __printl
    addl    $4, %esp

    __print $dot, $1

    movl    %ebx, %ecx
    andl    $0xff, %ecx
    push    %ecx
    call    __printl
    addl    $4, %esp

    __print $endl, $1

    jmp     end

usage:
    __print $string_usage_p1, $l_string_usage_p1

    /* Print the program name */
    movl    program_name, %ecx
    push    program_name
    call    __strlen
    addl    $4, %esp
    movl    %eax, %edx
    movl    $4, %eax
    movl    $1, %ebx
    int     $0x80

    __print $string_usage_p2, $l_string_usage_p2
    jmp     error

general_error:
    __print $string_general_error, $l_string_general_error
    jmp     error

no_interface:
    __print $string_no_interface, $l_string_no_interface
    jmp     error

error:
    movl    $1, %eax
    movl    $1, %ebx
    int     $0x80

end:
    movl    $1, %eax
    xorl    %ebx, %ebx
    int     $0x80

/* void __printl (int number) */
__printl:
    push    %ebp
    mov     %esp, %ebp
    sub     $8, %esp
    push    %ebx
    push    %ecx
    push    %edx

    movl    8(%ebp), %eax
    xorl    %ecx, %ecx
    xorl    %edx, %edx

    __printl_loop_1:
        mov     $10, %ebx
        divl    %ebx
        push    %edx
        xorl    %edx, %edx
        incl    %ecx

        cmp     $0, %eax
        jne     __printl_loop_1
    __printl_loop_end_1:

    movl    %ecx, -4(%ebp)

    __printl_loop_2:
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
        jne     __printl_loop_2
    __printl_loop_end_2:

    pop     %edx
    pop     %ecx
    pop     %ebx
    addl    $8, %esp
    pop     %ebp
    ret

/* int __strlen (char* str) */
__strlen:
    push    %ebp
    movl    %esp, %ebp
    push    %edi
    push    %ecx

    movl    8(%ebp), %edi
    xorl    %eax, %eax
    xorl    %ecx, %ecx
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

/* char* strncpy (char* dest, const char* src, int n) */
__strncpy:
    push    %ebp
    movl    %esp, %ebp
    push    %ebx
    push    %ecx
    push    %edx

    movl    8(%ebp), %ebx
    movl    12(%ebp), %edx
    movl    16(%ebp), %ecx
    
    __strncpy_loop:
        movzbl  (%edx), %eax
        movb    %al, (%ebx)

        cmpb    $0, %al
        je      __strncpy_fill_zero

        incl    %edx
        incl    %ebx
    loop __strncpy_loop

    jmp     __strncpy_end

    __strncpy_fill_zero:
        movb    $0, (%ebx)
        incl    %ebx
    loop __strncpy_fill_zero

    __strncpy_end:

    movl    -4(%ebx), %eax

    pop     %edx
    pop     %ecx
    pop     %ebx
    pop     %ebp
    ret

