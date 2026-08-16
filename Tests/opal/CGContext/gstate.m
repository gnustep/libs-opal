/* CGContext graphics state: the CTM of a bitmap context, transforms,
   save/restore, clipping and global alpha.  Expected values checked against
   Apple CoreGraphics on a macOS runner. */
#include "Testing.h"

#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGImage.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGColor.h>
#include <CoreGraphics/CGAffineTransform.h>
#include <math.h>
#include <stdlib.h>

static BOOL eqf(CGFloat a, CGFloat b)
{
  CGFloat d = a - b;
  if (d < 0) d = -d;
  return d < 1e-4;
}

static BOOL teq(CGAffineTransform t, CGFloat a, CGFloat b, CGFloat c,
                CGFloat d, CGFloat tx, CGFloat ty)
{
  return eqf(t.a, a) && eqf(t.b, b) && eqf(t.c, c) && eqf(t.d, d)
      && eqf(t.tx, tx) && eqf(t.ty, ty);
}

static CGContextRef makeCtx(CGColorSpaceRef dev, unsigned char **data)
{
  *data = calloc(10 * 10 * 4, 1);
  return CGBitmapContextCreate(*data, 10, 10, 8, 40, dev,
    kCGImageAlphaPremultipliedLast);
}

int main(void)
{
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();

  START_SET("CGContext")

  unsigned char *data;
  CGContextRef ctx = makeCtx(dev, &data);

  PASS(teq(CGContextGetCTM(ctx), 1, 0, 0, 1, 0, 0),
       "the initial CTM of a bitmap context is the identity");
  CGContextTranslateCTM(ctx, 2, 3);
  PASS(teq(CGContextGetCTM(ctx), 1, 0, 0, 1, 2, 3),
       "translating the CTM moves the origin");
  CGContextScaleCTM(ctx, 2, 2);
  PASS(teq(CGContextGetCTM(ctx), 2, 0, 0, 2, 2, 3),
       "scaling the CTM scales the diagonal and keeps the translation");

  CGContextSaveGState(ctx);
  CGContextTranslateCTM(ctx, 100, 100);
  CGContextRestoreGState(ctx);
  PASS(teq(CGContextGetCTM(ctx), 2, 0, 0, 2, 2, 3),
       "restoring the graphics state restores the CTM");

  /* Clip confines a fill to the clip rect. */
  unsigned char *cdata;
  CGContextRef cctx = makeCtx(dev, &cdata);
  CGFloat green[] = {0, 1, 0, 1};
  CGColorRef gc = CGColorCreate(dev, green);
  CGContextSetFillColorWithColor(cctx, gc);
  CGContextClipToRect(cctx, CGRectMake(2, 2, 4, 4));
  CGContextFillRect(cctx, CGRectMake(0, 0, 10, 10));
  unsigned char *cd = (unsigned char *)CGBitmapContextGetData(cctx);
  int inC = (4 * 10 + 4) * 4, outC = 0;
  PASS(cd[inC] == 0 && cd[inC+1] == 255 && cd[inC+2] == 0 && cd[inC+3] == 255,
       "a pixel inside the clip rect is filled");
  PASS(cd[outC] == 0 && cd[outC+1] == 0 && cd[outC+2] == 0 && cd[outC+3] == 0,
       "a pixel outside the clip rect is untouched");

  /* Global alpha scales the fill's coverage. */
  unsigned char *adata;
  CGContextRef actx = makeCtx(dev, &adata);
  CGFloat red[] = {1, 0, 0, 1};
  CGColorRef rc = CGColorCreate(dev, red);
  CGContextSetAlpha(actx, 0.5);
  CGContextSetFillColorWithColor(actx, rc);
  CGContextFillRect(actx, CGRectMake(0, 0, 10, 10));
  unsigned char *ad = (unsigned char *)CGBitmapContextGetData(actx);
  PASS(abs((int)ad[0] - 128) <= 1 && ad[1] == 0 && ad[2] == 0
       && abs((int)ad[3] - 128) <= 1,
       "a global alpha of one half premultiplies the fill");

  CGColorRelease(gc);
  CGColorRelease(rc);
  CGContextRelease(ctx);
  CGContextRelease(cctx);
  CGContextRelease(actx);
  free(data);
  free(cdata);
  free(adata);

  END_SET("CGContext")

  CGColorSpaceRelease(dev);
  return 0;
}
