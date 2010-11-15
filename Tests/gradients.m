#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#else
#include <CoreGraphics/CoreGraphics.h>
#endif

#include <Foundation/Foundation.h>
#include <assert.h>


void draw(CGContextRef ctx, CGRect rect)
{
  CGContextScaleCTM(ctx, rect.size.width, rect.size.height);
  
CGGradientRef myGradient;
CGColorSpaceRef myColorspace;
size_t num_locations = 2;
CGFloat locations[2] = { 0.0, 1.0 };
CGFloat components[8] = { 1.0, 0.5, 0.4, 1.0,  // Start color
                          0.8, 0.8, 0.3, 1.0 }; // End color
 
myColorspace = CGColorSpaceCreateDeviceRGB();
myGradient = CGGradientCreateWithColorComponents (myColorspace, components,
                          locations, num_locations);


CGPoint myStartPoint, myEndPoint;
CGFloat myStartRadius, myEndRadius;
myStartPoint.x = 0.15;
myStartPoint.y = 0.15;
myEndPoint.x = 0.5;
myEndPoint.y = 0.5;
myStartRadius = 0.1;
myEndRadius = 0.25;
CGContextDrawRadialGradient (ctx, myGradient, myStartPoint,
                         myStartRadius, myEndPoint, myEndRadius,
                         kCGGradientDrawsAfterEndLocation);
{            
CGPoint myStartPoint, myEndPoint;
myStartPoint.x = 0.0;
myStartPoint.y = 0.0;
myEndPoint.x = 1.0;
myEndPoint.y = 1.0;
CGContextDrawLinearGradient (ctx, myGradient, myStartPoint, myEndPoint, 0);
}
}
