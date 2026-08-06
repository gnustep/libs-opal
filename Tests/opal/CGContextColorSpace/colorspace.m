/* Setting the fill or stroke colour space resets the current fill or stroke
   colour to that space's default - an opaque, zero-intensity colour (black).
   A non-default colour is set first, then the colour space, then the paint;
   the result should be black, not the earlier colour.  Checked against Apple
   CoreGraphics. */
#include "Testing.h"

#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGColorSpace.h>
#include <stdlib.h>

#define W 4

int main(void)
{
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();

  START_SET("CGContext fill colour space reset")

  unsigned char *buf = calloc(W*W*4, 1);
  CGContextRef c = CGBitmapContextCreate(buf, W, W, 8, W*4, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextSetRGBFillColor(c, 1, 0, 0, 1);      /* red */
  CGContextSetFillColorSpace(c, dev);           /* should reset to black */
  CGContextFillRect(c, CGRectMake(0, 0, W, W));
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);
  testHopeful = YES;
  PASS(d[0] == 0 && d[1] == 0 && d[2] == 0 && d[3] == 255,
       "setting the fill colour space resets the fill colour to black");
  testHopeful = NO;
  CGContextRelease(c); free(buf);

  END_SET("CGContext fill colour space reset")

  START_SET("CGContext stroke colour space reset")

  unsigned char *buf = calloc(W*W*4, 1);
  CGContextRef c = CGBitmapContextCreate(buf, W, W, 8, W*4, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextSetRGBStrokeColor(c, 1, 0, 0, 1);    /* red */
  CGContextSetStrokeColorSpace(c, dev);         /* should reset to black */
  CGContextSetLineWidth(c, 8);
  CGContextMoveToPoint(c, 0, 2);
  CGContextAddLineToPoint(c, W, 2);
  CGContextStrokePath(c);
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);
  testHopeful = YES;
  PASS(d[0] == 0 && d[1] == 0 && d[2] == 0 && d[3] == 255,
       "setting the stroke colour space resets the stroke colour to black");
  testHopeful = NO;
  CGContextRelease(c); free(buf);

  END_SET("CGContext stroke colour space reset")

  CGColorSpaceRelease(dev);
  return 0;
}
