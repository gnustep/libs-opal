#include <stdlib.h>
#include <stdio.h>
#include <X11/Xlib.h>
#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGLayer.h>

#define pi 3.14159265358979323846

Display *d;
Window win;
CGContextRef ctx;

extern CGContextRef opal_XWindowContextCreate(Display *d, Window w);

CGLayerRef makeSampleLayer(CGContextRef ctx){
  CGRect layerBounds = CGRectMake(0,0,50, 50);
  CGLayerRef layer = CGLayerCreateWithContext(ctx, layerBounds.size, NULL);
  CGContextRef layerCtx = CGLayerGetContext(layer);

  CGContextSetRGBFillColor(layerCtx, 1, 1, 0, 0.5);
  CGContextFillRect(layerCtx, layerBounds);
  
  CGContextSetRGBStrokeColor(layerCtx, 0, 0, 0, 0.7);
  CGContextStrokeRect(layerCtx, layerBounds);


  // Draw a smiley

  CGContextAddArc(layerCtx, 10, 35, 4, 0, 2 * pi, 0); CGContextClosePath(layerCtx);
  CGContextAddArc(layerCtx, 40, 35, 4, 0, 2 * pi, 0); CGContextClosePath(layerCtx);

  CGContextAddArc(layerCtx, 12, 15, 4, 0, 2 * pi, 0);CGContextClosePath(layerCtx);
  CGContextAddArc(layerCtx, 19, 10, 4, 0, 2 * pi, 0);CGContextClosePath(layerCtx);
  CGContextAddArc(layerCtx, 25, 8, 4, 0, 2 * pi, 0);CGContextClosePath(layerCtx);
  CGContextAddArc(layerCtx, 31, 10, 4, 0, 2 * pi, 0);CGContextClosePath(layerCtx);
  CGContextAddArc(layerCtx, 38, 15, 4, 0, 2 * pi, 0);CGContextClosePath(layerCtx);

  CGContextSetRGBFillColor(layerCtx, 0, 0, 0, 0.7);
  CGContextFillPath(layerCtx);  

  CGContextSetRGBStrokeColor(layerCtx, 0, 0, 0, 1);
  CGContextStrokePath(layerCtx);

  
  return layer;
}

void draw(CGContextRef ctx, CGRect r)
{
  CGContextSetRGBFillColor(ctx, 0, 0, 1, 0.5);
  CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);
  CGContextFillRect(ctx, CGRectMake(10,10,r.size.width - 20, r.size.height - 20));
  CGContextStrokeRect(ctx, CGRectMake(10,10,r.size.width - 20, r.size.height - 20));
  
  // Draw some copies of a layer
  CGLayerRef layer = makeSampleLayer(ctx);
  
  // Draw some rotated faces
  CGContextSaveGState(ctx);
  CGContextTranslateCTM(ctx, 225, 125);
  int i;
  for (i = 0; i < 3; i++) {
    CGContextRotateCTM(ctx, 0.06);
    CGContextDrawLayerInRect(ctx, CGRectMake(-145,-110,290,220), layer);
  }
  CGContextRestoreGState(ctx);



  CGContextDrawLayerInRect(ctx, CGRectMake(80,15,290,220), layer);
  
  CGContextDrawLayerAtPoint(ctx, CGPointMake(100, 170), layer);
  CGContextDrawLayerAtPoint(ctx, CGPointMake(300, 170), layer);

  CGContextDrawLayerAtPoint(ctx, CGPointMake(100, 60), layer);
  CGContextDrawLayerAtPoint(ctx, CGPointMake(150, 16), layer);
  CGContextDrawLayerAtPoint(ctx, CGPointMake(200, 10), layer);
  CGContextDrawLayerAtPoint(ctx, CGPointMake(250, 16), layer);
  CGContextDrawLayerAtPoint(ctx, CGPointMake(300, 60), layer);
  CGLayerRelease(layer); 
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
