#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#else
#include <CoreGraphics/CoreGraphics.h>
#endif

#include <Foundation/Foundation.h>

#ifndef MIN
#define MIN(x,y) ((x)<(y)?(x):(y))
#endif

void draw(CGContextRef ctx, CGRect rect)
{
  CGContextSetRGBFillColor(ctx, 0.6, 0.6, 0.6, 1.0);
  CGContextFillRect(ctx, rect);
  
  // Draw a checkerboard
  CGContextSetRGBFillColor(ctx, 0.4, 0.4, 0.4, 1.0);
	unsigned int x, y;
	for (x=0; x<rect.size.width; x+=10)
	{
		for (y=0; y<rect.size.height; y+=10)
		{
			if (((x % 20) == 0) != ((y % 20) == 0))
			{
  			CGContextFillRect(ctx,  CGRectMake(x, y, 10, 10));
			}
  	}	
  }
  
  CGDataProviderRef pngData = CGDataProviderCreateWithFilename("test.png");
  CGImageRef png = CGImageCreateWithPNGDataProvider(pngData, NULL, YES, kCGRenderingIntentDefault);
  CGDataProviderRelease(pngData);
  CGRect pngRect = CGRectMake(0,0,rect.size.width/2,rect.size.height);
  CGContextDrawImage(ctx, pngRect, png);
  CGImageRelease(png);
    
  CGDataProviderRef jpegData = CGDataProviderCreateWithFilename("test.jpg");
  CGImageRef jpeg = CGImageCreateWithJPEGDataProvider(jpegData, NULL, YES, kCGRenderingIntentDefault);
  CGDataProviderRelease(jpegData);
  CGRect jpegRect = CGRectMake(rect.size.width/2,0,rect.size.width/2, rect.size.height);
  CGContextDrawImage(ctx, jpegRect, jpeg);
  CGImageRelease(jpeg);
}
