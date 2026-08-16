/* CGImage metadata from a bitmap context, drawing the image back into a
   context, and cropping a sub-image.  Expected values checked against Apple
   CoreGraphics on a macOS runner. */
#include "Testing.h"

#include <CoreGraphics/CGImage.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGColor.h>
#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <stdlib.h>

int main(void)
{
  START_SET("CGImage")

  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();

  /* A 2x2 green image, for metadata and drawing. */
  unsigned char *src = calloc(2 * 2 * 4, 1);
  CGContextRef sctx = CGBitmapContextCreate(src, 2, 2, 8, 8, dev,
    kCGImageAlphaPremultipliedLast);
  CGFloat g[] = {0, 1, 0, 1};
  CGColorRef green = CGColorCreate(dev, g);
  CGContextSetFillColorWithColor(sctx, green);
  CGContextFillRect(sctx, CGRectMake(0, 0, 2, 2));

  CGImageRef img = CGBitmapContextCreateImage(sctx);
  PASS(img != NULL, "creating an image from a bitmap context returns an image");
  PASS(CGImageGetWidth(img) == 2 && CGImageGetHeight(img) == 2,
       "the image has the bitmap's width and height");
  PASS(CGImageGetBitsPerComponent(img) == 8,
       "the image has 8 bits per component");
  PASS(CGImageGetBitsPerPixel(img) == 32,
       "the image has 32 bits per pixel");
  PASS(CGImageGetBytesPerRow(img) == 8,
       "the image has 8 bytes per row");
  PASS(CGImageGetAlphaInfo(img) == kCGImageAlphaPremultipliedLast,
       "the image reports premultiplied-last alpha");
  PASS(!CGImageIsMask(img), "the image is not a mask");
  PASS(CGColorSpaceGetModel(CGImageGetColorSpace(img)) == kCGColorSpaceModelRGB,
       "the image reports the RGB colour space model");

  unsigned char *dst = calloc(2 * 2 * 4, 1);
  CGContextRef dctx = CGBitmapContextCreate(dst, 2, 2, 8, 8, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextDrawImage(dctx, CGRectMake(0, 0, 2, 2), img);
  unsigned char *d = (unsigned char *)CGBitmapContextGetData(dctx);
  PASS(d[0] == 0 && d[1] == 255 && d[2] == 0 && d[3] == 255,
       "drawing the image reproduces its pixels");

  /* A 2x1 red|blue image, to crop the right (blue) pixel and check the
     sub-image reports the crop size and draws the cropped region. */
  unsigned char *rb = calloc(2 * 1 * 4, 1);
  CGContextRef rbctx = CGBitmapContextCreate(rb, 2, 1, 8, 8, dev,
    kCGImageAlphaPremultipliedLast);
  CGFloat redc[] = {1, 0, 0, 1};
  CGFloat bluec[] = {0, 0, 1, 1};
  CGColorRef red = CGColorCreate(dev, redc);
  CGColorRef blue = CGColorCreate(dev, bluec);
  CGContextSetFillColorWithColor(rbctx, red);
  CGContextFillRect(rbctx, CGRectMake(0, 0, 1, 1));
  CGContextSetFillColorWithColor(rbctx, blue);
  CGContextFillRect(rbctx, CGRectMake(1, 0, 1, 1));
  CGImageRef rbimg = CGBitmapContextCreateImage(rbctx);

  CGImageRef sub = CGImageCreateWithImageInRect(rbimg, CGRectMake(1, 0, 1, 1));
  testHopeful = YES;
  PASS(CGImageGetWidth(sub) == 1 && CGImageGetHeight(sub) == 1,
       "a sub-image reports the crop rect size");
  testHopeful = NO;

  unsigned char *subdst = calloc(1 * 1 * 4, 1);
  CGContextRef subctx = CGBitmapContextCreate(subdst, 1, 1, 8, 4, dev,
    kCGImageAlphaPremultipliedLast);
  CGContextDrawImage(subctx, CGRectMake(0, 0, 1, 1), sub);
  unsigned char *sd = (unsigned char *)CGBitmapContextGetData(subctx);
  PASS(sd[0] < 60 && sd[2] > 200 && sd[3] == 255,
       "drawing the sub-image renders the cropped (blue) region");

  CGImageRelease(img);
  CGImageRelease(rbimg);
  CGImageRelease(sub);
  CGColorRelease(green);
  CGColorRelease(red);
  CGColorRelease(blue);
  CGContextRelease(sctx);
  CGContextRelease(dctx);
  CGContextRelease(rbctx);
  CGContextRelease(subctx);
  CGColorSpaceRelease(dev);
  free(src);
  free(dst);
  free(rb);
  free(subdst);

  END_SET("CGImage")
  return 0;
}
