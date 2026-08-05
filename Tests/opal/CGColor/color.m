/* CGColor components, alpha, number of components, equality, copy and
   copy-with-alpha for the generic colour spaces.  Expected values checked
   against Apple CoreGraphics. */
#include "Testing.h"

#include <CoreGraphics/CGColor.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGImage.h>
#include <math.h>
#include <stdlib.h>

static BOOL eqf(CGFloat a, CGFloat b)
{
  CGFloat d = a - b;
  if (d < 0) d = -d;
  return d < 1e-4;
}

int main(void)
{
  const CGFloat *c;

  START_SET("CGColor")

  CGColorRef rgb = CGColorCreateGenericRGB(0.1, 0.2, 0.3, 0.4);
  c = CGColorGetComponents(rgb);
  PASS(eqf(c[0], 0.1) && eqf(c[1], 0.2) && eqf(c[2], 0.3) && eqf(c[3], 0.4)
       && eqf(CGColorGetAlpha(rgb), 0.4),
       "a generic RGB colour exposes its components and alpha");
  testHopeful = YES;
  PASS(CGColorGetNumberOfComponents(rgb) == 4,
       "a generic RGB colour reports 4 components, counting alpha");
  testHopeful = NO;

  CGColorRef gray = CGColorCreateGenericGray(0.5, 0.8);
  c = CGColorGetComponents(gray);
  PASS(eqf(c[0], 0.5) && eqf(c[1], 0.8) && eqf(CGColorGetAlpha(gray), 0.8),
       "a generic gray colour exposes its component and alpha");
  testHopeful = YES;
  PASS(CGColorGetNumberOfComponents(gray) == 2,
       "a generic gray colour reports 2 components, counting alpha");
  testHopeful = NO;

  CGColorRef cmyk = CGColorCreateGenericCMYK(0.1, 0.2, 0.3, 0.4, 0.5);
  c = CGColorGetComponents(cmyk);
  PASS(eqf(c[0], 0.1) && eqf(c[3], 0.4) && eqf(CGColorGetAlpha(cmyk), 0.5),
       "a generic CMYK colour exposes its components and alpha");
  testHopeful = YES;
  PASS(CGColorGetNumberOfComponents(cmyk) == 5,
       "a generic CMYK colour reports 5 components, counting alpha");
  testHopeful = NO;

  CGColorRef rgbA = CGColorCreateCopyWithAlpha(rgb, 0.9);
  c = CGColorGetComponents(rgbA);
  PASS(eqf(c[0], 0.1) && eqf(c[1], 0.2) && eqf(c[2], 0.3) && eqf(c[3], 0.9)
       && eqf(CGColorGetAlpha(rgbA), 0.9),
       "copy-with-alpha keeps the colour and replaces the alpha");

  PASS(CGColorSpaceGetModel(CGColorGetColorSpace(rgb)) == kCGColorSpaceModelRGB,
       "a generic RGB colour reports the RGB colour space model");

  CGColorRef rgb2 = CGColorCreateGenericRGB(0.1, 0.2, 0.3, 0.4);
  CGColorRef copy = CGColorCreateCopy(rgb);
  testHopeful = YES;
  PASS(CGColorEqualToColor(rgb, rgb2) && !CGColorEqualToColor(rgb, gray),
       "equal colours compare equal and different colours do not");
  PASS(CGColorEqualToColor(rgb, copy),
       "a copy equals the original");
  testHopeful = NO;

  CGColorRelease(rgb);
  CGColorRelease(gray);
  CGColorRelease(cmyk);
  CGColorRelease(rgbA);
  CGColorRelease(rgb2);
  CGColorRelease(copy);

  /* Rendering: fill a 1x1 premultiplied-RGBA bitmap with a device colour and
     read the pixel with CGBitmapContextGetData.  A device colour into a
     device-RGB bitmap avoids colour-management conversion, so the pixel is the
     components scaled to bytes. */
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();

  unsigned char obuf[4] = {0, 0, 0, 0};
  CGContextRef octx = CGBitmapContextCreate(obuf, 1, 1, 8, 4, dev,
    kCGImageAlphaPremultipliedLast);
  CGFloat oc[] = {0.2, 0.4, 0.6, 1.0};
  CGColorRef ofill = CGColorCreate(dev, oc);
  CGContextSetFillColorWithColor(octx, ofill);
  CGContextFillRect(octx, CGRectMake(0, 0, 1, 1));
  unsigned char *opx = (unsigned char *)CGBitmapContextGetData(octx);
  PASS(opx[0] == 51 && opx[1] == 102 && opx[2] == 153 && opx[3] == 255,
       "filling a bitmap with an opaque device colour writes it to the pixel");

  unsigned char pbuf[4] = {0, 0, 0, 0};
  CGContextRef pctx = CGBitmapContextCreate(pbuf, 1, 1, 8, 4, dev,
    kCGImageAlphaPremultipliedLast);
  CGFloat pc[] = {1.0, 0.0, 0.0, 0.5};
  CGColorRef pfill = CGColorCreate(dev, pc);
  CGContextSetFillColorWithColor(pctx, pfill);
  CGContextFillRect(pctx, CGRectMake(0, 0, 1, 1));
  unsigned char *ppx = (unsigned char *)CGBitmapContextGetData(pctx);
  PASS(abs((int)ppx[0] - 128) <= 1 && ppx[1] == 0 && ppx[2] == 0
       && abs((int)ppx[3] - 128) <= 1,
       "filling with a half-alpha colour premultiplies red into the pixel");

  CGColorRelease(ofill);
  CGColorRelease(pfill);
  CGContextRelease(octx);
  CGContextRelease(pctx);
  CGColorSpaceRelease(dev);

  END_SET("CGColor")
  return 0;
}
