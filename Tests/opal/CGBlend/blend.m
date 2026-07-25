/* CGContextSetBlendMode selects the compositing/blending used by subsequent
   drawing.  An opaque red base is filled, a blend mode is set, then a
   half-transparent blue is filled over it; the resulting pixel is compared to
   Apple CoreGraphics.  Most modes map to a Cairo operator and match within one
   level of rounding.  Two are known deviations, marked hopeful: ColorBurn
   (Cairo's operator differs from CoreGraphics where a source channel is zero)
   and PlusDarker (no Cairo operator exists). */
#include "Testing.h"

#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGColorSpace.h>
#include <stdlib.h>

/* Composite blue-at-50% over opaque red with the given blend mode; write the
   resulting RGBA into out. */
static void blend(CGColorSpaceRef dev, CGBlendMode mode, unsigned char out[4])
{
  unsigned char *buf = calloc(4*4*4, 1);
  CGContextRef c = CGBitmapContextCreate(buf, 4, 4, 8, 16, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextSetRGBFillColor(c, 200/255.0, 0, 0, 1);
  CGContextFillRect(c, CGRectMake(0, 0, 4, 4));
  CGContextSetBlendMode(c, mode);
  CGContextSetRGBFillColor(c, 0, 0, 200/255.0, 0.5);
  CGContextFillRect(c, CGRectMake(0, 0, 4, 4));
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);
  out[0] = d[0]; out[1] = d[1]; out[2] = d[2]; out[3] = d[3];
  CGContextRelease(c); free(buf);
}

static int near4(const unsigned char g[4], int r, int gr, int b, int a)
{
  return abs(g[0]-r) <= 1 && abs(g[1]-gr) <= 1
      && abs(g[2]-b) <= 1 && abs(g[3]-a) <= 1;
}

int main(void)
{
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();
  unsigned char g[4];

  START_SET("CGContext blend modes")

  blend(dev, kCGBlendModeNormal, g);
  PASS(near4(g, 100,0,100,255), "Normal composites source over destination");
  blend(dev, kCGBlendModeMultiply, g);
  PASS(near4(g, 100,0,0,255), "Multiply darkens");
  blend(dev, kCGBlendModeScreen, g);
  PASS(near4(g, 200,0,100,255), "Screen lightens");
  blend(dev, kCGBlendModeDarken, g);
  PASS(near4(g, 100,0,0,255), "Darken keeps the darker channels");
  blend(dev, kCGBlendModeLighten, g);
  PASS(near4(g, 200,0,100,255), "Lighten keeps the lighter channels");
  blend(dev, kCGBlendModeHardLight, g);
  PASS(near4(g, 100,0,72,255), "HardLight blends");
  blend(dev, kCGBlendModeDifference, g);
  PASS(near4(g, 200,0,100,255), "Difference");
  blend(dev, kCGBlendModeExclusion, g);
  PASS(near4(g, 200,0,100,255), "Exclusion");
  blend(dev, kCGBlendModeHue, g);
  PASS(near4(g, 119,19,119,255), "Hue (non-separable)");
  blend(dev, kCGBlendModeLuminosity, g);
  PASS(near4(g, 137,0,0,255), "Luminosity (non-separable)");

  blend(dev, kCGBlendModeClear, g);
  PASS(near4(g, 0,0,0,0), "Clear erases");
  blend(dev, kCGBlendModeCopy, g);
  PASS(near4(g, 0,0,100,128), "Copy replaces with the source");
  blend(dev, kCGBlendModeSourceAtop, g);
  PASS(near4(g, 100,0,100,255), "SourceAtop");
  blend(dev, kCGBlendModeDestinationOver, g);
  PASS(near4(g, 200,0,0,255), "DestinationOver keeps the destination on top");
  blend(dev, kCGBlendModeXOR, g);
  PASS(near4(g, 100,0,0,127), "XOR");
  blend(dev, kCGBlendModePlusLighter, g);
  PASS(near4(g, 200,0,100,255), "PlusLighter adds");

  /* Known deviations. */
  testHopeful = YES;
  blend(dev, kCGBlendModeColorBurn, g);
  PASS(near4(g, 0,0,0,255), "ColorBurn matches CoreGraphics where a channel is zero");
  blend(dev, kCGBlendModePlusDarker, g);
  PASS(near4(g, 72,0,0,255), "PlusDarker matches CoreGraphics");
  testHopeful = NO;

  END_SET("CGContext blend modes")

  CGColorSpaceRelease(dev);
  return 0;
}
