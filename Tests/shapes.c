#include <stdlib.h>
#include <stdio.h>
#include <X11/Xlib.h>
#include <CoreGraphics/CGContext.h>

#define pi 3.14159265358979323846

Display *d;
Window win;
CGContextRef ctx;

extern CGContextRef opal_XWindowContextCreate(Display *d, Window w);
extern void frameArc(CGContextRef context, CGRect r, int startAngle, int arcAngle);
extern void paintArc(CGContextRef context, CGRect r, int startAngle, int arcAngle);
extern void frameOval(CGContextRef context, CGRect r);
extern void paintOval(CGContextRef context, CGRect r);
extern void frameRect(CGContextRef context, CGRect r);
extern void paintRect(CGContextRef context, CGRect r);
extern void fillRoundedRect(CGContextRef context, CGRect rect, CGFloat ovalWidth, CGFloat ovalHeight);
extern void strokeRoundedRect(CGContextRef context, CGRect rect, CGFloat ovalWidth, CGFloat ovalHeight);

void draw(CGContextRef ctx, CGRect r)
{
	CGRect bounds = r;
	double a, b;
	int count, k;

	CGContextSetRGBFillColor(ctx, 0, 0, 0, 1);
	CGContextFillRect(ctx, CGRectMake(0, r.size.height / 2, r.size.width, r.size.height / 2));

	// Use a transparency layer for the first shape

        CGContextSetAlpha(ctx, 0.5);
        CGContextBeginTransparencyLayer(ctx, NULL);

	// Calculate the dimensions for an oval inside the bounding box
	a = 0.9 * bounds.size.width/4;
	b = 0.3 * bounds.size.height/2;
	count = 5;

	// Set the fill color to a partially transparent blue
	CGContextSetRGBFillColor(ctx, 0, 0, 1, 1);

	// Set the stroke color to an opaque black
	CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);

	// Set the line width to be used, in user space units.
	CGContextSetLineWidth(ctx, 3);

	// Save the conexts state because we are going to be moving the origin and
	// rotating context for drawing, but we would like to restore the current
	// state before drawing the next image.
	CGContextSaveGState(ctx);

	// Move the origin to the middle of the first image (left side) to draw.
	CGContextTranslateCTM(ctx, bounds.size.width/4, bounds.size.height/2);

	// Draw "count" ovals, rotating the context around the newly translated origin
	// 1/count radians after drawing each oval
	for (k = 0; k < count; k++)
	{
		// Paint the oval with the fill color
		paintOval(ctx, CGRectMake(-a, -b, 2 * a, 2 * b));

		// Frame the oval with the stroke color
		frameOval(ctx, CGRectMake(-a, -b, 2 * a, 2 * b));

		// Rotate the context around the center of the image
		CGContextRotateCTM(ctx, pi / count);
	}
	// Restore the saved state to a known state for dawing the next image
	CGContextRestoreGState(ctx);

	// End the transparency layer
        CGContextEndTransparencyLayer(ctx);



	// Calculate a bounding box for the rounded rect
	a = 0.9 * bounds.size.width/4;
	b = 0.3 * bounds.size.height/2;
	count = 5;

	// Set the fill color to a partially transparent red
	CGContextSetRGBFillColor(ctx, 1, 0, 0, 0.5);

	// Set the stroke color to an opaque black
	CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);

	// Set the line width to be used, in user space units.
	CGContextSetLineWidth(ctx, 3);

	// Save the conexts state because we are going to be moving the origin and
	// rotating context for drawing, but we would like to restore the current
	// state before drawing the next image.
	CGContextSaveGState(ctx);

	// Move the origin to the middle of the second image (right side) to draw.
	CGContextTranslateCTM(ctx, bounds.size.width/4 + bounds.size.width/2, bounds.size.height/2);

	for (k = 0; k < count; k++)
	{
		// Fill then stroke the rounding rect, otherwise the fill would cover the stroke
		fillRoundedRect(ctx, CGRectMake(-a, -b, 2 * a, 2 * b), 20, 20);
		strokeRoundedRect(ctx, CGRectMake(-a, -b, 2 * a, 2 * b), 20, 20);
		// Rotate the context for the next rounded rect
		CGContextRotateCTM(ctx, pi / count);
	}
	CGContextRestoreGState(ctx);       
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

  /* Flip coordinate system to match Quickdraw */
  CGContextTranslateCTM(ctx, 0, cr.size.height);
  CGContextScaleCTM(ctx, 1.0, -1.0);
#if 0
  /* Draw something */
	//  Draw the outer arcs in the left portion of the window
    r.size.height = 210;
    r.origin.x = 20;
    r.origin.y = 20;
    r.size.width = 210;
    frameArc(ctx, r, 0, 135);
    frameArc(ctx, r, 180 - 10, 20);
    frameArc(ctx, r, 225, 45);
    frameArc(ctx, r, 315 - 20, 40);
	
	// Draw the inner arcs in the left portion of the window
    r.size.height = 145;
    r.origin.x = 75;
    r.origin.y = 55;
    r.size.width = 100;
    frameArc(ctx, r, 0, 135);
    frameArc(ctx, r, 180 - 10, 20);
    frameArc(ctx, r, 225, 45);
    frameArc(ctx, r, 315 - 20, 40);
	
    /* Set the fill color to green. */
    CGContextSetRGBFillColor(ctx, 0, 1, 0, 1);
	
	// Draw and fill the outer arcs in the right portion of the window
    r.size.height = 210;
    r.origin.x = 270;
    r.origin.y = 20;
    r.size.width = 210;
    paintArc(ctx, r, 0, 135);
    paintArc(ctx, r, 180 - 10, 20);
    paintArc(ctx, r, 225, 45);
    paintArc(ctx, r, 315 - 20, 40);
	
    /* Set the fill color to yellow. */
    CGContextSetRGBFillColor(ctx, 1, 1, 0, 1);

	// Draw and fill the inner arcs in the right portion of the window
    r.size.height = 145;
    r.origin.x = 325;
    r.origin.y = 55;
    r.size.width = 100;
    paintArc(ctx, r, 0, 135);
    paintArc(ctx, r, 180 - 10, 20);
    paintArc(ctx, r, 225, 45);
    paintArc(ctx, r, 315 - 20, 40);
  CGContextFlush(ctx);
  getchar();

  XClearWindow(d, win);
	// Draw the outer oval in the left portion of the window
    r.size.height = 210;
    r.origin.x = 20;
    r.origin.y = 20;
    r.size.width = 210;
    frameOval(ctx, r);
	
	// Draw the inner oval in the left portion of the window
    r.size.height = 145;
    r.origin.x = 75;
    r.origin.y = 55;
    r.size.width = 100;
    frameOval(ctx, r);
	
    /* Set the fill color to green. */
    CGContextSetRGBFillColor(ctx, 0, 1, 0, 1);
	
	// Draw and fill the outter oval in the right portion of the window
    r.size.height = 210;
    r.origin.x = 270;
    r.origin.y = 20;
    r.size.width = 210;
    paintOval(ctx, r);
	
    /* Set the fill color to yellow. */
    CGContextSetRGBFillColor(ctx, 1, 1, 0, 1);
	
	// Draw and fill the inner oval in the right portion of the window
    r.size.height = 145;
    r.origin.x = 325;
    r.origin.y = 55;
    r.size.width = 100;
    paintOval(ctx, r);

  CGContextFlush(ctx);
  getchar();

  XClearWindow(d, win);
	/* Set the stroke color to black. */
    CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);
	
    r.size.height = 210;
    r.origin.x = 20;
    r.origin.y = 20;
    r.size.width = 210;
    frameRect(ctx, r);
	
    r.size.height = 145;
    r.origin.x = 75;
    r.origin.y = 55;
    r.size.width = 100;
    frameRect(ctx, r);

    /* Set the fill color to green. */
    CGContextSetRGBFillColor(ctx, 0, 1, 0, 1);
	
    r.size.height = 210;
    r.origin.x = 270;
    r.origin.y = 20;
    r.size.width = 210;
    paintRect(ctx, r);
	
    /* Set the fill color to yellow. */
    CGContextSetRGBFillColor(ctx, 1, 1, 0, 1);
	
    r.size.height = 145;
    r.origin.x = 325;
    r.origin.y = 55;
    r.size.width = 100;
    paintRect(ctx, r);

  CGContextFlush(ctx);
  getchar();
#endif

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
