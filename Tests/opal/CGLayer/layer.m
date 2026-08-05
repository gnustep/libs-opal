/* CGLayer size and context, and compositing a layer drawn green into a
   destination context.  Expected values checked against Apple CoreGraphics. */
#include "Testing.h"

#include <CoreGraphics/CGLayer.h>
#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGImage.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGColor.h>
#include <math.h>
#include <stdlib.h>

int main(void)
{
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();
  unsigned char *dest = calloc(10 * 10 * 4, 1);
  CGContextRef dctx = CGBitmapContextCreate(dest, 10, 10, 8, 40, dev,
    kCGImageAlphaPremultipliedLast);

  START_SET("CGLayer")

  CGLayerRef layer = CGLayerCreateWithContext(dctx, CGSizeMake(4, 4), NULL);
  PASS(layer != NULL, "creating a layer returns a layer");
  CGSize sz = CGLayerGetSize(layer);
  PASS(sz.width == 4 && sz.height == 4, "the layer reports its size");
  PASS(CGLayerGetContext(layer) != NULL, "the layer has a drawing context");

  /* Draw green into the layer, then composite it into the destination. */
  CGContextRef lctx = CGLayerGetContext(layer);
  CGFloat green[] = {0, 1, 0, 1};
  CGColorRef gc = CGColorCreate(dev, green);
  CGContextSetFillColorWithColor(lctx, gc);
  CGContextFillRect(lctx, CGRectMake(0, 0, 4, 4));

  CGContextDrawLayerAtPoint(dctx, CGPointMake(2, 2), layer);
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(dctx);
  int in = (4 * 10 + 4) * 4, out = 0;
  PASS(d[in] == 0 && d[in+1] == 255 && d[in+2] == 0 && d[in+3] == 255,
       "a pixel where the layer was composited is the layer's colour");
  PASS(d[out] == 0 && d[out+1] == 0 && d[out+2] == 0 && d[out+3] == 0,
       "a pixel outside the composited layer is untouched");

  CGColorRelease(gc);
  CGLayerRelease(layer);

  END_SET("CGLayer")

  CGContextRelease(dctx);
  CGColorSpaceRelease(dev);
  free(dest);
  return 0;
}
