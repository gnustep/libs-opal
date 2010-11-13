#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#else
#include <CoreGraphics/CoreGraphics.h>
#endif
#define pi 3.14159265358979323846

void draw(CGContextRef ctx, CGRect r)
{
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathAddArc(path, NULL, 100, 100, 25, 0, 2 * pi, YES);
  CGPathAddArc(path, NULL, 200, 200, 50, 0, 0.8 * pi, NO);
  CGPathAddArc(path, NULL, 300, 300, 50, 1.7 * pi, 1 * pi, NO);

  CGPathMoveToPoint(path, NULL, 300, 100);
  CGPathAddCurveToPoint(path, NULL, 300, 150, 350, 100, 350, 150);
  CGPathAddCurveToPoint(path, NULL, 400, 200, 400, 200, 450, 150);
  CGContextAddPath(ctx, (CGPathRef)path);
  CGContextStrokePath(ctx);
}

