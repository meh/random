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
* gcc `sdl-config --cflags` `sdl-config --libs` -lSDL_mixer -o f f.c *
*********************************************************************/

#include <stdio.h>
#include "SDL.h"
#include "SDL_mixer.h"

int
main (int argc, char *argv[])
{
    Mix_Music* music;

    if (argc < 2) {
        fprintf(stderr, "LOL NIG\n");
        return 1;
    }

    if (SDL_Init(SDL_INIT_AUDIO) < 0) {
        fprintf(stderr, "Failed init: %s\n", SDL_GetError());
        return 2;
    }

    if (Mix_OpenAudio(MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, MIX_DEFAULT_CHANNELS, 4096) < 0) {
        fprintf(stderr, "Failed mix: %s\n", Mix_GetError());
        return 3;
    }

    if (!(music = Mix_LoadMUS(argv[1]))) {
        fprintf(stderr, "Failed loading: %s\n", Mix_GetError());
        return 4;
    }

    if (Mix_PlayMusic(music, 1) < 0) {
        fprintf(stderr, "Failed to play: %s\n", Mix_GetError());
        return 5;
    }

    while (Mix_PlayingMusic()) {
        sleep(5);
    }

    return 0;
}
