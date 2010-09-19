/*********************************************************************/
/*           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE             */
/*                   Version 2, December 2004                        */
/*                                                                   */
/*  Copyleft meh.                                                    */
/*                                                                   */
/*           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE             */
/*  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION  */
/*                                                                   */
/*  0. You just DO WHAT THE FUCK YOU WANT TO.                        */
/*********************************************************************/

.data
    /* Strings */
    string_not_enough_arguments: .string "Usage: %s <ip> <start_port> [end_port]\n"
    string_port_range_error:     .string "The start port has to be lesser than the end port, faggot.\n"
    string_connection_error:     .string "Unable to connect to the host.\n"
    string_general_error:        .string "Something went wrong.\n"

    string_port_is_open:         .string "Port %d is open.\n"

    /* Arguments */
    argc:           .int    0
    program_name:   .int    0
    ip:             .int    0
    start_port:     .int    0
    end_port:       .int    0

    /* Data */
    current_port:   .int    0
    
    /* Socket stuff */
    server:         .space 128, 0 /* struct sockaddr */
    server_length=  .-server
    addr:           .int    0
    sockd:          .int    0

.text
    .global _start
    
_start:
    /* Program arguments stuff */
    pop     argc

    /* program_name = argv[0] */
    pop     program_name

    /* if (argc < 3) goto not_enough_arguments */
    cmpl    $3, argc
    jb      not_enough_arguments

    /* if (argc != 4) goto oneport; */
    cmpl    $4, argc
    jne     one_port_set

port_range_set:
    movl    $1, argc
    jmp     P1

one_port_set:
    movl $2, argc

P1:
    /* ip = argv[1] */
    pop     ip
    
    /* start_port = atoi(argv[1]); */
    call    atoi
    pop     %edx
    movl    %eax, start_port

    cmpl    $2, argc
    je      one_port

port_range:
    /* end_port = atoi(argv[2]); */
    call    atoi
    pop     %edx
    movl    %eax, end_port
    jmp     P2

one_port:
    movl    start_port, %eax
    movl    %eax, end_port

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
    call    inet_addr
    movl    %eax, addr
    addl    $4, %esp

scan:
    /* Creating the socket */
    movl    $102, %eax /* socketcall */
    movl    $1, %ebx   /* socket */

    xorl    %edx, %edx
    sub     $12, %esp
    movl    $2,  (%esp)
    movl    $1, 4(%esp)
    movl    $6, 8(%esp)
    mov     %esp, %ecx

    int     $0x80

    cmp     $1, %eax
    jb      general_error
    movl    %eax, sockd

    /* Fill struct sockaddr */
    movw    $2,server

    push    current_port
    call    htons
    movw    %ax, server+2

    /* server.sin_addr = addr */
    movl    addr, %edx
    movl    %edx, server+4  

    /* Connecting */
    movl    $102, %eax /* socketcall */
    movl    $3, %ebx   /* connect */

    sub     $12, %esp
    movl    sockd, %edx
    movl    %edx, (%esp)
    movl    $server, 4(%esp)
    movl    $server_length, 8(%esp)
    mov     %esp, %ecx

    int     $0x80

    cmp     $0, %eax
    jne     P3

    push    current_port
    push    $string_port_is_open
    call    printf

P3:
    /* Close socket */
    movl    $6, %eax
    movl    sockd, %ebx
    int     $0x80

    incl    current_port
    mov     current_port, %edx
    cmp     %edx, end_port
    jge     scan

    jmp     exit

not_enough_arguments:
    push    program_name
    push    $string_not_enough_arguments
    jmp     error

connection_error:
    push    $string_connection_error
    jmp     error

port_range_error:
    push    $string_port_range_error
    jmp     error

general_error:
    push    $string_general_error
    jmp     error

error:
    call    printf
    movl    $1,%eax
    movl    $1,%ebx
    int     $0x80

end:
    movl    $1,%eax
    xorl    %ebx,%ebx
    int     $0x80

