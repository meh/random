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
* gcc -lX11 -o watchingmovie file.c                                  *
**********************************************************************
* I was watching a movie with my partner and the screen kept         *
* blanking, then, here the hackish solution :P                       *
*                                                                    *
* DO WHAT YOU WANT CAUSE A PIRATE IS FREE, YOU ARE A PIRATE!         *
*********************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <X11/Xlib.h>

#define WAIT_FOR 360

#define USAGE \
    "Usage: watchingmovie [options]\n" \
    "    -p  x-y:x-y | tl, tr, bl, br   Toggle between the x-y couple or angle\n" \
    "    -s  n                          Seconds to wait for next move\n" \
    "    -h                             Print this help\n"

#define ERROR(str) fprintf(stdout, str); exit(-1);

int
main (int argc, char *argv[])
{
    Display* display;
    Screen*  screen;
    Window   root;
    int      width;
    int      height;
    int      fromX;
    int      fromY;
    int      toX;
    int      toY;
    int      waitFor;

    int   i;
    int   toggle = 0;
    char* token;

    display = XOpenDisplay(NULL);
    screen  = XDefaultScreenOfDisplay(display);
    root    = DefaultRootWindow(display);
    width   = XWidthOfScreen(screen);
    height  = XHeightOfScreen(screen);

    fromX   = width;
    fromY   = 0;
    toX     = width;
    toY     = 1;
    waitFor = WAIT_FOR;

    for (i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0) {
            ERROR(USAGE);
        }
        else if (strcmp(argv[i], "-p") == 0) {
            if (i == argc-1) {
                ERROR(USAGE);
            }

            i++;

            if (strcmp(argv[i], "tl") == 0) {
                fromX = 0;
                fromY = 0;
                toX   = 0;
                toY   = 1;
            }
            else if (strcmp(argv[i], "tr") == 0) {
                fromX = width;
                fromY = 0;
                toX   = width;
                toY   = 1;
            }
            else if (strcmp(argv[i], "bl") == 0) {
                fromX = 0;
                fromY = height;
                toX   = 0;
                toY   = height-2;
            }
            else if (strcmp(argv[i], "br") == 0) {
                fromX = width;
                fromY = height;
                toX   = width;
                toY   = height-2;
            }
            else {
                fromX = atoi(argv[i]);
                
                if (!(token = strchr(argv[i], '-')) || strlen(token+1) == 0) {
                    ERROR(USAGE);
                }
    
                fromY = atoi(token+1);
    
                if (!(token = strchr(argv[i], ':')) || strlen(token+1) == 0) {
                    ERROR(USAGE);
                }
    
                toX = atoi(token+1);
    
                if (!(token = strchr(strchr(argv[i], '-')+1, '-')) || strlen(token+1) == 0) {
                    ERROR(USAGE);
                }
    
                toY = atoi(token+1);
            }
        }
        else if (strcmp(argv[i], "-s") == 0) {
            if (i == argc-1) {
                ERROR(USAGE);
            }

            i++;

            waitFor = atoi(argv[i]);
        }
        else {
            ERROR(USAGE);
        }
    }

    while (1) {
        if (toggle == 0) {
            toggle = 1;
            XWarpPointer(display, None, root, 0, 0, width, height, fromX, fromY);
        }
        else {
            toggle = 0;
            XWarpPointer(display, None, root, 0, 0, width, height, toX, toY);
        }

        XFlush(display);
        sleep(waitFor);
    }
}
