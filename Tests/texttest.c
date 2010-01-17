#include <stdlib.h>
#include <stdio.h>
#include <X11/Xlib.h>
#include <CoreGraphics/CGContext.h>

Display *d;
Window win;
CGContextRef ctx;
static const char *fontName = "Times-Roman";

extern CGContextRef opal_XWindowContextCreate(Display *d, Window w);

void drawRect(CGContextRef currentContext, CGRect rect)
{
    CGRect pageRect = CGRectMake( 0, 0, rect.size.width, rect.size.height );

    CGContextBeginPage(currentContext, &pageRect);

    CGContextSetGrayFillColor(currentContext, 0, 1);

    CGContextSelectFont(currentContext, fontName, 1, kCGEncodingMacRoman);
    CGContextShowTextAtPoint(currentContext, 40, 200, "1: M x", 6);

    CGContextSelectFont(currentContext, fontName, 2, kCGEncodingMacRoman);
    CGContextShowTextAtPoint(currentContext, 40, 150, "2: M x", 6);

    CGContextSelectFont(currentContext, fontName, 3, kCGEncodingMacRoman);
    CGContextShowTextAtPoint(currentContext, 40, 100, "3: M x", 6);

    CGContextSelectFont(currentContext, fontName, 4, kCGEncodingMacRoman);
    CGContextShowTextAtPoint(currentContext, 40, 50, "4: M x", 6);

    CGContextEndPage(currentContext);

    CGContextFlush(currentContext);
}

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
  if (argc > 1)
  {
    fontName = argv[1];
  }

  cr = CGRectMake(0,0,480,360);
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
  printf("XCreateSimpleWindow returned: %lx\n", win);

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
        /* Draw window contents */
        if(e.xexpose.count == 0) {
          XClearWindow(d, win);
          drawRect(ctx, cr);
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
