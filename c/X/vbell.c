/*********************************************************************
*           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE              *
*                   Version 2, December 2004                         *
*                                                                    *
*  Copyleft meh. [http://meh.doesntexist.org | meh@paranoici.org]    *
*                                                                    *
*           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE              *
*  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION   *
*                                                                    *
*  0. You just DO WHAT THE FUCK YOU WANT TO.                         *
**********************************************************************
* gcc -o vbell vbell.c `pkg-config 'xrandr' --libs`                  *
*                                                                    *
* For gamma vbell support add -DGAMMA -lXxf86vm                      *
*********************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <unistd.h>

#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/extensions/Xrandr.h>

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
long            Backlight_get       (Display* display, RROutput output, Atom backlight);
bool            Backlight_set       (Display* display, RROutput output, Atom backlight, long value);
void            Backlight_fade      (Display* display, RROutput output, Atom backlight, long from, long to, long step, double interval);

int
main (int argc, char** argv) {
    Display*            display;
    int                 screen;
    Window              root;
    XRRScreenResources* resources;
    RROutput            output;
    long                current;

    int major;
    int minor;

    int i;

    Atom backlight;
    bool supported = true;

    #ifdef GAMMA
    XF86VidModeGamma original;
    double           average;
    #endif

    if ((display = XOpenDisplay(NULL)) == NULL) {
        fprintf(stderr, "Is X started?\n");
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

    if (supported) {
        for (screen = 0; screen < ScreenCount(display); screen++) {
            root      = RootWindow(display, screen);
            resources = XRRGetScreenResources(display, root);

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
                }
            }
        }
    }
    else {
        #ifdef GAMMA
        fprintf(stderr, "Dropping to gamma vbell.\n");

        for (screen = 0; screen < ScreenCount(display); screen++) {
            if (!XF86VidModeGetGamma(display, screen, &original)) {
                fprintf(stderr, "Even gamma is not supported :(\n");
                return -2;
            }

            average = ((original.red + original.green + original.blue) / 3);

            Gamma_fade(display, screen, average, average + 5, 0.1, 0.005);
            Gamma_fade(display, screen, average + 5, average, 0.1, 0.005);

            XF86VidModeSetGamma(display, screen, &original);
        }
        #endif
    }

    XSync(display, False);
    XCloseDisplay(display);

    return 0;
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
    XRRPropertyInfo* info = XRRQueryOutputProperty(display, output, backlight);

    if (!info || !(info->range && info->num_values == 2)) {
        return NULL;
    }

    BacklightRange* range = malloc(sizeof(BacklightRange));
    range->min = info->values[0];
    range->max = info->values[1];

    XFree(info);

    return range;
}

long
Backlight_get (Display* display, RROutput output, Atom backlight)
{
    BacklightRange* range;
    unsigned long   items;
    unsigned long   after;
    unsigned char*  prop;
    Atom            type;
    int             format;

    long result;

    if (XRRGetOutputProperty(display, output, backlight, 0, 4, False, False, None, &type, &format, &items, &after, &prop) != Success) {
        return -1;
    }

    if (type != XA_INTEGER || items != 1 || format != 32) {
        result = -1;
    }
    else {
        range = Backlight_range(display, output, backlight);

        if (range) {
            result = (*((long *) prop) - range->min) * 100 / (range->max - range->min);

            free(range);
        }
    }

    XFree (prop);

    return result;
}

bool
Backlight_set (Display *display, RROutput output, Atom backlight, long value)
{
    BacklightRange* range = Backlight_range(display, output, backlight);

    if (range == NULL) {
        return false;
    }

    value *= (range->max - range->min) / 100;

    XRRChangeOutputProperty(display, output, backlight, XA_INTEGER, 32, PropModeReplace, (unsigned char *) &value, 1);

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

