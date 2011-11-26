#include <stdlib.h>
#include "prerror.h"
#include "prnetdb.h"
#include "prthread.h"

void
giveMessage (void* args)
{
    // Send a faggot message and close the socket
    PR_Send((PRFileDesc*) args, "THE GAME\r\n", 10, 0, PR_INTERVAL_NO_TIMEOUT);
    PR_Close((PRFileDesc*) args);
}

int
main (int argc, char *argv[])
{
    // Stuff that will be useful later
    PRThread* thread;
    PRFileDesc* client;

    // Create, bind and listen the new TCP socket
    PRFileDesc* socket = PR_NewTCPSocket();
    PRNetAddr   addr; PR_InitializeNetAddr(PR_IpAddrAny, 9001, &addr);
    PR_Bind(socket, &addr);
    PR_Listen(socket, 30);
    
    // Start the infinite cycle to get connections
    PRNetAddr waste;
    while ((client = PR_Accept(socket, &waste, PR_INTERVAL_NO_TIMEOUT))) {
        // Create a user thread that calls `giveMessage` passing `client`,
        // this thread will have high priority and will be local and unjoinable,
        // the stack size will be choosed by PR_CreateThread (0 = choice is yours)
        thread = PR_CreateThread(
            PR_USER_THREAD,
            giveMessage, client,
            PR_PRIORITY_HIGH, PR_LOCAL_THREAD, PR_UNJOINABLE_THREAD, 0
        );
    }

    return 0;
}

