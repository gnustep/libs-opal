/* Draw axial and radial shadings built from a CGFunction into a bitmap and
   check the result's structure: the ramp is grayscale and monotonic, an
   un-extended axial shading leaves the area outside its axis untouched, an
   extended one clamps to its end colours, and a radial shading runs dark at
   the centre to light at the rim.  Exact bytes are not checked because Apple
   gamma-curves the interpolation while the cairo backend interpolates
   linearly; the shape checked here matches Apple CoreGraphics. */
#include "Testing.h"

#include <CoreGraphics/CGShading.h>
#include <CoreGraphics/CGFunction.h>
#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGColorSpace.h>
#include <stdlib.h>

/* black -> white ramp, opaque */
static void ramp(void *info, const CGFloat *in, CGFloat *out)
{
  CGFloat t = in[0];
  out[0] = t; out[1] = t; out[2] = t; out[3] = 1;
}

static CGFunctionRef makeRamp(void)
{
  CGFloat domain[] = {0, 1};
  CGFloat range[] = {0, 1, 0, 1, 0, 1, 0, 1};
  CGFunctionCallbacks cb = {0, ramp, NULL};
  return CGFunctionCreate(NULL, 1, domain, 4, range, &cb);
}

static CGContextRef makeCtx(CGColorSpaceRef dev, unsigned char *buf)
{
  return CGBitmapContextCreate(buf, 10, 10, 8, 40, dev,
    kCGImageAlphaPremultipliedLast);
}

int main(void)
{
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();

  START_SET("CGShading axial")

  CGFunctionRef fn = makeRamp();
  PASS(fn != NULL, "a CGFunction is created");

  CGShadingRef sh = CGShadingCreateAxial(dev, CGPointMake(2, 5),
    CGPointMake(8, 5), fn, 0, 0);
  PASS(sh != NULL, "an axial shading is created");

  unsigned char *buf = calloc(10 * 10 * 4, 1);
  CGContextRef c = makeCtx(dev, buf);
  CGContextDrawShading(c, sh);
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);

  /* Without extension, the area to either side of the axis is untouched. */
  PASS(d[(5*10 + 0)*4 + 3] == 0, "an un-extended axial shading leaves the area before its start untouched");
  PASS(d[(5*10 + 9)*4 + 3] == 0, "an un-extended axial shading leaves the area after its end untouched");

  /* Inside the axis the ramp is opaque, grayscale and gets lighter along +x. */
  int lo = (5*10 + 3)*4, hi = (5*10 + 6)*4;
  PASS(d[lo+3] == 255 && d[hi+3] == 255, "the shading fills its axis opaquely");
  PASS(d[lo] == d[lo+1] && d[lo+1] == d[lo+2]
       && d[hi] == d[hi+1] && d[hi+1] == d[hi+2],
       "the ramp stays grayscale");
  PASS(d[hi] > d[lo], "the ramp gets lighter from start to end");

  CGShadingRelease(sh);
  free(buf);

  END_SET("CGShading axial")

  START_SET("CGShading axial extended")

  CGFunctionRef fn = makeRamp();
  CGShadingRef sh = CGShadingCreateAxial(dev, CGPointMake(2, 5),
    CGPointMake(8, 5), fn, 1, 1);
  unsigned char *buf = calloc(10 * 10 * 4, 1);
  CGContextRef c = makeCtx(dev, buf);
  CGContextDrawShading(c, sh);
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);

  int before = (5*10 + 0)*4, after = (5*10 + 9)*4;
  PASS(d[before+3] == 255 && d[after+3] == 255,
       "an extended axial shading fills beyond its axis");
  PASS(d[before] < 40, "before the start it clamps to the near-black start colour");
  PASS(d[after] > 200, "after the end it clamps to the near-white end colour");

  CGShadingRelease(sh);
  free(buf);

  END_SET("CGShading axial extended")

  START_SET("CGShading radial")

  CGFunctionRef fn = makeRamp();
  CGShadingRef sh = CGShadingCreateRadial(dev, CGPointMake(5, 5), 0,
    CGPointMake(5, 5), 5, fn, 1, 1);
  unsigned char *buf = calloc(10 * 10 * 4, 1);
  CGContextRef c = makeCtx(dev, buf);
  CGContextDrawShading(c, sh);
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);

  int centre = (5*10 + 5)*4, edge = (5*10 + 0)*4;
  PASS(d[centre+3] == 255 && d[edge+3] == 255, "the radial shading is opaque");
  PASS(d[centre] == d[centre+1] && d[centre+1] == d[centre+2],
       "the radial ramp stays grayscale");
  PASS(d[edge] > d[centre],
       "the radial ramp runs dark at the centre to light at the rim");

  CGShadingRelease(sh);
  free(buf);

  END_SET("CGShading radial")

  CGColorSpaceRelease(dev);
  return 0;
}
