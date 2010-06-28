#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#else
#include <CoreGraphics/CoreGraphics.h>
#endif
#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>

#define MIN(x,y) ((x)<(y)?(x):(y))

static CGImageRef png;

void draw(CGContextRef ctx, CGRect rect)
{
//  CGContextSetRGBFillColor(ctx, 0.5, 0.5, 0.5, 1.0);
//  CGContextFillRect(ctx, rect);
  
  if (!png)
  {
    CGDataProviderRef pngData = CGDataProviderCreateWithFilename("test.png");
    png = CGImageCreateWithPNGDataProvider(pngData, NULL, YES, kCGRenderingIntentDefault);
    CGDataProviderRelease(pngData);
  }
  
  CGRect pngRect = CGRectMake(0,0,rect.size.width,rect.size.height);
  CGContextDrawImage(ctx, pngRect, png);
  
  
  //CGImageRelease(png);
    
  /*CGDataProviderRef jpegData = CGDataProviderCreateWithFilename("test.jpg");
  CGImageRef jpeg = CGImageCreateWithJPEGDataProvider(jpegData, NULL, YES, kCGRenderingIntentDefault);
  CGRect jpegRect = CGRectMake(rect.size.width/2,0,rect.size.width/2, rect.size.height);
  CGContextDrawImage(ctx, jpegRect, jpeg);
  CGDataProviderRelease(jpegData);
  CGImageRelease(jpeg);*/
}
