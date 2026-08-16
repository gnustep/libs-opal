/* CGContextDrawTiledImage tiles an image across the clip region.  A 4x4 tile
   (left half green, right half blue) is tiled over a 12x12 context; the tile
   repeats with a period of 4 and fills the whole context.  Checked against
   Apple CoreGraphics. */
#include "Testing.h"

#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGImage.h>
#include <stdlib.h>

#define W 12

static CGImageRef makeTile(CGColorSpaceRef dev)
{
  CGContextRef c = CGBitmapContextCreate(NULL, 4, 4, 8, 16, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextSetRGBFillColor(c, 0, 1, 0, 1);
  CGContextFillRect(c, CGRectMake(0, 0, 2, 4));
  CGContextSetRGBFillColor(c, 0, 0, 1, 1);
  CGContextFillRect(c, CGRectMake(2, 0, 2, 4));
  CGImageRef img = CGBitmapContextCreateImage(c);
  CGContextRelease(c);
  return img;
}

/* green channel and blue channel of a pixel */
static int G(unsigned char *d, int x, int y) { return d[(y*W + x)*4 + 1]; }
static int B(unsigned char *d, int x, int y) { return d[(y*W + x)*4 + 2]; }

int main(void)
{
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();

  START_SET("CGContext draw tiled image")

  unsigned char *buf = calloc(W*W*4, 1);
  CGContextRef c = CGBitmapContextCreate(buf, W, W, 8, W*4, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextDrawTiledImage(c, CGRectMake(0, 0, 4, 4), makeTile(dev));
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);

  /* Each 4px tile is green in its left half, blue in its right half. */
  PASS(G(d,0,6) > 200 && G(d,1,6) > 200, "the first tile's left half is green");
  PASS(B(d,2,6) > 200 && B(d,3,6) > 200, "the first tile's right half is blue");
  PASS(G(d,4,6) > 200 && G(d,5,6) > 200, "the pattern repeats a tile later");
  PASS(B(d,6,6) > 200 && B(d,7,6) > 200, "the right half repeats too");
  PASS(G(d,8,6) > 200 && B(d,10,6) > 200, "tiling continues across the context");

  /* The tile fills the whole context, not just the origin tile. */
  PASS(B(d,10,10) > 200, "a far corner is filled by the tiling");

  CGContextRelease(c); free(buf);

  END_SET("CGContext draw tiled image")

  CGColorSpaceRelease(dev);
  return 0;
}
