/* CGImageSourceCopyPropertiesAtIndex reports an encoded image's metadata:
   pixel width and height, bits per component (Depth), colour model and, for
   formats that carry it, whether the image has alpha.  A PNG and a JPEG are
   generated in memory and their properties are read back.  Keys and values
   match Apple CoreGraphics.  The dictionaries are Foundation dictionaries. */
#include "Testing.h"

#include <Foundation/NSData.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSString.h>

#include <CoreGraphics/CGImage.h>
#include <CoreGraphics/CGImageSource.h>
#include <CoreGraphics/CGImageDestination.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGColor.h>

/* A solid green w*h image drawn with device colours. */
static CGImageRef makeImage(CGColorSpaceRef dev, int w, int h)
{
  CGContextRef c = CGBitmapContextCreate(NULL, w, h, 8, w*4, dev,
    kCGImageAlphaPremultipliedLast);
  CGFloat green[] = {0, 1, 0, 1};
  CGColorRef col = CGColorCreate(dev, green);
  CGContextSetFillColorWithColor(c, col);
  CGContextFillRect(c, CGRectMake(0, 0, w, h));
  CGColorRelease(col);
  CGImageRef img = CGBitmapContextCreateImage(c);
  CGContextRelease(c);
  return img;
}

static NSData *encode(CGImageRef img, NSString *type)
{
  NSMutableData *data = [NSMutableData data];
  CGImageDestinationRef dst =
    CGImageDestinationCreateWithData((CFMutableDataRef)data,
      (CFStringRef)type, 1, NULL);
  CGImageDestinationAddImage(dst, img, NULL);
  CGImageDestinationFinalize(dst);
  return data;
}

static NSDictionary *propsFor(NSData *data)
{
  CGImageSourceRef src = CGImageSourceCreateWithData((CFDataRef)data, NULL);
  return (NSDictionary *)CGImageSourceCopyPropertiesAtIndex(src, 0, NULL);
}

int main(void)
{
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();

  START_SET("CGImageSource PNG properties")

  NSData *png = encode(makeImage(dev, 3, 5), @"public.png");
  NSDictionary *p = propsFor(png);
  PASS(p != nil && [p count] > 0, "PNG properties are returned");
  PASS([[p objectForKey: (NSString*)kCGImagePropertyPixelWidth] intValue] == 3,
       "the PNG pixel width is reported");
  PASS([[p objectForKey: (NSString*)kCGImagePropertyPixelHeight] intValue] == 5,
       "the PNG pixel height is reported");
  PASS([[p objectForKey: (NSString*)kCGImagePropertyDepth] intValue] == 8,
       "the PNG bit depth is reported");
  PASS([[p objectForKey: (NSString*)kCGImagePropertyColorModel]
         isEqual: (NSString*)kCGImagePropertyColorModelRGB],
       "the PNG colour model is RGB");
  PASS([[p objectForKey: (NSString*)kCGImagePropertyHasAlpha] boolValue] == YES,
       "the PNG reports that it has alpha");

  END_SET("CGImageSource PNG properties")

  START_SET("CGImageSource JPEG properties")

  NSData *jpg = encode(makeImage(dev, 7, 4), @"public.jpeg");
  NSDictionary *p = propsFor(jpg);
  PASS([[p objectForKey: (NSString*)kCGImagePropertyPixelWidth] intValue] == 7,
       "the JPEG pixel width is reported");
  PASS([[p objectForKey: (NSString*)kCGImagePropertyPixelHeight] intValue] == 4,
       "the JPEG pixel height is reported");
  PASS([[p objectForKey: (NSString*)kCGImagePropertyDepth] intValue] == 8,
       "the JPEG bit depth is reported");
  PASS([[p objectForKey: (NSString*)kCGImagePropertyColorModel]
         isEqual: (NSString*)kCGImagePropertyColorModelRGB],
       "the JPEG colour model is RGB");

  END_SET("CGImageSource JPEG properties")

  CGColorSpaceRelease(dev);
  return 0;
}
