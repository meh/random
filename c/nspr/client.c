#include <stdio.h>
#include <stdlib.h>
#include "prnetdb.h"

int
main (int argc, char *argv[])
{
    // Create the new TCP socket and connect it to localhost
    PRFileDesc* socket = PR_NewTCPSocket();
    PRNetAddr   addr; //PR_InitializeNetAddr(PR_IpAddrLoopback, 9001, &addr);
    printf("%d\n", PR_StringToNetAddr("127.0.0.1:9001", &addr));
    PR_Connect(socket, &addr, PR_INTERVAL_NO_TIMEOUT);

    // Receive a string and output it
    char* string = (char*) malloc(10*sizeof(char));
    PR_Recv(socket, string, 10, 0, PR_INTERVAL_NO_TIMEOUT);
    string[10] = 0;
    printf("%s\n", string);

    // Close the socket
    PR_Close(socket);

    return 0;
}

