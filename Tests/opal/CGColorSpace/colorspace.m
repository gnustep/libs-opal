/* CGColorSpace models and component counts for the device and named colour
   spaces.  Expected values checked against Apple CoreGraphics. */
#include "Testing.h"

#include <CoreGraphics/CGColorSpace.h>

int main(void)
{
  START_SET("CGColorSpace")

  PASS(kCGColorSpaceModelMonochrome == 0 && kCGColorSpaceModelRGB == 1
       && kCGColorSpaceModelCMYK == 2,
       "the colour space model constants have the AppKit values");

  CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
  PASS(CGColorSpaceGetModel(rgb) == kCGColorSpaceModelRGB
       && CGColorSpaceGetNumberOfComponents(rgb) == 3,
       "device RGB is the RGB model with 3 components");

  CGColorSpaceRef gray = CGColorSpaceCreateDeviceGray();
  PASS(CGColorSpaceGetModel(gray) == kCGColorSpaceModelMonochrome
       && CGColorSpaceGetNumberOfComponents(gray) == 1,
       "device gray is the monochrome model with 1 component");

  CGColorSpaceRef cmyk = CGColorSpaceCreateDeviceCMYK();
  PASS(CGColorSpaceGetModel(cmyk) == kCGColorSpaceModelCMYK
       && CGColorSpaceGetNumberOfComponents(cmyk) == 4,
       "device CMYK is the CMYK model with 4 components");

  CGColorSpaceRef grgb = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  PASS(CGColorSpaceGetModel(grgb) == kCGColorSpaceModelRGB
       && CGColorSpaceGetNumberOfComponents(grgb) == 3,
       "the generic RGB name gives an RGB space with 3 components");

  CGColorSpaceRef ggray = CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
  PASS(CGColorSpaceGetModel(ggray) == kCGColorSpaceModelMonochrome
       && CGColorSpaceGetNumberOfComponents(ggray) == 1,
       "the generic gray name gives a monochrome space with 1 component");

  CGColorSpaceRef srgb = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
  PASS(CGColorSpaceGetModel(srgb) == kCGColorSpaceModelRGB
       && CGColorSpaceGetNumberOfComponents(srgb) == 3,
       "the sRGB name gives an RGB space with 3 components");

  CGColorSpaceRelease(rgb);
  CGColorSpaceRelease(gray);
  CGColorSpaceRelease(cmyk);
  CGColorSpaceRelease(grgb);
  CGColorSpaceRelease(ggray);
  CGColorSpaceRelease(srgb);

  END_SET("CGColorSpace")
  return 0;
}
