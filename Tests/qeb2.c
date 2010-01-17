#include <stdlib.h>
#include <stdio.h>
#include <X11/Xlib.h>
#include <CoreGraphics/CGContext.h>

Display *d;
Window win;
CGContextRef ctx;

extern CGContextRef opal_XWindowContextCreate(Display *d, Window w);
extern void myDraw(CGContextRef context, CGRect* contextRect);

int main(int argc, char **argv)
{
  int ret;
  CGRect cr;
  XSetWindowAttributes wa;
  XEvent e;

  d = XOpenDisplay(NULL);
  if (!d) {
    fprintf(stderr,"Cannot open display: %s\n", XDisplayName(NULL));
    exit(EXIT_FAILURE);
  }
  printf("Opened display %s\n", DisplayString(d));

  cr = CGRectMake(0,0,545,391);
  wa.background_pixel = WhitePixel(d, DefaultScreen(d));
  wa.event_mask = ExposureMask | ButtonReleaseMask;

  /* Create a window */
  win = XCreateWindow(d, /* Display */
        DefaultRootWindow(d), /* Parent */
        cr.origin.x, cr.origin.y, /* x, y */
        cr.size.width, cr.size.height, /* width, height */
        0, /* border_width */
        CopyFromParent, /* depth */
        InputOutput, /* class */
        CopyFromParent, /* visual */
        CWBackPixel | CWEventMask, /* valuemask */
        &wa); /* attributes */
  printf("XCreateWindow returned: %lx\n", win);

  /* Map the window */
  ret = XMapRaised(d, win);
  printf("XMapRaised returned: %x\n", ret);

  /* Create a CGContext */
  ctx = opal_XWindowContextCreate(d, win);
  if (!ctx) {
    fprintf(stderr,"Cannot create context\n");
    exit(EXIT_FAILURE);
  }
  printf("Created context\n");

  while(1)
  {
    XNextEvent(d,&e);
    switch(e.type)
    {
      case Expose:
        /* Dispose multiple events */
        while (XCheckTypedEvent(d, Expose, &e));
        /* Draw window contents */
        if(e.xexpose.count == 0) {
          CGContextSaveGState(ctx);
          XClearWindow(d, win);
          myDraw(ctx, &cr);
          CGContextRestoreGState(ctx);
        }
        break;

      case ButtonRelease:
        /* Finish program */
        CGContextRelease(ctx);
        XCloseDisplay(d);
        exit(EXIT_SUCCESS);
        break;
    }
  }
}
