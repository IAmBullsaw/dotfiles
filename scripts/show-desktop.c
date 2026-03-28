#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    int show = (argc > 1) ? atoi(argv[1]) : 1;
    Display *d = XOpenDisplay(NULL);
    if (!d) return 1;
    Window root = DefaultRootWindow(d);
    XEvent ev = {0};
    ev.xclient.type = ClientMessage;
    ev.xclient.window = root;
    ev.xclient.message_type = XInternAtom(d, "_NET_SHOWING_DESKTOP", False);
    ev.xclient.format = 32;
    ev.xclient.data.l[0] = show;
    XSendEvent(d, root, False, SubstructureRedirectMask | SubstructureNotifyMask, &ev);
    XFlush(d);
    XCloseDisplay(d);
    return 0;
}
