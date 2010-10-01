/*********************************************************************
*           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE              *
*                   Version 2, December 2004                         *
*                                                                    *
*  Copyleft meh.                                                     *
*                                                                    *
*           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE              *
*  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION   *
*                                                                    *
*  0. You just DO WHAT THE FUCK YOU WANT TO.                         *
**********************************************************************
* Compilation:                                                       *
* gcc `nspr-config --cflags` `nspr-config --libs` -o file file.cpp   *
**********************************************************************
* Needed it in lulzJS and could be useful to someone else.           *
*                                                                    *
* DO WHAT YOU WANT CAUSE A PIRATE IS FREE, YOU ARE A PIRATE!         *
*********************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string>
#include "prnetdb.h"

char*
getHostByName (const char* host)
{
    char* buf = new char[PR_NETDB_BUF_SIZE];
    PRHostEnt hp; 
    if (PR_GetHostByName(host, buf, PR_NETDB_BUF_SIZE, &hp) == PR_FAILURE) {
        return NULL;
    }

    char* ip = new char[INET6_ADDRSTRLEN];
    int offset = 0;

    offset += sprintf(&ip[offset], "%u.", (unsigned char) hp.h_addr_list[0][0]);
    offset += sprintf(&ip[offset], "%u.", (unsigned char) hp.h_addr_list[0][1]);
    offset += sprintf(&ip[offset], "%u.", (unsigned char) hp.h_addr_list[0][2]);
    offset += sprintf(&ip[offset], "%u",  (unsigned char) hp.h_addr_list[0][3]);

    delete [] buf;

    return ip;
}

PRStatus
initAddr (PRNetAddr* addr, const char* host, int port = -1)
{
    std::string sHost = host;
 
    if (PR_StringToNetAddr(sHost.c_str(), addr) == PR_FAILURE) {
        std::string sIp;
        std::string sPort;
 
        if (sHost[0] == '[') {
            sIp = sHost.substr(1, sHost.find_last_of("]")-1);
            sPort = sHost.substr(sHost.find_last_of("]")+2);
        }
        else {
            sIp = sHost.substr(0, sHost.find_last_of(":"));
            sPort = sHost.substr(sHost.find_last_of(":")+1);
        }

        if (!sPort.empty()) {
            int tmp = atoi(sPort.c_str());

            if (tmp >= 1 && tmp <= 65536) {
                port = tmp;
            }
        }
 
        if (PR_StringToNetAddr(sIp.c_str(), addr) == PR_FAILURE) {
            char* ip = getHostByName(sIp.c_str());

            if (ip == NULL) {
                return PR_FAILURE;
            }

            sIp = ip; delete [] ip;
 
            if (PR_StringToNetAddr(sIp.c_str(), addr) == PR_FAILURE) {
                return PR_FAILURE;
            }
        }
    }
 
    if (port >= 1 && port <= 65536) {
        PR_InitializeNetAddr(PR_IpAddrNull, port, addr);
    }
 
    return PR_SUCCESS;
}

int
main (int argc, char *argv[])
{
    if (argc != 3) {
        return 1;
    }

    PRFileDesc* socket = PR_NewTCPSocket();
    PRNetAddr   addr; initAddr(&addr, argv[1], atoi(argv[2]));
    PR_Connect(socket, &addr, PR_INTERVAL_NO_TIMEOUT);

    char* string = (char*) malloc(10*sizeof(char));
    PR_Recv(socket, string, 10, 0, PR_INTERVAL_NO_TIMEOUT);
    string[10] = 0;
    printf("%s\n", string);

    PR_Close(socket);

}

