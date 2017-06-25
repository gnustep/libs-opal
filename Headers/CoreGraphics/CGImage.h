/** <title>CGImage</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

   Author: BALATON Zoltan <balaton@eik.bme.hu>
   Date: 2006

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#ifndef OPAL_CGImage_h
#define OPAL_CGImage_h

/* Data Types */

#ifdef INTERNAL_BUILD_OBJC
@class CGImage;
typedef CGImage* CGImageRef;
#else
typedef struct CGImage* CGImageRef;
#endif


#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGGeometry.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Constants */

enum
{
  kCGImageAlphaNone = 0,
  kCGImageAlphaPremultipliedLast = 1,
  kCGImageAlphaPremultipliedFirst = 2,
  kCGImageAlphaLast = 3,
  kCGImageAlphaFirst = 4,
  kCGImageAlphaNoneSkipLast = 5,
  kCGImageAlphaNoneSkipFirst = 6,
  kCGImageAlphaOnly = 7
};

enum
{
  kCGBitmapAlphaInfoMask = 0x1F,
  kCGBitmapFloatComponents = (1 << 8),
  kCGBitmapByteOrderMask = 0x7000,
  kCGBitmapByteOrderDefault = (0 << 12),
  kCGBitmapByteOrder16Little = (1 << 12),
  kCGBitmapByteOrder32Little = (2 << 12),
  kCGBitmapByteOrder16Big = (3 << 12),
  kCGBitmapByteOrder32Big = (4 << 12)
};

typedef uint32_t CGImageAlphaInfo;
typedef uint32_t CGBitmapInfo;

enum
{
  kCGImagePropertyOrientationUp = 1,
  kCGImagePropertyOrientationUpMirrored,
  kCGImagePropertyOrientationDown,
  kCGImagePropertyOrientationDownMirrored,
  kCGImagePropertyOrientationLeftMirrored,
  kCGImagePropertyOrientationRight,
  kCGImagePropertyOrientationRightMirrored,
  kCGImagePropertyOrientationLeft
};
typedef int CGImagePropertyOrientation;

extern const CFStringRef kCGImagePropertyOrientation;

extern const CFStringRef kCGImagePropertyPixelHeight;
extern const CFStringRef kCGImagePropertyPixelWidth;

extern const CFStringRef kCGImagePropertyTIFFDictionary;
extern const CFStringRef kCGImagePropertyGIFDictionary;
extern const CFStringRef kCGImagePropertyJFIFDictionary;
extern const CFStringRef kCGImagePropertyExifDictionary;
extern const CFStringRef kCGImagePropertyPNGDictionary;
extern const CFStringRef kCGImagePropertyIPTCDictionary;
extern const CFStringRef kCGImagePropertyGPSDictionary;
extern const CFStringRef kCGImagePropertyRawDictionary;
extern const CFStringRef kCGImagePropertyCIFFDictionary;
extern const CFStringRef kCGImagePropertyMakerCanonDictionary;
extern const CFStringRef kCGImagePropertyMakerNikonDictionary;
extern const CFStringRef kCGImagePropertyMakerMinoltaDictionary;
extern const CFStringRef kCGImagePropertyMakerFujiDictionary;
extern const CFStringRef kCGImagePropertyMakerOlympusDictionary;
extern const CFStringRef kCGImagePropertyMakerPentaxDictionary;
extern const CFStringRef kCGImageProperty8BIMDictionary;
extern const CFStringRef kCGImagePropertyDNGDictionary;
extern const CFStringRef kCGImagePropertyExifAuxDictionary;
extern const CFStringRef kCGImagePropertyOpenEXRDictionary;
extern const CFStringRef kCGImagePropertyMakerAppleDictionary;

extern const CFStringRef kCGImagePropertyJFIFVersion;
extern const CFStringRef kCGImagePropertyJFIFXDensity;
extern const CFStringRef kCGImagePropertyJFIFYDensity;
extern const CFStringRef kCGImagePropertyJFIFDensityUnit;
extern const CFStringRef kCGImagePropertyJFIFIsProgressive;

extern const CFStringRef kCGImagePropertyGIFLoopCount;
extern const CFStringRef kCGImagePropertyGIFDelayTime;
extern const CFStringRef kCGImagePropertyGIFImageColorMap;
extern const CFStringRef kCGImagePropertyGIFHasGlobalColorMap;
extern const CFStringRef kCGImagePropertyGIFUnclampedDelayTime;

extern const CFStringRef kCGImagePropertyPNGGamma;
extern const CFStringRef kCGImagePropertyPNGInterlaceType;
extern const CFStringRef kCGImagePropertyPNGXPixelsPerMeter;
extern const CFStringRef kCGImagePropertyPNGYPixelsPerMeter;
extern const CFStringRef kCGImagePropertyPNGsRGBIntent;
extern const CFStringRef kCGImagePropertyPNGChromaticities;

extern const CFStringRef kCGImagePropertyPNGAuthor;
extern const CFStringRef kCGImagePropertyPNGCopyright;
extern const CFStringRef kCGImagePropertyPNGCreationTime;
extern const CFStringRef kCGImagePropertyPNGDescription;
extern const CFStringRef kCGImagePropertyPNGModificationTime;
extern const CFStringRef kCGImagePropertyPNGSoftware;
extern const CFStringRef kCGImagePropertyPNGTitle;

extern const CFStringRef kCGImagePropertyAPNGLoopCount;
extern const CFStringRef kCGImagePropertyAPNGDelayTime;
extern const CFStringRef kCGImagePropertyAPNGUnclampedDelayTime;

// FIXME: Verify this endianness check works
#if GS_WORDS_BIGENDIAN
#define kCGBitmapByteOrder16Host kCGBitmapByteOrder16Big
#define kCGBitmapByteOrder32Host kCGBitmapByteOrder32Big
#else
#define kCGBitmapByteOrder16Host kCGBitmapByteOrder16Little
#define kCGBitmapByteOrder32Host kCGBitmapByteOrder32Little
#endif

/* Drawing Images */

CGImageRef CGImageCreate(
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bitsPerPixel,
  size_t bytesPerRow,
  CGColorSpaceRef colorspace,
  CGBitmapInfo bitmapInfo,
  CGDataProviderRef provider,
  const CGFloat decode[],
  bool shouldInterpolate,
  CGColorRenderingIntent intent
);

CGImageRef CGImageMaskCreate(
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bitsPerPixel,
  size_t bytesPerRow,
  CGDataProviderRef provider,
  const CGFloat decode[],
  bool shouldInterpolate
);

CGImageRef CGImageCreateCopy(CGImageRef image);

CGImageRef CGImageCreateCopyWithColorSpace(
  CGImageRef image,
  CGColorSpaceRef colorspace
);

CGImageRef CGImageCreateWithImageInRect(
  CGImageRef image,
  CGRect rect
);

CGImageRef CGImageCreateWithJPEGDataProvider (
  CGDataProviderRef source,
  const CGFloat decode[],
  bool shouldInterpolate,
  CGColorRenderingIntent intent
);

CGImageRef CGImageCreateWithMask (
  CGImageRef image,
  CGImageRef mask
);

CGImageRef CGImageCreateWithMaskingColors (
  CGImageRef image,
  const CGFloat components[]
);

CGImageRef CGImageCreateWithPNGDataProvider (
  CGDataProviderRef source,
  const CGFloat decode[],
  bool shouldInterpolate,
  CGColorRenderingIntent intent
);

CFTypeID CGImageGetTypeID();

CGImageRef CGImageRetain(CGImageRef image);

void CGImageRelease(CGImageRef image);

bool CGImageIsMask(CGImageRef image);

size_t CGImageGetWidth(CGImageRef image);

size_t CGImageGetHeight(CGImageRef image);

size_t CGImageGetBitsPerComponent(CGImageRef image);

size_t CGImageGetBitsPerPixel(CGImageRef image);

size_t CGImageGetBytesPerRow(CGImageRef image);

CGColorSpaceRef CGImageGetColorSpace(CGImageRef image);

CGImageAlphaInfo CGImageGetAlphaInfo(CGImageRef image);

CGBitmapInfo CGImageGetBitmapInfo(CGImageRef image);

CGDataProviderRef CGImageGetDataProvider(CGImageRef image);

const CGFloat *CGImageGetDecode(CGImageRef image);

bool CGImageGetShouldInterpolate(CGImageRef image);

CGColorRenderingIntent CGImageGetRenderingIntent(CGImageRef image);

#ifdef __cplusplus
}
#endif

#endif /* OPAL_CGImage_h */
