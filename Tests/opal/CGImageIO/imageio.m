/* Round-trip images through CGImageDestination and CGImageSource: encode a
   CGImage to PNG and to JPEG in memory, decode it back, and check the source
   count, type, dimensions and pixels.  PNG is lossless, so the decoded image's
   pixels must match the original exactly; JPEG is lossy, so a solid colour is
   only required to come back close to the original.  The pixels are compared
   through the images' own data providers, which sidesteps any drawing
   convention.  Expected values checked against Apple CoreGraphics/ImageIO.
   The image type identifiers are held as Foundation strings and the data
   buffers as Foundation data objects.  A divergence in the JPEG encoder is
   marked hopeful; its fix and regression are described alongside. */
#include "Testing.h"

#include <Foundation/NSData.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>

#include <CoreGraphics/CGImage.h>
#include <CoreGraphics/CGImageSource.h>
#include <CoreGraphics/CGImageDestination.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGColor.h>
#include <CoreGraphics/CGDataProvider.h>
#include <stdlib.h>

static void fill(CGContextRef c, CGColorSpaceRef dev, CGRect r,
  CGFloat red, CGFloat green, CGFloat blue)
{
  CGFloat comps[] = {red, green, blue, 1};
  CGColorRef col = CGColorCreate(dev, comps);
  CGContextSetFillColorWithColor(c, col);
  CGContextFillRect(c, r);
  CGColorRelease(col);
}

/* A 2x2 image: bottom row red|green, top row blue|white (the context's origin
   is bottom-left).  Drawn with device colours so the pixels are exact. */
static CGImageRef makeQuad(CGColorSpaceRef dev)
{
  CGContextRef c = CGBitmapContextCreate(NULL, 2, 2, 8, 8, dev,
    kCGImageAlphaPremultipliedLast);
  fill(c, dev, CGRectMake(0, 0, 1, 1), 1, 0, 0);
  fill(c, dev, CGRectMake(1, 0, 1, 1), 0, 1, 0);
  fill(c, dev, CGRectMake(0, 1, 1, 1), 0, 0, 1);
  fill(c, dev, CGRectMake(1, 1, 1, 1), 1, 1, 1);
  CGImageRef img = CGBitmapContextCreateImage(c);
  CGContextRelease(c);
  return img;
}

/* A solid w*h image of one opaque colour. */
static CGImageRef makeSolid(CGColorSpaceRef dev, int w, int h,
  CGFloat r, CGFloat g, CGFloat b)
{
  CGContextRef c = CGBitmapContextCreate(NULL, w, h, 8, w * 4, dev,
    kCGImageAlphaPremultipliedLast);
  fill(c, dev, CGRectMake(0, 0, w, h), r, g, b);
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
  if (dst == NULL) return nil;
  CGImageDestinationAddImage(dst, img, NULL);
  bool ok = CGImageDestinationFinalize(dst);
  return ok ? data : nil;
}

static NSData *pixels(CGImageRef img)
{
  return (NSData *)CGDataProviderCopyData(CGImageGetDataProvider(img));
}

int main(void)
{
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();

  START_SET("CGImageIO png")

  CGImageRef img = makeQuad(dev);
  NSData *src = pixels(img);

  NSData *png = encode(img, @"public.png");
  PASS(png != nil && [png length] > 0, "an image encodes to PNG data");

  CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)png, NULL);
  PASS(source != NULL, "PNG data creates an image source");
  PASS(CGImageSourceGetCount(source) == 1, "the PNG source holds one image");
  NSString *type = (NSString *)CGImageSourceGetType(source);
  PASS([type isEqualToString: @"public.png"],
       "the source reports the PNG type");

  CGImageRef back = CGImageSourceCreateImageAtIndex(source, 0, NULL);
  PASS(back != NULL, "the PNG source decodes its image");
  PASS(CGImageGetWidth(back) == 2 && CGImageGetHeight(back) == 2,
       "the decoded PNG has the original size");

  /* PNG is lossless: the four opaque pixels must come back unchanged. */
  NSData *out = pixels(back);
  PASS([out isEqualToData: src],
       "PNG round-trip preserves every pixel");

  CGImageRelease(back);
  CGImageRelease(img);

  END_SET("CGImageIO png")

  START_SET("CGImageIO jpeg")

  CGImageRef img = makeSolid(dev, 8, 8, 200/255.0, 40/255.0, 40/255.0);

  NSData *jpg = encode(img, @"public.jpeg");
  PASS(jpg != nil && [jpg length] > 0, "an image encodes to JPEG data");

  CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)jpg, NULL);
  PASS(source != NULL, "JPEG data creates an image source");
  PASS(CGImageSourceGetCount(source) == 1, "the JPEG source holds one image");
  NSString *type = (NSString *)CGImageSourceGetType(source);
  PASS([type isEqualToString: @"public.jpeg"],
       "the source reports the JPEG type");

  CGImageRef back = CGImageSourceCreateImageAtIndex(source, 0, NULL);
  PASS(back != NULL, "the JPEG source decodes its image");
  PASS(CGImageGetWidth(back) == 8 && CGImageGetHeight(back) == 8,
       "the decoded JPEG has the original size");

  /* JPEG is lossy: the solid colour must come back close to the original.
     The encoder must feed libjpeg packed colour samples with the alpha channel
     stripped; when it instead passes the raw RGBA rows to a three-component
     compressor the samples are read misaligned and every colour is corrupted.
     Sample the first pixel of the decoded (RGB or RGBA) image. */
  NSData *out = pixels(back);
  const unsigned char *p = [out bytes];
  int bpp = CGImageGetBitsPerPixel(back) / 8;
  testHopeful = YES;
  PASS(bpp >= 3 && abs((int)p[0] - 200) < 30 && abs((int)p[1] - 40) < 30
       && abs((int)p[2] - 40) < 30,
       "JPEG round-trip returns approximately the original colour");
  testHopeful = NO;

  CGImageRelease(back);
  CGImageRelease(img);

  END_SET("CGImageIO jpeg")

  START_SET("CGImageIO types")

  NSArray *dtypes = (NSArray *)CGImageDestinationCopyTypeIdentifiers();
  PASS([dtypes containsObject: @"public.png"],
       "PNG is an available destination type");
  PASS([dtypes containsObject: @"public.jpeg"],
       "JPEG is an available destination type");

  NSArray *stypes = (NSArray *)CGImageSourceCopyTypeIdentifiers();
  PASS([stypes containsObject: @"public.png"],
       "PNG is an available source type");
  PASS([stypes containsObject: @"public.jpeg"],
       "JPEG is an available source type");

  END_SET("CGImageIO types")

  CGColorSpaceRelease(dev);
  return 0;
}
