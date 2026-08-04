/* Stroke line attributes affect how a path is painted: a wider line covers
   pixels farther from the path, a square cap extends past the endpoint while a
   butt cap does not, and a dash pattern leaves gaps.  Green stroke on a
   transparent device-RGB bitmap; a pixel is "painted" when its alpha is
   non-zero.  Which pixels are painted matches Apple CoreGraphics; the exact
   antialiased coverage is not compared. */
#include "Testing.h"

#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGColor.h>
#include <stdlib.h>

#define W 12

static CGContextRef newCtx(unsigned char *buf, CGColorSpaceRef dev)
{
  CGContextRef c = CGBitmapContextCreate(buf, W, W, 8, W*4, dev,
    kCGImageAlphaPremultipliedLast);
  CGFloat green[] = {0,1,0,1};
  CGColorRef gc = CGColorCreate(dev, green);
  CGContextSetStrokeColorWithColor(c, gc);
  CGColorRelease(gc);
  return c;
}

/* Alpha of a pixel (device-RGB bitmap read through the backing store). */
static int A(CGContextRef c, int x, int y)
{
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);
  return d[(y*W + x)*4 + 3];
}

int main(void)
{
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();

  START_SET("CGContext line width")

  unsigned char *b1 = calloc(W*W*4,1);
  CGContextRef c1 = newCtx(b1, dev);
  CGContextSetLineWidth(c1, 1);
  CGContextMoveToPoint(c1, 0, 6); CGContextAddLineToPoint(c1, W, 6);
  CGContextStrokePath(c1);
  PASS(A(c1,6,6) > 0, "a stroked line paints along its path");
  PASS(A(c1,6,3) == 0, "a thin line does not reach far from the path");

  unsigned char *b6 = calloc(W*W*4,1);
  CGContextRef c6 = newCtx(b6, dev);
  CGContextSetLineWidth(c6, 6);
  CGContextMoveToPoint(c6, 0, 6); CGContextAddLineToPoint(c6, W, 6);
  CGContextStrokePath(c6);
  PASS(A(c6,6,3) > 0, "a wider line reaches farther from the path");

  CGContextRelease(c1); CGContextRelease(c6); free(b1); free(b6);

  END_SET("CGContext line width")

  START_SET("CGContext line cap")

  unsigned char *bb = calloc(W*W*4,1);
  CGContextRef cb = newCtx(bb, dev);
  CGContextSetLineWidth(cb, 4);
  CGContextSetLineCap(cb, kCGLineCapButt);
  CGContextMoveToPoint(cb, 4, 6); CGContextAddLineToPoint(cb, 8, 6);
  CGContextStrokePath(cb);
  PASS(A(cb,6,6) > 0, "the stroked segment is painted");
  PASS(A(cb,2,6) == 0, "a butt cap does not extend beyond the endpoint");

  unsigned char *bs = calloc(W*W*4,1);
  CGContextRef cs = newCtx(bs, dev);
  CGContextSetLineWidth(cs, 4);
  CGContextSetLineCap(cs, kCGLineCapSquare);
  CGContextMoveToPoint(cs, 4, 6); CGContextAddLineToPoint(cs, 8, 6);
  CGContextStrokePath(cs);
  PASS(A(cs,2,6) > 0, "a square cap extends beyond the endpoint");

  CGContextRelease(cb); CGContextRelease(cs); free(bb); free(bs);

  END_SET("CGContext line cap")

  START_SET("CGContext line dash")

  unsigned char *bd = calloc(W*W*4,1);
  CGContextRef cd = newCtx(bd, dev);
  CGContextSetLineWidth(cd, 2);
  CGFloat dash[] = {2,2};
  CGContextSetLineDash(cd, 0, dash, 2);
  CGContextMoveToPoint(cd, 0, 6); CGContextAddLineToPoint(cd, W, 6);
  CGContextStrokePath(cd);
  PASS(A(cd,1,6) > 0, "a dash paints its on segment");
  PASS(A(cd,3,6) == 0, "a dash leaves a gap");
  PASS(A(cd,5,6) > 0, "the dash pattern repeats");

  CGContextRelease(cd); free(bd);

  END_SET("CGContext line dash")

  CGColorSpaceRelease(dev);
  return 0;
}
