/* CGImageCreateCopyWithColorSpace re-tags a bitmap image with a new colour
   space of the same number of components, keeping the pixel data: the copy has
   the original dimensions and bit depth, reports the new colour space, and
   draws to the same pixels (CoreGraphics does not convert the pixel data).  It
   returns NULL when the component counts differ or the image is a mask.
   Behaviour checked against Apple CoreGraphics. */
#include "Testing.h"

#include <CoreGraphics/CGImage.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGContext.h>
#include <stdlib.h>

static CGImageRef rgbImage(CGColorSpaceRef dev)
{
  CGContextRef c = CGBitmapContextCreate(NULL, 2, 2, 8, 8, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextSetRGBFillColor(c, 200/255.0, 100/255.0, 50/255.0, 1);
  CGContextFillRect(c, CGRectMake(0, 0, 2, 2));
  CGImageRef img = CGBitmapContextCreateImage(c);
  CGContextRelease(c);
  return img;
}

static void firstPixel(CGImageRef img, CGColorSpaceRef dev, unsigned char out[4])
{
  unsigned char *b = calloc(2*2*4, 1);
  CGContextRef c = CGBitmapContextCreate(b, 2, 2, 8, 8, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextDrawImage(c, CGRectMake(0, 0, 2, 2), img);
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(c);
  out[0]=d[0]; out[1]=d[1]; out[2]=d[2]; out[3]=d[3];
  CGContextRelease(c); free(b);
}

int main(void)
{
  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();
  CGColorSpaceRef srgb = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
  CGColorSpaceRef gray = CGColorSpaceCreateDeviceGray();

  START_SET("CGImageCreateCopyWithColorSpace")

  CGImageRef img = rgbImage(dev);

  CGImageRef copy = CGImageCreateCopyWithColorSpace(img, srgb);
  PASS(copy != NULL, "copying to a same-component colour space succeeds");
  PASS(CGImageGetWidth(copy) == 2 && CGImageGetHeight(copy) == 2,
       "the copy keeps the dimensions");
  PASS(CGImageGetBitsPerComponent(copy) == 8,
       "the copy keeps the bit depth");
  PASS(CGColorSpaceGetModel(CGImageGetColorSpace(copy)) == kCGColorSpaceModelRGB,
       "the copy reports a colour space");

  unsigned char a[4], b[4];
  firstPixel(img, dev, a);
  firstPixel(copy, dev, b);
  PASS(a[0]==b[0] && a[1]==b[1] && a[2]==b[2] && a[3]==b[3],
       "the pixel data is unchanged (not converted)");

  CGImageRef toGray = CGImageCreateCopyWithColorSpace(img, gray);
  PASS(toGray == NULL,
       "copying to a colour space with a different component count returns NULL");

  END_SET("CGImageCreateCopyWithColorSpace")

  CGColorSpaceRelease(dev);
  return 0;
}
