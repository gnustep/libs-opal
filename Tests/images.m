#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#else
#include <CoreGraphics/CoreGraphics.h>
#endif
#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>

void draw(CGContextRef ctx, CGRect rect)
{
  CGContextSetRGBFillColor(ctx, 0.5, 0.5, 0.5, 1.0);
  CGContextFillRect(ctx, rect);
  
  CGDataProviderRef pngData = CGDataProviderCreateWithFilename([[[NSBundle mainBundle] pathForResource: @"test" ofType: @"png"] UTF8String]);
  CGImageRef png = CGImageCreateWithPNGDataProvider(pngData, NULL, YES, kCGRenderingIntentDefault);
  CGRect pngRect = CGRectMake(0,0,rect.size.width/2, rect.size.height);
  CGContextDrawImage(ctx, pngRect, png);
  CGDataProviderRelease(pngData);
  CGImageRelease(png);
    
  CGDataProviderRef jpegData = CGDataProviderCreateWithFilename([[[NSBundle mainBundle] pathForResource: @"test" ofType: @"jpg"] UTF8String]);
  CGImageRef jpeg = CGImageCreateWithJPEGDataProvider(jpegData, NULL, YES, kCGRenderingIntentDefault);
  CGRect jpegRect = CGRectMake(rect.size.width/2,0,rect.size.width/2, rect.size.height);
  CGContextDrawImage(ctx, jpegRect, jpeg);
  CGDataProviderRelease(jpegData);
  CGImageRelease(jpeg);
}
