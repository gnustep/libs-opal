/* CGBitmapContext accessors report the configuration a bitmap context was
   created with: width, height, bits per component, bits per pixel, bytes per
   row, alpha info, bitmap info, colour space and a data pointer.  Checked
   against Apple CoreGraphics.  An explicit bytes-per-row is echoed exactly; a
   zero bytes-per-row lets the implementation choose a row size (Apple aligns it
   up), so only the minimum is required there. */
#include "Testing.h"

#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGImage.h>

int main(void)
{
  CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
  CGColorSpaceRef gray = CGColorSpaceCreateDeviceGray();

  START_SET("CGBitmapContext RGBA")

  CGContextRef c = CGBitmapContextCreate(NULL, 10, 8, 8, 40, rgb,
    kCGImageAlphaPremultipliedLast);
  PASS(c != NULL, "an RGBA bitmap context is created");
  PASS(CGBitmapContextGetWidth(c) == 10, "the width is reported");
  PASS(CGBitmapContextGetHeight(c) == 8, "the height is reported");
  PASS(CGBitmapContextGetBitsPerComponent(c) == 8, "the bits per component are reported");
  PASS(CGBitmapContextGetBitsPerPixel(c) == 32, "RGBA is 32 bits per pixel");
  PASS(CGBitmapContextGetBytesPerRow(c) == 40, "an explicit bytes-per-row is reported exactly");
  PASS(CGBitmapContextGetAlphaInfo(c) == kCGImageAlphaPremultipliedLast,
       "the alpha info is reported");
  PASS((CGBitmapContextGetBitmapInfo(c) & kCGBitmapAlphaInfoMask)
         == kCGImageAlphaPremultipliedLast,
       "the bitmap info carries the alpha info");
  PASS(CGColorSpaceGetModel(CGBitmapContextGetColorSpace(c)) == kCGColorSpaceModelRGB,
       "the colour space is reported");
  PASS(CGBitmapContextGetData(c) != NULL, "the backing data pointer is available");

  CGContextRelease(c);

  END_SET("CGBitmapContext RGBA")

  START_SET("CGBitmapContext gray+alpha")

  CGContextRef g = CGBitmapContextCreate(NULL, 10, 8, 8, 0, gray,
    kCGImageAlphaPremultipliedLast);
  PASS(g != NULL, "a gray+alpha bitmap context is created");
  PASS(CGBitmapContextGetBitsPerPixel(g) == 16, "gray plus alpha is 16 bits per pixel");
  PASS(CGColorSpaceGetModel(CGBitmapContextGetColorSpace(g)) == kCGColorSpaceModelMonochrome,
       "the gray colour space is reported");
  /* A zero bytes-per-row is chosen by the implementation; require at least the
     minimum for the row. */
  testHopeful = YES;
  PASS(CGBitmapContextGetBytesPerRow(g) >= 10 * 2,
       "a computed bytes-per-row is at least the row minimum");
  testHopeful = NO;

  CGContextRelease(g);

  END_SET("CGBitmapContext gray+alpha")

  return 0;
}
