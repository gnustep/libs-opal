/* A CGPattern is drawn by tiling its cell over a fill.  A 4x4 cell that paints
   one half tiles with a period of 4 pixels; filling a 12x8 rect repeats the
   painted/clear stripes.  Colored patterns paint their own colours; uncolored
   patterns are tinted with the caller's components (via the pattern colour
   space's base space).  Transparent device-RGB bitmap; a pixel is "painted"
   when its alpha is non-zero.  The tiling period, origin and orientation, and
   the pattern colour space properties, match Apple CoreGraphics (exact
   antialiased edges are not compared - the cell edges are whole pixels here). */
#include "Testing.h"

#include <CoreGraphics/CGPattern.h>
#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGColor.h>
#include <stdlib.h>

#define W 12
#define H 8

/* Cell painting its left half (x 0..2) green. */
static void drawLeft(void *info, CGContextRef c)
{
  CGContextSetRGBFillColor(c, 0, 1, 0, 1);
  CGContextFillRect(c, CGRectMake(0, 0, 2, 4));
}

/* Cell painting its bottom half (y 0..2) green. */
static void drawBottom(void *info, CGContextRef c)
{
  CGContextSetRGBFillColor(c, 0, 1, 0, 1);
  CGContextFillRect(c, CGRectMake(0, 0, 4, 2));
}

/* Cell painting its left half with the current (caller-supplied) colour. */
static void drawLeftUncolored(void *info, CGContextRef c)
{
  CGContextFillRect(c, CGRectMake(0, 0, 2, 4));
}

static int A(unsigned char *d, int x, int y) { return d[(y*W + x)*4 + 3]; }
static int chan(unsigned char *d, int x, int y, int i) { return d[(y*W + x)*4 + i]; }

static CGContextRef fillWithPattern(unsigned char *buf, CGColorSpaceRef dev,
  CGPatternDrawPatternCallback draw)
{
  CGContextRef c = CGBitmapContextCreate(buf, W, H, 8, W*4, dev,
    kCGImageAlphaPremultipliedLast);
  CGPatternCallbacks cb = {0, draw, NULL};
  CGPatternRef pat = CGPatternCreate(NULL, CGRectMake(0, 0, 4, 4),
    CGAffineTransformIdentity, 4, 4, kCGPatternTilingNoDistortion, 1, &cb);
  CGContextSetFillPattern(c, pat, NULL);
  CGContextFillRect(c, CGRectMake(0, 0, W, H));
  CGPatternRelease(pat);
  return c;
}

int main(void)
{
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();

  START_SET("CGPattern creation")

  CGPatternCallbacks cb = {0, drawLeft, NULL};
  CGPatternRef pat = CGPatternCreate(NULL, CGRectMake(0, 0, 4, 4),
    CGAffineTransformIdentity, 4, 4, kCGPatternTilingNoDistortion, 1, &cb);
  PASS(pat != NULL, "a pattern is created");
  CGPatternRelease(pat);

  END_SET("CGPattern creation")

  START_SET("CGPattern horizontal tiling")

  unsigned char *buf = calloc(W*H*4, 1);
  CGContextRef c = fillWithPattern(buf, dev, drawLeft);
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);
  /* Left half of each 4px cell is green, right half clear, repeating. */
  PASS(A(d,0,4) > 0 && A(d,1,4) > 0, "the cell's painted half is drawn");
  PASS(A(d,2,4) == 0 && A(d,3,4) == 0, "the cell's clear half is left clear");
  PASS(A(d,4,4) > 0 && A(d,5,4) > 0, "the pattern repeats a cell later");
  PASS(A(d,6,4) == 0 && A(d,7,4) == 0, "the clear half repeats too");
  PASS(A(d,8,4) > 0 && A(d,9,4) > 0, "and repeats again across the fill");
  CGContextRelease(c); free(buf);

  END_SET("CGPattern horizontal tiling")

  START_SET("CGPattern vertical tiling")

  unsigned char *buf = calloc(W*H*4, 1);
  CGContextRef c = fillWithPattern(buf, dev, drawBottom);
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);
  /* The pattern tiles vertically with a period of 4, matching Apple's cell
     placement (the cell's painted band lands at y 2..4 and 6..8). */
  PASS(A(d,1,2) > 0 && A(d,1,3) > 0, "a painted band of the cell is drawn");
  PASS(A(d,1,0) == 0 && A(d,1,1) == 0, "the cell's clear band is left clear");
  PASS(A(d,1,6) > 0 && A(d,1,7) > 0, "the band repeats a cell later vertically");
  CGContextRelease(c); free(buf);

  END_SET("CGPattern vertical tiling")

  START_SET("CGPattern colour space")

  CGColorSpaceRef colored = CGColorSpaceCreatePattern(NULL);
  PASS(colored != NULL, "a colored pattern colour space is created");
  PASS(CGColorSpaceGetModel(colored) == kCGColorSpaceModelPattern,
       "its model is the pattern model");
  PASS(CGColorSpaceGetNumberOfComponents(colored) == 0,
       "a colored pattern colour space has no components");
  PASS(CGColorSpaceGetBaseColorSpace(colored) == NULL,
       "a colored pattern colour space has no base");
  CGColorSpaceRelease(colored);

  CGColorSpaceRef uncolored = CGColorSpaceCreatePattern(dev);
  PASS(CGColorSpaceGetModel(uncolored) == kCGColorSpaceModelPattern,
       "an uncolored pattern colour space's model is the pattern model");
  PASS(CGColorSpaceGetNumberOfComponents(uncolored) == 3,
       "its component count comes from its base");
  PASS(CGColorSpaceGetModel(CGColorSpaceGetBaseColorSpace(uncolored))
         == kCGColorSpaceModelRGB,
       "its base colour space is reported");
  CGColorSpaceRelease(uncolored);

  END_SET("CGPattern colour space")

  START_SET("CGPattern uncolored")

  unsigned char *buf = calloc(W*H*4, 1);
  CGContextRef c = CGBitmapContextCreate(buf, W, H, 8, W*4, dev,
    kCGImageAlphaPremultipliedLast);
  CGPatternCallbacks cb = {0, drawLeftUncolored, NULL};
  CGPatternRef pat = CGPatternCreate(NULL, CGRectMake(0, 0, 4, 4),
    CGAffineTransformIdentity, 4, 4, kCGPatternTilingNoDistortion, 0, &cb);
  CGColorSpaceRef pcs = CGColorSpaceCreatePattern(dev);
  CGContextSetFillColorSpace(c, pcs);
  CGFloat blue[] = {0, 0, 1, 1};
  CGContextSetFillPattern(c, pat, blue);
  CGContextFillRect(c, CGRectMake(0, 0, W, H));
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);
  /* The cell is tinted with the caller's blue and tiled. */
  PASS(A(d,1,4) > 0 && chan(d,1,4,2) > 200
         && chan(d,1,4,0) < 60 && chan(d,1,4,1) < 60,
       "an uncolored pattern is tinted with the caller's colour");
  PASS(A(d,3,4) == 0, "the cell's clear half is left clear");
  PASS(A(d,5,4) > 0 && chan(d,5,4,2) > 200,
       "the tinted pattern repeats across the fill");
  CGPatternRelease(pat);
  CGColorSpaceRelease(pcs);
  CGContextRelease(c); free(buf);

  END_SET("CGPattern uncolored")

  CGColorSpaceRelease(dev);
  return 0;
}
