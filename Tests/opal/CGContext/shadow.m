/* CGContextSetShadow and CGContextSetShadowWithColor.  Expected values
   checked against Apple CoreGraphics on a macOS runner: a filled path's
   shadow covers that path moved by the offset and grown by the radius on
   every side, it is drawn in the colour that was set, and it is drawn
   wherever in the context the path is.  CGContextSetShadow uses black at one
   third alpha.

   Every case puts the offset further to the right than the path is wide, so
   the shadow and the path fall in different halves of the context and can be
   measured apart.  Colour is not used to tell them apart: a shadow fades out
   to an alpha of 1, where the premultiplied colour rounds to zero and reads
   as black whatever colour it was given.

   Which way user space y runs in the buffer is measured here rather than
   assumed, so the offset can be asserted with its sign either way. */
#include "Testing.h"

#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGColor.h>
#include <CoreGraphics/CGGeometry.h>
#include <stdlib.h>

#define OFFSET 60

typedef struct
{
  int x0, y0, x1, y1, count;
} Box;

static CGContextRef makeCtx(CGColorSpaceRef dev, int w, int h,
                            unsigned char **data)
{
  *data = calloc(w * h * 4, 1);
  return CGBitmapContextCreate(*data, w, h, 8, w * 4, dev,
                               kCGImageAlphaPremultipliedLast);
}

/* What has been drawn so far.  Reading the buffer that was handed to
   CGBitmapContextCreate is not enough: what is drawn reaches it only once
   the context has been asked for it. */
static unsigned char *pixels(CGContextRef ctx)
{
  return (unsigned char *)CGBitmapContextGetData(ctx);
}

/* The box of pixels with any coverage at all, within the columns given. */
static Box boxOf(unsigned char *d, int w, int h, int fromX, int toX)
{
  Box b = { w, h, -1, -1, 0 };
  int x, y;

  for (y = 0; y < h; y++)
    for (x = fromX; x < toX; x++)
      {
        unsigned char *p = d + (y * w + x) * 4;

        if (p[3] > 0)
          {
            b.count++;
            if (x < b.x0) b.x0 = x;
            if (x > b.x1) b.x1 = x;
            if (y < b.y0) b.y0 = y;
            if (y > b.y1) b.y1 = y;
          }
      }
  return b;
}

static void black(CGContextRef ctx, CGColorSpaceRef dev)
{
  CGFloat c[] = { 0, 0, 0, 1 };
  CGColorRef color = CGColorCreate(dev, c);

  CGContextSetFillColorWithColor(ctx, color);
  CGContextSetStrokeColorWithColor(ctx, color);
  CGColorRelease(color);
}

int main(void)
{
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();
  CGFloat whiteComponents[] = { 1, 1, 1, 1 };
  CGColorRef white = CGColorCreate(dev, whiteComponents);

  START_SET("CGContext shadow")

  unsigned char *data;
  CGContextRef ctx;
  Box fill, shadow;
  int yStep;

  /* Which row a rect at the bottom of user space lands in.  If it lands in
     the last rows then user space y runs the opposite way to the rows, and a
     positive offset moves the shadow towards row zero. */
  ctx = makeCtx(dev, 40, 40, &data);
  black(ctx, dev);
  CGContextFillRect(ctx, CGRectMake(0, 0, 40, 8));
  fill = boxOf(pixels(ctx), 40, 40, 0, 40);
  yStep = fill.y0 >= 20 ? -1 : 1;
  CGContextRelease(ctx);
  free(data);

  /* A shadow with no blur is the path moved by the offset. */
  ctx = makeCtx(dev, 200, 200, &data);
  black(ctx, dev);
  CGContextSetShadowWithColor(ctx, CGSizeMake(OFFSET, OFFSET), 0, white);
  CGContextFillRect(ctx, CGRectMake(70, 70, 40, 40));
  fill = boxOf(pixels(ctx), 200, 200, 0, 120);
  shadow = boxOf(pixels(ctx), 200, 200, 120, 200);

  PASS(shadow.count > 0, "a filled rect casts a shadow");
  PASS(shadow.x1 - shadow.x0 == fill.x1 - fill.x0
       && shadow.y1 - shadow.y0 == fill.y1 - fill.y0,
       "a shadow with a radius of 0 is the same size as what casts it");
  PASS(shadow.x0 - fill.x0 == OFFSET
       && shadow.y0 - fill.y0 == OFFSET * yStep,
       "and sits at the offset it was given");
  {
    int x = (shadow.x0 + shadow.x1) / 2;
    int y = (shadow.y0 + shadow.y1) / 2;
    unsigned char *p = pixels(ctx) + (y * 200 + x) * 4;

    PASS(p[0] == 255 && p[1] == 255 && p[2] == 255 && p[3] == 255,
         "a shadow is drawn in the colour it was given");
  }
  CGContextRelease(ctx);
  free(data);

  /* The radius grows the shadow by that much on every side. */
  ctx = makeCtx(dev, 200, 200, &data);
  black(ctx, dev);
  CGContextSetShadowWithColor(ctx, CGSizeMake(OFFSET, OFFSET), 5, white);
  CGContextFillRect(ctx, CGRectMake(70, 70, 40, 40));
  fill = boxOf(pixels(ctx), 200, 200, 0, 120);
  shadow = boxOf(pixels(ctx), 200, 200, 120, 200);

  PASS(shadow.count > 0
       && shadow.x1 - shadow.x0 == (fill.x1 - fill.x0) + 10,
       "a radius of 5 grows the shadow by 5 on each side");
  PASS(shadow.count > 0
       && shadow.y1 - shadow.y0 == (fill.y1 - fill.y0) + 10,
       "in both directions");
  CGContextRelease(ctx);
  free(data);

  /* Far from the origin, past any fixed-size intermediate buffer. */
  ctx = makeCtx(dev, 600, 600, &data);
  black(ctx, dev);
  CGContextSetShadowWithColor(ctx, CGSizeMake(OFFSET, OFFSET), 0, white);
  CGContextFillRect(ctx, CGRectMake(450, 450, 40, 40));
  shadow = boxOf(pixels(ctx), 600, 600, 500, 600);

  PASS(shadow.count > 0,
       "a rect far from the origin casts a shadow as well");
  PASS(shadow.count == 1600,
       "and the whole of it is drawn");
  CGContextRelease(ctx);
  free(data);

  /* CGContextSetShadow's own colour. */
  ctx = makeCtx(dev, 200, 200, &data);
  black(ctx, dev);
  CGContextSetShadow(ctx, CGSizeMake(OFFSET, OFFSET), 0);
  CGContextFillRect(ctx, CGRectMake(70, 70, 40, 40));
  shadow = boxOf(pixels(ctx), 200, 200, 120, 200);
  {
    int x = (shadow.x0 + shadow.x1) / 2;
    int y = (shadow.y0 + shadow.y1) / 2;
    unsigned char *p = pixels(ctx) + (y * 200 + x) * 4;

    PASS(p[0] == 0 && p[1] == 0 && p[2] == 0 && p[3] >= 84 && p[3] <= 86,
         "CGContextSetShadow draws black at one third alpha");
  }
  CGContextRelease(ctx);
  free(data);

  /* A stroke casts one too. */
  ctx = makeCtx(dev, 200, 200, &data);
  black(ctx, dev);
  CGContextSetShadowWithColor(ctx, CGSizeMake(OFFSET, OFFSET), 0, white);
  CGContextSetLineWidth(ctx, 4);
  CGContextBeginPath(ctx);
  CGContextAddRect(ctx, CGRectMake(70, 70, 40, 40));
  CGContextStrokePath(ctx);
  shadow = boxOf(pixels(ctx), 200, 200, 120, 200);
  PASS(shadow.count > 0, "a stroked path casts a shadow");
  CGContextRelease(ctx);
  free(data);

  /* The shadow belongs to the graphics state. */
  ctx = makeCtx(dev, 200, 200, &data);
  black(ctx, dev);
  CGContextSaveGState(ctx);
  CGContextSetShadowWithColor(ctx, CGSizeMake(OFFSET, OFFSET), 0, white);
  CGContextRestoreGState(ctx);
  CGContextFillRect(ctx, CGRectMake(70, 70, 40, 40));
  shadow = boxOf(pixels(ctx), 200, 200, 120, 200);
  PASS(shadow.count == 0,
       "a shadow set inside a saved state is gone once it is restored");
  CGContextRelease(ctx);
  free(data);

  /* A NULL colour turns it off as well. */
  ctx = makeCtx(dev, 200, 200, &data);
  black(ctx, dev);
  CGContextSetShadowWithColor(ctx, CGSizeMake(OFFSET, OFFSET), 0, white);
  CGContextSetShadowWithColor(ctx, CGSizeMake(OFFSET, OFFSET), 0, NULL);
  CGContextFillRect(ctx, CGRectMake(70, 70, 40, 40));
  shadow = boxOf(pixels(ctx), 200, 200, 120, 200);
  PASS(shadow.count == 0, "a shadow given no colour is not drawn");
  CGContextRelease(ctx);
  free(data);

  END_SET("CGContext shadow")

  CGColorRelease(white);
  CGColorSpaceRelease(dev);
  return 0;
}
