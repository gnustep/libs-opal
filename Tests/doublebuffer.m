#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#else
#include <CoreGraphics/CoreGraphics.h>
#endif

#include <Foundation/Foundation.h>

/* Taken from GSQuartzCore's CABackingStore */
static CGContextRef createCGBitmapContext(int pixelsWide,
                                          int pixelsHigh)
{
  CGContextRef    context = NULL;
  CGColorSpaceRef colorSpace;
  int             bitmapBytesPerRow;

  bitmapBytesPerRow = (pixelsWide * 4);

  colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

  // Let CGBitmapContextCreate() allocate the memory.
  // This should be good under Cocoa too.
  context = CGBitmapContextCreate(NULL,
                                  pixelsWide,
                                  pixelsHigh,
                                  8,      // bits per component
                                  bitmapBytesPerRow,
                                  colorSpace,
                                  kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);

  // Note: our use of premultiplied alpha means that we need to
  // do alpha blending using:
  //  GL_SRC_ALPHA, GL_ONE

  CGColorSpaceRelease(colorSpace);
  if (context == NULL)
    {
      NSLog(@"Context not created!");
      return NULL;
    }
  return context;
}

void draw_red(CGContextRef ctx, CGRect rect)
{
  const CGFloat r = 0.9;
  const CGFloat g = 0.0;
  const CGFloat b = 0.0;
  const CGFloat a = 0.7;


  CGContextSetRGBFillColor(ctx, r, g, b, a);
  CGContextFillRect(ctx, rect);

} 

void draw(CGContextRef ctx, CGRect rect)
{
  CGContextRef ctx1 = createCGBitmapContext(rect.size.width,
                                            rect.size.height);
  draw_red(ctx1, rect);

  CGImageRef backingImage = CGBitmapContextCreateImage(ctx1);

  CGContextDrawImage(ctx, rect, backingImage);
} 


