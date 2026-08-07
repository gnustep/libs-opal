/* CGContext clipping confines drawing.  A green fill over a transparent 10x10
   device-RGB bitmap is limited by different clips: a path clip, an even-odd
   clip (which leaves a hole), a multi-rectangle clip, and nested clips (which
   intersect).  A pixel is "painted" when its alpha is non-zero.  Which pixels
   are painted matches Apple CoreGraphics. */
#include "Testing.h"

#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGColorSpace.h>
#include <stdlib.h>

#define W 10

static CGContextRef newCtx(unsigned char *buf, CGColorSpaceRef dev)
{
  CGContextRef c = CGBitmapContextCreate(buf, W, W, 8, W*4, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextSetRGBFillColor(c, 0, 1, 0, 1);
  return c;
}
static int A(unsigned char *d, int x, int y) { return d[(y*W + x)*4 + 3]; }

int main(void)
{
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();

  START_SET("CGContext path clip")

  unsigned char *b = calloc(W*W*4,1);
  CGContextRef c = newCtx(b, dev);
  CGContextBeginPath(c);
  CGContextAddRect(c, CGRectMake(2, 2, 6, 6));
  CGContextClip(c);
  CGContextFillRect(c, CGRectMake(0, 0, W, W));
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);
  PASS(A(d,5,5) > 0, "drawing inside the clip is painted");
  PASS(A(d,0,0) == 0, "drawing outside the clip is suppressed");
  CGContextRelease(c); free(b);

  END_SET("CGContext path clip")

  START_SET("CGContext even-odd clip")

  unsigned char *b = calloc(W*W*4,1);
  CGContextRef c = newCtx(b, dev);
  CGContextBeginPath(c);
  CGContextAddRect(c, CGRectMake(0, 0, 10, 10));
  CGContextAddRect(c, CGRectMake(3, 3, 4, 4));
  CGContextEOClip(c);
  CGContextFillRect(c, CGRectMake(0, 0, W, W));
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);
  PASS(A(d,1,1) > 0, "the even-odd ring is painted");
  PASS(A(d,5,5) == 0, "the even-odd inner rectangle is a hole");
  CGContextRelease(c); free(b);

  END_SET("CGContext even-odd clip")

  START_SET("CGContext multi-rect clip")

  unsigned char *b = calloc(W*W*4,1);
  CGContextRef c = newCtx(b, dev);
  CGRect rects[] = { CGRectMake(0,0,2,10), CGRectMake(6,0,2,10) };
  CGContextClipToRects(c, rects, 2);
  CGContextFillRect(c, CGRectMake(0, 0, W, W));
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);
  PASS(A(d,1,5) > 0, "the first clip rectangle is painted");
  PASS(A(d,4,5) == 0, "the gap between clip rectangles is suppressed");
  PASS(A(d,7,5) > 0, "the second clip rectangle is painted");
  CGContextRelease(c); free(b);

  END_SET("CGContext multi-rect clip")

  START_SET("CGContext nested clip")

  unsigned char *b = calloc(W*W*4,1);
  CGContextRef c = newCtx(b, dev);
  CGContextClipToRect(c, CGRectMake(0, 0, 7, 7));
  CGContextClipToRect(c, CGRectMake(4, 4, 6, 6));
  CGContextFillRect(c, CGRectMake(0, 0, W, W));
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);
  PASS(A(d,5,5) > 0, "the intersection of the clips is painted");
  PASS(A(d,1,1) == 0, "a point only in the first clip is suppressed");
  PASS(A(d,8,8) == 0, "a point only in the second clip is suppressed");
  CGContextRelease(c); free(b);

  END_SET("CGContext nested clip")

  CGColorSpaceRelease(dev);
  return 0;
}
