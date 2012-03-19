/*           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
 *                   Version 2, December 2004
 *
 *  Copyleft meh. [http://meh.doesntexist.org | meh@paranoici.org]
 *
 *           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
 *  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
 *
 *  0. You just DO WHAT THE FUCK YOU WANT TO.
 **********************************************************************
 * gcc -o vbell vbell.c `pkg-config 'xrandr' --libs` -lX11 -lm
 *
 * If you don't have a monitor with backlight support simply add
 * -DGAMMA -lXxf86vm to the compilation line
 *********************************************************************/

#define __USE_BSD

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <unistd.h>
#include <signal.h>

#include <X11/Xatom.h>
#include <X11/extensions/Xrandr.h>

// The difference between start and max gamma
#define GAMMA_DELTA 3
#define STEP        0.1

void catch (int number);
void initializeCatching (sig_t handler);

bool locked (void);
bool lock   (void);
bool unlock (void);

#ifdef GAMMA
#   include <X11/extensions/xf86vmode.h>

void Gamma_fade (Display* display, int screen, double from, double to, double step, float interval);
#endif

typedef struct BacklightRange {
    double min;
    double max;
} BacklightRange;

Atom            Backlight_retrieve  (Display* display);
bool            Backlight_supported (Display* display, RROutput output, Atom backlight);
BacklightRange* Backlight_range     (Display* display, RROutput output, Atom backlight);
double          Backlight_get       (Display* display, RROutput output, Atom backlight);
bool            Backlight_set       (Display* display, RROutput output, Atom backlight, double value);
void            Backlight_fade      (Display* display, RROutput output, Atom backlight, long from, long to, long step, double interval);

int
main (int argc, char** argv) {
    Display*            display;
    int                 screen;
    Window              root;
    XRRScreenResources* resources;
    RROutput            output;
    double              current;

    int major;
    int minor;

    int i;

    Atom backlight;
    bool supported = true;

    #ifdef GAMMA
    XF86VidModeGamma original;
    double           average;
    bool             backlightPresent;
    #endif

    initializeCatching(catch);

    if (locked() || !lock()) {
        return 0;
    }

    if ((display = XOpenDisplay(NULL)) == NULL) {
        fprintf(stderr, "Is X started?\n");
        unlock();
        return -1;
    }

    if (!XRRQueryVersion(display, &major, &minor) || (major < 1 || (major == 1 && minor < 2))) {
        fprintf(stderr, "XRandR too old.\n");
        supported = false;
    }
    else {
        if ((backlight = Backlight_retrieve(display)) == None) {
            fprintf(stderr, "Could not get a backlight.\n");
            supported = false;
        }
    }

    /* Force gamma if a parameter was given */
    if (argc > 1) {
        supported = false;
    }

    for (screen = 0; screen < ScreenCount(display); screen++) {
        #ifdef GAMMA
        backlightPresent = false;
        #endif

        if (supported) {
            root = RootWindow(display, screen);

            if (minor > 2) {
                resources = XRRGetScreenResourcesCurrent(display, root);
            }
            else {
                resources = XRRGetScreenResources(display, root);
            }

            if (!resources) {
                continue;
            }

            for (i = 0; i < resources->noutput; i++) {
                output = resources->outputs[i];

                if (Backlight_supported(display, output, backlight)) {
                    current = Backlight_get(display, output, backlight);

                    Backlight_fade(display, output, backlight, current, 0,       5, 0.005);
                    Backlight_fade(display, output, backlight, 0,       100,     5, 0.005);
                    Backlight_fade(display, output, backlight, 100,     0,       5, 0.005);
                    Backlight_fade(display, output, backlight, 0,       current, 5, 0.005);

                    #ifdef GAMMA
                    backlightPresent = true;
                    #endif
                }
            }
        }

        #ifdef GAMMA
        if (!supported || !backlightPresent) {
            if (!XF86VidModeGetGamma(display, screen, &original)) {
                fprintf(stderr, "Even gamma is not supported :(\n");
                continue;
            }

            /* Colors gamma may be different, we just want to change brightness, so get the average */
            average = ((original.red + original.green + original.blue) / 3);

            Gamma_fade(display, screen, average, average + 5, 0.1, 0.005);
            Gamma_fade(display, screen, average + 5, average, 0.1, 0.005);

            XF86VidModeSetGamma(display, screen, &original);
            XF86VidModeGetGamma(display, screen, &original);
        }
        #endif
    }

    XSync(display, False);
    XCloseDisplay(display);

    unlock();

    return 0;
}

void
catch (int number)
{
    unlock();
    exit(255);
}

void
initializeCatching (sig_t handler)
{
    static int signals[] = {
        SIGSEGV, SIGABRT, SIGFPE, SIGILL, SIGINT, SIGTERM
    };

    int i;

    for (i = 0; i < sizeof(signals) / sizeof(*signals); i++) {
        signal(signals[i], catch);
    }
}

bool
locked (void)
{
    FILE* file = fopen("/tmp/.__meh_vbell", "r");
    bool  result;

    if (file) {
        result = true;

        fclose(file);
    }
    else {
        result = false;
    }

    return result;
}

bool
lock (void)
{
    FILE* file;

    if (locked()) {
        return false;
    }

    file = fopen("/tmp/.__meh_vbell", "w");
    fclose(file);

    return true;
}

bool
unlock (void)
{
    if (!locked()) {
        return false;
    }

    unlink("/tmp/.__meh_vbell");

    return true;
}

#ifdef GAMMA

void
Gamma_fade (Display* display, int screen, double from, double to, double step, float interval)
{
    XF86VidModeGamma gamma;
    double           i;

    if (from < to ) {
        for (i = from; i < to; i += step) {
            gamma.red = gamma.green = gamma.blue = i;
            XF86VidModeSetGamma(display, screen, &gamma);
            /* For some reason you have to do a get to make the change effective */
            XF86VidModeGetGamma(display, screen, &gamma);

            usleep(interval * 1000000);
        }
    }
    else if (from > to) {
        for (i = from; i > to; i -= step) {
            gamma.red = gamma.green = gamma.blue = i;
            XF86VidModeSetGamma(display, screen, &gamma);
            XF86VidModeGetGamma(display, screen, &gamma);

            usleep(interval * 1000000);
        }
    }
    else {
        gamma.red = gamma.green = gamma.blue = from;
        XF86VidModeSetGamma(display, screen, &gamma);
        XF86VidModeGetGamma(display, screen, &gamma);
    }
}

#endif

Atom
Backlight_retrieve (Display* display)
{
    Atom result;

    if ((result = XInternAtom(display, "Backlight", True)) == None) {
        if ((result = XInternAtom(display, "BACKLIGHT", True)) == None) {
            return None;
        }
    }

    return result;
}

bool
Backlight_supported (Display* display, RROutput output, Atom backlight)
{
    return Backlight_get(display, output, backlight) != -1;
}

BacklightRange*
Backlight_range (Display* display, RROutput output, Atom backlight)
{
    BacklightRange*  range;
    XRRPropertyInfo* info = XRRQueryOutputProperty(display, output, backlight);

    if (!info || !(info->range && info->num_values == 2)) {
        return NULL;
    }

    range = malloc(sizeof(BacklightRange));
    range->min = info->values[0];
    range->max = info->values[1];

    XFree(info);

    return range;
}

double
Backlight_get (Display* display, RROutput output, Atom backlight)
{
    BacklightRange* range;
    unsigned long   items;
    unsigned long   after;
    unsigned char*  prop;
    Atom            type;
    int             format;

    double result = -1;

    if (XRRGetOutputProperty(display, output, backlight, 0, 4, False, False, None, &type, &format, &items, &after, &prop) != Success) {
        return result;
    }

    if (type != XA_INTEGER || items != 1 || format != 32) {
        result = -1;
    }
    else {
        if ((range = Backlight_range(display, output, backlight))) {
            /* The real values are something on the lines of 0 .. 15, so we need a % */
            result = (*((long *) prop) - range->min) * 100 / (range->max - range->min);

            free(range);
        }
    }

    XFree (prop);

    return result;
}

bool
Backlight_set (Display *display, RROutput output, Atom backlight, double value)
{
    long            raw;
    BacklightRange* range = Backlight_range(display, output, backlight);

    if (range == NULL) {
        return false;
    }

    /* Same as with the get */
    value *= (range->max - range->min) / 100;
    raw    = ceil(value);

    XRRChangeOutputProperty(display, output, backlight, XA_INTEGER, 32, PropModeReplace, (unsigned char *) &raw, 1);

    free(range);

    return true;
}

void
Backlight_fade (Display* display, RROutput output, Atom backlight, long from, long to, long step, double interval)
{
    int i;

    if (from < to ) {
        for (i = from; i < to; i += step) {
            Backlight_set(display, output, backlight, i);

            usleep(interval * 1000000);
        }
    }
    else if (from > to) {
        for (i = from; i > to; i -= step) {
            Backlight_set(display, output, backlight, i);

            usleep(interval * 1000000);
        }
    }
    else {
        Backlight_set(display, output, backlight, from);
    }
}

