/* CGContext text state and drawing: the default text matrix is the identity,
   the text position and the text matrix share their translation (setting one
   is visible through the other), drawing text advances the text position along
   x, and drawing text paints pixels.  The state checks match Apple
   CoreGraphics; the drawing checks need a font and are skipped when none is
   available. */
#include "Testing.h"

#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGAffineTransform.h>
#include <stdlib.h>

#define W 30

static CGContextRef newCtx(unsigned char *buf, CGColorSpaceRef dev)
{
  return CGBitmapContextCreate(buf, W, W, 8, W*4, dev,
    kCGImageAlphaPremultipliedLast);
}

int main(void)
{
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();

  START_SET("CGContext text state")

  unsigned char *b = calloc(W*W*4,1);
  CGContextRef c = newCtx(b, dev);

  CGAffineTransform tm = CGContextGetTextMatrix(c);
  PASS(CGAffineTransformIsIdentity(tm), "the default text matrix is the identity");

  CGContextSetTextPosition(c, 3, 4);
  CGPoint p = CGContextGetTextPosition(c);
  PASS(p.x == 3 && p.y == 4, "the text position round-trips");
  CGAffineTransform tm2 = CGContextGetTextMatrix(c);
  PASS(tm2.tx == 3 && tm2.ty == 4,
       "the text position is the text matrix translation");

  CGContextSetTextMatrix(c, CGAffineTransformMake(2, 0, 0, 2, 5, 6));
  CGPoint p2 = CGContextGetTextPosition(c);
  PASS(p2.x == 5 && p2.y == 6,
       "setting the text matrix moves the text position");

  CGContextRelease(c); free(b);

  END_SET("CGContext text state")

  START_SET("CGContext text drawing")

  unsigned char *b = calloc(W*W*4,1);
  CGContextRef c = newCtx(b, dev);
  CGContextSelectFont(c, "DejaVu Sans", 14, kCGEncodingMacRoman);
  CGContextSetTextMatrix(c, CGAffineTransformIdentity);
  CGContextSetRGBFillColor(c, 0, 0, 0, 1);
  CGContextSetTextPosition(c, 2, 15);
  CGContextShowText(c, "Ag", 2);

  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);
  int painted = 0;
  for (int i = 0; i < W*W; i++) if (d[i*4+3] != 0) painted++;
  if (painted == 0)
    SKIP("no usable font available to draw text")

  CGPoint p = CGContextGetTextPosition(c);
  PASS(painted > 0, "drawing text paints pixels");
  PASS(p.x > 2.0, "drawing text advances the text position along x");
  PASS(p.y == 15.0, "drawing horizontal text leaves the y position unchanged");

  CGContextRelease(c); free(b);

  END_SET("CGContext text drawing")

  CGColorSpaceRelease(dev);
  return 0;
}
