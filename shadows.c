#include <stdlib.h>
#include <stdio.h>
#include <X11/Xlib.h>
#include <CGContext.h>
#include <CGLayer.h>

#define pi 3.14159265358979323846

Display *d;
Window win;
CGContextRef ctx;

extern CGContextRef opal_XWindowContextCreate(Display *d, Window w);

void draw(CGContextRef ctx, CGRect r)
{
  CGContextSetRGBFillColor(ctx, 0, 0, 1, 0.5);
  CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);
  CGContextFillRect(ctx, CGRectMake(10,10,r.size.width - 20, r.size.height - 20));
  CGContextStrokeRect(ctx, CGRectMake(10,10,r.size.width - 20, r.size.height - 20));
   
  CGContextSetShadow(ctx, CGSizeMake(3.0,3.0), 2.0);

  // Draw some rotated, shadowed squares
  CGContextSetRGBFillColor(ctx, 0, 1, 0.5, 1);
  CGContextSaveGState(ctx);
  CGContextTranslateCTM(ctx, 225, 125);
  int i;
  for (i = 0; i < 2; i++) {
    CGContextRotateCTM(ctx, 0.4);
    CGContextFillRect(ctx, CGRectMake(-50,-50,100,100));
  }
  CGContextRestoreGState(ctx);
  
  CGContextSetRGBFillColor(ctx, 1, 0, 0.5, 1);
  CGContextFillRect(ctx, CGRectMake(10, 200, 50, 15));
  CGContextFillRect(ctx, CGRectMake(10, 10, 15, 75));
  CGContextFillRect(ctx, CGRectMake(400, 10, 35, 35));
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

  cr = CGRectMake(0,0,500,250);
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
          draw(ctx, cr);
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
  return(EXIT_SUCCESS);
}
