/* CGGradient drawing.  A gradient has no public accessors, so this checks its
   rendered result: a linear gradient interpolates from the start colour to the
   end colour across the drawing.  Structural properties (monotonic, grayscale,
   opaque, endpoint colours) are checked rather than exact bytes, because the
   interpolation is gamma-dependent.  Behaviour checked against Apple
   CoreGraphics on a macOS runner. */
#include "Testing.h"

#include <CoreGraphics/CGGradient.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGImage.h>
#include <stdlib.h>

int main(void)
{
  START_SET("CGGradient")

  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();
  CGFloat locs[] = {0.0, 1.0};

  /* Black to white. */
  CGFloat bw[] = {0, 0, 0, 1,  1, 1, 1, 1};
  CGGradientRef g = CGGradientCreateWithColorComponents(dev, bw, locs, 2);
  PASS(g != NULL, "creating a gradient returns a gradient");

  unsigned char *d1 = calloc(10 * 4, 1);
  CGContextRef c1 = CGBitmapContextCreate(d1, 10, 1, 8, 40, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextDrawLinearGradient(c1, g, CGPointMake(0, 0), CGPointMake(10, 0), 0);
  unsigned char *p1 = (unsigned char *)CGBitmapContextGetData(c1);

  PASS(p1[0] < 60 && p1[3] == 255,
       "the start of a black-to-white gradient is near black");
  PASS(p1[9 * 4] > 200 && p1[9 * 4 + 3] == 255,
       "the end of a black-to-white gradient is near white");

  BOOL gray = YES, mono = YES, opaque = YES;
  for (int x = 0; x < 10; x++)
    {
      unsigned char *px = p1 + x * 4;
      if (!(px[0] == px[1] && px[1] == px[2])) gray = NO;
      if (px[3] != 255) opaque = NO;
      if (x > 0 && px[0] < p1[(x - 1) * 4]) mono = NO;
    }
  PASS(gray, "a black-to-white gradient stays grayscale");
  PASS(mono, "the gradient increases monotonically from start to end");
  PASS(opaque, "the gradient is opaque");

  /* Red to blue: check the colour channels interpolate. */
  CGFloat rb[] = {1, 0, 0, 1,  0, 0, 1, 1};
  CGGradientRef g2 = CGGradientCreateWithColorComponents(dev, rb, locs, 2);
  unsigned char *d2 = calloc(10 * 4, 1);
  CGContextRef c2 = CGBitmapContextCreate(d2, 10, 1, 8, 40, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextDrawLinearGradient(c2, g2, CGPointMake(0, 0), CGPointMake(10, 0), 0);
  unsigned char *p2 = (unsigned char *)CGBitmapContextGetData(c2);

  PASS(p2[0] > 200 && p2[2] < 60,
       "the start of a red-to-blue gradient is red");
  PASS(p2[9 * 4] < 60 && p2[9 * 4 + 2] > 200,
       "the end of a red-to-blue gradient is blue");

  CGGradientRelease(g);
  CGGradientRelease(g2);
  CGContextRelease(c1);
  CGContextRelease(c2);
  CGColorSpaceRelease(dev);
  free(d1);
  free(d2);

  END_SET("CGGradient")
  return 0;
}
