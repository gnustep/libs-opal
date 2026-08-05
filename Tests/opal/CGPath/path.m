/* CGPath construction, bounding boxes, current point, containment, emptiness,
   equality, and filling a path into a bitmap context.  Expected values checked
   against Apple CoreGraphics. */
#include "Testing.h"

#include <CoreGraphics/CGPath.h>
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

static BOOL req(CGRect r, CGFloat x, CGFloat y, CGFloat w, CGFloat h)
{
  return eqf(r.origin.x, x) && eqf(r.origin.y, y)
      && eqf(r.size.width, w) && eqf(r.size.height, h);
}

int main(void)
{
  START_SET("CGPath")

  CGMutablePathRef empty = CGPathCreateMutable();
  PASS(CGPathIsEmpty(empty), "a new path is empty");

  CGMutablePathRef rect = CGPathCreateMutable();
  CGPathAddRect(rect, NULL, CGRectMake(10, 20, 30, 40));
  PASS(!CGPathIsEmpty(rect), "a path with a rect is not empty");
  PASS(req(CGPathGetBoundingBox(rect), 10, 20, 30, 40),
       "the bounding box of a rect path is the rect");
  PASS(req(CGPathGetPathBoundingBox(rect), 10, 20, 30, 40),
       "the path bounding box of a rect path is the rect");
  CGPoint cur = CGPathGetCurrentPoint(rect);
  testHopeful = YES;
  PASS(eqf(cur.x, 10) && eqf(cur.y, 20),
       "the current point after adding a rect is the rect origin");
  testHopeful = NO;
  PASS(CGPathContainsPoint(rect, NULL, CGPointMake(15, 30), false),
       "a point inside the rect is contained");
  PASS(!CGPathContainsPoint(rect, NULL, CGPointMake(5, 5), false),
       "a point outside the rect is not contained");

  CGMutablePathRef line = CGPathCreateMutable();
  CGPathMoveToPoint(line, NULL, 5, 5);
  CGPathAddLineToPoint(line, NULL, 15, 25);
  cur = CGPathGetCurrentPoint(line);
  PASS(eqf(cur.x, 15) && eqf(cur.y, 25),
       "the current point is the last line endpoint");
  PASS(req(CGPathGetBoundingBox(line), 5, 5, 10, 20),
       "the bounding box spans the line");

  CGMutablePathRef curve = CGPathCreateMutable();
  CGPathMoveToPoint(curve, NULL, 0, 0);
  CGPathAddCurveToPoint(curve, NULL, 0, 100, 100, 100, 100, 0);
  PASS(req(CGPathGetBoundingBox(curve), 0, 0, 100, 100),
       "the bounding box includes the curve control points");
  testHopeful = YES;
  PASS(req(CGPathGetPathBoundingBox(curve), 0, 0, 100, 75),
       "the path bounding box is the tight bounds of the curve");
  testHopeful = NO;

  CGMutablePathRef rect2 = CGPathCreateMutable();
  CGPathAddRect(rect2, NULL, CGRectMake(10, 20, 30, 40));
  PASS(CGPathEqualToPath(rect, rect2) && !CGPathEqualToPath(rect, line),
       "equal paths compare equal and different paths do not");

  /* Rendering: fill a rect path green and sample inside and outside. */
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();
  unsigned char *data = calloc(10 * 10 * 4, 1);
  CGContextRef ctx = CGBitmapContextCreate(data, 10, 10, 8, 40, dev,
    kCGImageAlphaPremultipliedLast);
  CGFloat gc[] = {0.0, 1.0, 0.0, 1.0};
  CGColorRef green = CGColorCreate(dev, gc);
  CGContextSetFillColorWithColor(ctx, green);
  CGMutablePathRef fillp = CGPathCreateMutable();
  CGPathAddRect(fillp, NULL, CGRectMake(2, 2, 4, 4));
  CGContextAddPath(ctx, fillp);
  CGContextFillPath(ctx);
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(ctx);
  int in = (4 * 10 + 4) * 4;
  int out = (0 * 10 + 0) * 4;
  PASS(d[in] == 0 && d[in + 1] == 255 && d[in + 2] == 0 && d[in + 3] == 255,
       "a pixel inside the filled path is the fill colour");
  PASS(d[out] == 0 && d[out + 1] == 0 && d[out + 2] == 0 && d[out + 3] == 0,
       "a pixel outside the filled path is untouched");

  CGColorRelease(green);
  CGContextRelease(ctx);
  CGColorSpaceRelease(dev);
  free(data);
  CGPathRelease(empty);
  CGPathRelease(rect);
  CGPathRelease(rect2);
  CGPathRelease(line);
  CGPathRelease(curve);
  CGPathRelease(fillp);

  END_SET("CGPath")
  return 0;
}
