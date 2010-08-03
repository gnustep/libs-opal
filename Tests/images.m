#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#else
#include <CoreGraphics/CoreGraphics.h>
#endif

#include <Foundation/Foundation.h>

#ifndef MIN
#define MIN(x,y) ((x)<(y)?(x):(y))
#endif

static CGImageRef png, jpeg, tiff;

void draw(CGContextRef ctx, CGRect rect)
{
  CGContextSetRGBFillColor(ctx, 0.45, 0.45, 0.45, 1.0);
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
  
  if (nil == png)
  {
    CGDataProviderRef pngData = CGDataProviderCreateWithFilename("test.png");
    png = CGImageCreateWithPNGDataProvider(pngData, NULL, YES, kCGRenderingIntentDefault);
    CGDataProviderRelease(pngData);
  }

  CGRect pngRect = CGRectMake(0,0,rect.size.width/3,rect.size.height);
  CGContextDrawImage(ctx, pngRect, png);
   
  if (nil == jpeg)
  { 
    CGDataProviderRef jpegData = CGDataProviderCreateWithFilename("test.jpg");
    jpeg = CGImageCreateWithJPEGDataProvider(jpegData, NULL, YES, kCGRenderingIntentDefault);
    CGDataProviderRelease(jpegData);
  }

  CGRect jpegRect = CGRectMake(rect.size.width/3,0,rect.size.width/3, rect.size.height);
  CGContextDrawImage(ctx, jpegRect, jpeg);

  if (nil == tiff)
  { 
    CGDataProviderRef tiffData = CGDataProviderCreateWithFilename("test.tiff");
    CGImageSourceRef tiffSource = CGImageSourceCreateWithDataProvider(tiffData, nil);
    
    tiff = CGImageSourceCreateImageAtIndex(tiffSource, 0, nil);

    CGDataProviderRelease(tiffData);
    [tiffSource release];
  }

  CGRect tiffRect = CGRectMake((2*rect.size.width)/3,0,rect.size.width/3, rect.size.height);
  CGContextDrawImage(ctx, tiffRect, tiff);
}
