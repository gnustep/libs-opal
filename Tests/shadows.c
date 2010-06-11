#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#else
#include <CoreGraphics/CoreGraphics.h>
#endif

#define pi 3.14159265358979323846

void draw(CGContextRef ctx, CGRect r)
{
  CGContextSetRGBFillColor(ctx, 0, 0, 1, 0.5);
  CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);
  CGContextFillRect(ctx, CGRectMake(10,10,r.size.width - 20, r.size.height - 20));
  CGContextStrokeRect(ctx, CGRectMake(10,10,r.size.width - 20, r.size.height - 20));
   
  CGContextSetShadow(ctx, CGSizeMake(3.0,3.0), 2.0);

  // Draw some rotated, shadowed squares
  CGContextSetRGBFillColor(ctx, 0, 1, 0.5, 1);
  CGContextSaveGState(ctx);
  CGContextTranslateCTM(ctx, 225, 125);
  int i;
  for (i = 0; i < 2; i++) {
    CGContextRotateCTM(ctx, 0.4);
    CGContextFillRect(ctx, CGRectMake(-50,-50,100,100));
  }
  CGContextRestoreGState(ctx);
  
  CGContextSetRGBFillColor(ctx, 1, 0, 0.5, 1);
  CGContextFillRect(ctx, CGRectMake(10, 200, 50, 15));
  CGContextFillRect(ctx, CGRectMake(10, 10, 15, 75));
  CGContextFillRect(ctx, CGRectMake(400, 10, 35, 35));
}
