/* CGContextClipToMask limits subsequent drawing by an image's coverage.  For an
   image mask a sample of 0 (black) paints and 255 (white) does not; for a
   normal image the value (or the alpha) is the coverage.  A green fill is
   clipped by a half-black/half-white mask - horizontally and vertically - and
   the painted half is checked.  Which pixels are painted matches Apple
   CoreGraphics. */
#include "Testing.h"

#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGColor.h>
#include <CoreGraphics/CGImage.h>
#include <CoreGraphics/CGGradient.h>
#include <CoreGraphics/CGDataProvider.h>
#include <stdlib.h>

#define W 8

static int A(unsigned char *d, int x, int y) { return d[(y*W + x)*4 + 3]; }

/* An 8x8 one-component image.  vertical=0: left half lo, right half hi;
   vertical=1: top image rows lo, bottom hi. */
static CGImageRef halfMask(int lo, int hi, int asMask, int vertical,
  CGColorSpaceRef gray)
{
  unsigned char *m = malloc(W*W);
  for (int y = 0; y < W; y++)
    for (int x = 0; x < W; x++)
      m[y*W+x] = ((vertical ? y : x) < W/2) ? lo : hi;
  CGDataProviderRef dp = CGDataProviderCreateWithData(NULL, m, W*W, NULL);
  if (asMask)
    return CGImageMaskCreate(W, W, 8, 8, W, dp, NULL, false);
  return CGImageCreate(W, W, 8, 8, W, gray, kCGImageAlphaNone, dp, NULL, false,
    kCGRenderingIntentDefault);
}

/* Fill green through the mask; write the four sample alphas. */
static void fillMasked(CGColorSpaceRef dev, CGImageRef mask,
  int *left, int *right, int *topDev, int *botDev)
{
  unsigned char *buf = calloc(W*W*4, 1);
  CGContextRef c = CGBitmapContextCreate(buf, W, W, 8, W*4, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextClipToMask(c, CGRectMake(0, 0, W, W), mask);
  CGContextSetRGBFillColor(c, 0, 1, 0, 1);
  CGContextFillRect(c, CGRectMake(0, 0, W, W));
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);
  *left = A(d,2,4); *right = A(d,6,4); *topDev = A(d,4,6); *botDev = A(d,4,1);
  CGContextRelease(c); free(buf);
}

int main(void)
{
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();
  CGColorSpaceRef gray = CGColorSpaceCreateDeviceGray();
  int l, r, t, b;

  START_SET("CGContextClipToMask image mask")

  fillMasked(dev, halfMask(0, 255, 1, 0, gray), &l, &r, &t, &b);
  PASS(l > 0 && r == 0, "an image mask paints where it is black, not where white");

  fillMasked(dev, halfMask(0, 255, 1, 1, gray), &l, &r, &t, &b);
  PASS(b > 0 && t == 0,
       "the mask is oriented like an image (its top maps to the top of the rect)");

  END_SET("CGContextClipToMask image mask")

  START_SET("CGContextClipToMask image")

  fillMasked(dev, halfMask(0, 255, 0, 0, gray), &l, &r, &t, &b);
  PASS(r > 0 && l == 0,
       "a normal image paints where it is light, not where dark");

  fillMasked(dev, halfMask(0, 255, 0, 1, gray), &l, &r, &t, &b);
  PASS(t > 0 && b == 0, "the image mask orientation is correct vertically");

  END_SET("CGContextClipToMask image")

  START_SET("CGContextClipToMask limits an image")

  /* Left half of the mask paints (black), right half does not. */
  unsigned char *ib = calloc(W*W*4, 1);
  CGContextRef ic = CGBitmapContextCreate(ib, W, W, 8, W*4, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextClipToMask(ic, CGRectMake(0, 0, W, W), halfMask(0, 255, 1, 0, gray));
  CGContextRef gimgCtx = CGBitmapContextCreate(NULL, W, W, 8, W*4, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextSetRGBFillColor(gimgCtx, 0, 1, 0, 1);
  CGContextFillRect(gimgCtx, CGRectMake(0, 0, W, W));
  CGImageRef gimg = CGBitmapContextCreateImage(gimgCtx);
  CGContextDrawImage(ic, CGRectMake(0, 0, W, W), gimg);
  unsigned char *idata = (unsigned char *)CGBitmapContextGetData(ic);
  PASS(A(idata,2,4) > 0 && A(idata,6,4) == 0, "a drawn image is limited by the mask");
  CGContextRelease(ic); CGContextRelease(gimgCtx); free(ib);

  END_SET("CGContextClipToMask limits an image")

  START_SET("CGContextClipToMask limits a gradient")

  unsigned char *gb = calloc(W*W*4, 1);
  CGContextRef gc = CGBitmapContextCreate(gb, W, W, 8, W*4, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextClipToMask(gc, CGRectMake(0, 0, W, W), halfMask(0, 255, 1, 0, gray));
  CGFloat comps[] = {1,0,0,1, 0,0,1,1};
  CGFloat locs[] = {0, 1};
  CGGradientRef grad = CGGradientCreateWithColorComponents(dev, comps, locs, 2);
  CGContextDrawLinearGradient(gc, grad, CGPointMake(0,0), CGPointMake(W,0), 0);
  unsigned char *gd = (unsigned char *)CGBitmapContextGetData(gc);
  PASS(A(gd,2,4) > 0 && A(gd,6,4) == 0, "a gradient is limited by the mask");
  CGContextRelease(gc); free(gb);

  END_SET("CGContextClipToMask limits a gradient")

  START_SET("CGContextClipToMask limits text")

  /* Count painted pixels in the right half with and without a left-half mask;
     the mask must suppress the right half.  Needs a font. */
  int rightNoMask = 0, rightMasked = 0, leftMasked = 0;
  for (int pass = 0; pass < 2; pass++)
    {
      unsigned char *tb = calloc(W*W*4, 1);
      CGContextRef tc = CGBitmapContextCreate(tb, W, W, 8, W*4, dev,
        kCGImageAlphaPremultipliedLast);
      if (pass == 1)
        CGContextClipToMask(tc, CGRectMake(0,0,W,W), halfMask(0,255,1,0,gray));
      CGContextSelectFont(tc, "DejaVu Sans", 10, kCGEncodingMacRoman);
      CGContextSetRGBFillColor(tc, 0, 1, 0, 1);
      CGContextShowTextAtPoint(tc, 0, 2, "MM", 2);
      unsigned char *td = (unsigned char *)CGBitmapContextGetData(tc);
      for (int y = 0; y < W; y++)
        for (int x = 0; x < W; x++)
          {
            if (A(td,x,y) > 0)
              {
                if (x >= W/2) { if (pass) rightMasked++; else rightNoMask++; }
                else if (pass) leftMasked++;
              }
          }
      CGContextRelease(tc); free(tb);
    }
  if (rightNoMask == 0)
    SKIP("no font available to draw text")
  PASS(rightMasked == 0 && leftMasked > 0,
       "text is limited by the mask (suppressed in the masked-out half)");

  END_SET("CGContextClipToMask limits text")

  START_SET("CGContextClipToMask does not affect unmasked contexts")

  unsigned char *buf = calloc(W*W*4, 1);
  CGContextRef c = CGBitmapContextCreate(buf, W, W, 8, W*4, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextSetRGBFillColor(c, 0, 1, 0, 1);
  CGContextFillRect(c, CGRectMake(0, 0, W, W));
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);
  PASS(A(d,4,4) == 255, "a context with no mask fills normally");
  CGContextRelease(c); free(buf);

  END_SET("CGContextClipToMask does not affect unmasked contexts")

  CGColorSpaceRelease(dev);
  return 0;
}
