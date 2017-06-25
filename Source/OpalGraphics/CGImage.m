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

#include "CoreGraphics/CGImage.h"
#include "CoreGraphics/CGImageSource.h"
//#include "CGDataProvider-private.h"
#include "CGImage-private.h"
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#include <stdlib.h>
#include <cairo.h>

#import "OPImageConversion.h"

/* Exports */
#define OPALSTR(x) (CFStringRef)(@ x)
const CFStringRef kCGImagePropertyOrientation =
  OPALSTR("kCGImagePropertyOrientation");

const CFStringRef kCGImagePropertyPixelHeight =
  OPALSTR("kCGImagePropertyPixelHeight");
const CFStringRef kCGImagePropertyPixelWidth =
  OPALSTR("kCGImagePropertyPixelWidth");

const CFStringRef kCGImagePropertyTIFFDictionary =
  OPALSTR("kCGImagePropertyTIFFDictionary");
const CFStringRef kCGImagePropertyGIFDictionary =
  OPALSTR("kCGImagePropertyGIFDictionary");
const CFStringRef kCGImagePropertyJFIFDictionary =
  OPALSTR("kCGImagePropertyJFIFDictionary");
const CFStringRef kCGImagePropertyExifDictionary =
  OPALSTR("kCGImagePropertyExifDictionary");
const CFStringRef kCGImagePropertyPNGDictionary =
  OPALSTR("kCGImagePropertyPNGDictionary");
const CFStringRef kCGImagePropertyIPTCDictionary =
  OPALSTR("kCGImagePropertyIPTCDictionary");
const CFStringRef kCGImagePropertyGPSDictionary =
  OPALSTR("kCGImagePropertyGPSDictionary");
const CFStringRef kCGImagePropertyRawDictionary =
  OPALSTR("kCGImagePropertyRawDictionary");
const CFStringRef kCGImagePropertyCIFFDictionary =
  OPALSTR("kCGImagePropertyCIFFDictionary");
const CFStringRef kCGImagePropertyMakerCanonDictionary =
  OPALSTR("kCGImagePropertyMakerCanonDictionary");
const CFStringRef kCGImagePropertyMakerNikonDictionary =
  OPALSTR("kCGImagePropertyMakerNikonDictionary");
const CFStringRef kCGImagePropertyMakerMinoltaDictionary =
  OPALSTR("kCGImagePropertyMakerMinoltaDictionary");
const CFStringRef kCGImagePropertyMakerFujiDictionary =
  OPALSTR("kCGImagePropertyMakerFujiDictionary");
const CFStringRef kCGImagePropertyMakerOlympusDictionary =
  OPALSTR("kCGImagePropertyMakerOlympusDictionary");
const CFStringRef kCGImagePropertyMakerPentaxDictionary =
  OPALSTR("kCGImagePropertyMakerPentaxDictionary");
const CFStringRef kCGImageProperty8BIMDictionary =
  OPALSTR("kCGImageProperty8BIMDictionary");
const CFStringRef kCGImagePropertyDNGDictionary =
  OPALSTR("kCGImagePropertyDNGDictionary");
const CFStringRef kCGImagePropertyExifAuxDictionary =
  OPALSTR("kCGImagePropertyExifAuxDictionary");
const CFStringRef kCGImagePropertyOpenEXRDictionary =
  OPALSTR("kCGImagePropertyOpenEXRDictionary");
const CFStringRef kCGImagePropertyMakerAppleDictionary =
  OPALSTR("kCGImagePropertyMakerAppleDictionary");

const CFStringRef kCGImagePropertyJFIFVersion =
  OPALSTR("kCGImagePropertyJFIFVersion");
const CFStringRef kCGImagePropertyJFIFXDensity =
  OPALSTR("kCGImagePropertyJFIFXDensity");
const CFStringRef kCGImagePropertyJFIFYDensity =
  OPALSTR("kCGImagePropertyJFIFYDensity");
const CFStringRef kCGImagePropertyJFIFDensityUnit =
  OPALSTR("kCGImagePropertyJFIFDensityUnit");
const CFStringRef kCGImagePropertyJFIFIsProgressive =
  OPALSTR("kCGImagePropertyJFIFIsProgressive");

const CFStringRef kCGImagePropertyGIFLoopCount =
  OPALSTR("kCGImagePropertyGIFLoopCount");
const CFStringRef kCGImagePropertyGIFDelayTime =
  OPALSTR("kCGImagePropertyGIFDelayTime");
const CFStringRef kCGImagePropertyGIFImageColorMap =
  OPALSTR("kCGImagePropertyGIFImageColorMap");
const CFStringRef kCGImagePropertyGIFHasGlobalColorMap =
  OPALSTR("kCGImagePropertyGIFHasGlobalColorMap");
const CFStringRef kCGImagePropertyGIFUnclampedDelayTime =
  OPALSTR("kCGImagePropertyGIFUnclampedDelayTime");

const CFStringRef kCGImagePropertyPNGGamma =
  OPALSTR("kCGImagePropertyPNGGamma");
const CFStringRef kCGImagePropertyPNGInterlaceType =
  OPALSTR("kCGImagePropertyPNGInterlaceType");
const CFStringRef kCGImagePropertyPNGXPixelsPerMeter =
  OPALSTR("kCGImagePropertyPNGXPixelsPerMeter");
const CFStringRef kCGImagePropertyPNGYPixelsPerMeter =
  OPALSTR("kCGImagePropertyPNGYPixelsPerMeter");
const CFStringRef kCGImagePropertyPNGsRGBIntent =
  OPALSTR("kCGImagePropertyPNGsRGBIntent");
const CFStringRef kCGImagePropertyPNGChromaticities =
  OPALSTR("kCGImagePropertyPNGChromaticities");

const CFStringRef kCGImagePropertyPNGAuthor =
  OPALSTR("kCGImagePropertyPNGAuthor");
const CFStringRef kCGImagePropertyPNGCopyright =
  OPALSTR("kCGImagePropertyPNGCopyright");
const CFStringRef kCGImagePropertyPNGCreationTime =
  OPALSTR("kCGImagePropertyPNGCreationTime");
const CFStringRef kCGImagePropertyPNGDescription =
  OPALSTR("kCGImagePropertyPNGDescription");
const CFStringRef kCGImagePropertyPNGModificationTime =
  OPALSTR("kCGImagePropertyPNGModificationTime");
const CFStringRef kCGImagePropertyPNGSoftware =
  OPALSTR("kCGImagePropertyPNGSoftware");
const CFStringRef kCGImagePropertyPNGTitle =
  OPALSTR("kCGImagePropertyPNGTitle");

const CFStringRef kCGImagePropertyAPNGLoopCount =
  OPALSTR("kCGImagePropertyAPNGLoopCount");
const CFStringRef kCGImagePropertyAPNGDelayTime =
  OPALSTR("kCGImagePropertyAPNGDelayTime");
const CFStringRef kCGImagePropertyAPNGUnclampedDelayTime =
  OPALSTR("kCGImagePropertyAPNGUnclampedDelayTime");
#undef OPALSTR

void DumpPixel(const void *data, NSString *msg)
{
  if(!data)
    {
      NSDebugLLog(@"Opal", @"%@: <null data>", msg);
      return;
    }

  NSDebugLLog(@"Opal", @"%@: (%02x,%02x,%02x,%02x)", msg, (int)(((unsigned char*)data)[0]), 
        (int)(((unsigned char*)data)[1]),
        (int)(((unsigned char*)data)[2]),
        (int)(((unsigned char*)data)[3]));
}

@implementation CGImage

- (id) initWithWidth: (size_t)aWidth
              height: (size_t)aHeight
    bitsPerComponent: (size_t)aBitsPerComponent
        bitsPerPixel: (size_t)aBitsPerPixel
         bytesPerRow: (size_t)aBytesPerRow
          colorSpace: (CGColorSpaceRef)aColorspace
          bitmapInfo: (CGBitmapInfo)aBitmapInfo
            provider: (CGDataProviderRef)aProvider
              decode: (const CGFloat *)aDecode
   shouldInterpolate: (bool)anInterpolate
              intent: (CGColorRenderingIntent)anIntent
{
  self = [super init];
  if (nil == self)
  {
    [super release];
    return nil;
  }

  size_t numComponents;
  if ((aBitmapInfo & kCGBitmapAlphaInfoMask) == kCGImageAlphaOnly)
  {
    numComponents = 0;
  }
  else
  {
    numComponents = CGColorSpaceGetNumberOfComponents(aColorspace);
  }

  const bool hasAlpha =
    ((aBitmapInfo & kCGBitmapAlphaInfoMask) == kCGImageAlphaPremultipliedLast) ||
    ((aBitmapInfo & kCGBitmapAlphaInfoMask) == kCGImageAlphaPremultipliedFirst) ||
    ((aBitmapInfo & kCGBitmapAlphaInfoMask) == kCGImageAlphaLast) ||
    ((aBitmapInfo & kCGBitmapAlphaInfoMask) == kCGImageAlphaFirst) ||
    ((aBitmapInfo & kCGBitmapAlphaInfoMask) == kCGImageAlphaOnly);

  const size_t numComponentsIncludingAlpha = numComponents + (hasAlpha ? 1 : 0);

  if (aBitsPerComponent < 1 || aBitsPerComponent > 32)
  {
    NSLog(@"Unsupported bitsPerComponent: %d", aBitsPerComponent);
    [self release];
    return nil;
  }
  if ((aBitmapInfo & kCGBitmapFloatComponents) != 0 && aBitsPerComponent != 32)
  {
    NSLog(@"Only 32 bitsPerComponents supported for float components");
    [self release];
    return nil;
  }
  if (aBitsPerPixel < aBitsPerComponent * numComponentsIncludingAlpha)
  {
    // Note if an alpha channel is requrested, we require it to be the same size 
    // as the other components
    NSLog(@"Too few bitsPerPixel for bitsPerComponent");
    [self release];
    return nil;
  }

  if(aDecode && numComponents) {
    size_t i;

    self->decode = malloc(2 * numComponents * sizeof(CGFloat));
    if (!self->decode)
    {
      NSLog(@"Malloc failed");
      [self release];
      return nil;
    }
    for(i = 0; i < 2 * numComponents; i++)
    {
      self->decode[i] = aDecode[i];
    }
  }

  self->ismask = false;
  self->width = aWidth;
  self->height = aHeight;
  self->bitsPerComponent = aBitsPerComponent;
  self->bitsPerPixel = aBitsPerPixel;
  self->bytesPerRow = aBytesPerRow;
  self->dp = CGDataProviderRetain(aProvider);
  self->shouldInterpolate = anInterpolate;
  self->crop = CGRectNull;
  self->surf = NULL;
  self->bitmapInfo = aBitmapInfo;
  self->cspace = CGColorSpaceRetain(aColorspace);
  self->intent = anIntent;

  return self;
}

- (id) copyWithZone: (NSZone*)zone
{
  return [self retain];
}

- (void) dealloc
{
  CGColorSpaceRelease(self->cspace);
  CGDataProviderRelease(self->dp);
  if (self->decode) free(self->decode);
  if (self->surf) cairo_surface_destroy(self->surf);
  [super dealloc];
}

- (NSString *)description
{
  return [NSString stringWithFormat: @"<CGImage %p width: %d  height: %d bits-per-component: %d bpp: %d bytes-per-row: %d provider: %@ shouldInterpolate: %d crop: %g,%g,%g,%g>", self, (int)width, (int)height, (int)bitsPerComponent, (int)bitsPerPixel, (int)bytesPerRow, dp, (int)shouldInterpolate, crop.origin.x, crop.origin.y, crop.size.width, crop.size.height];
}

@end





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
  CGColorRenderingIntent intent)
{
  return [[CGImage alloc] initWithWidth: width
                                 height: height
                       bitsPerComponent: bitsPerComponent
                           bitsPerPixel: bitsPerPixel
                            bytesPerRow: bytesPerRow
                             colorSpace: colorspace
                             bitmapInfo: bitmapInfo
                               provider: provider
                                 decode: decode
                      shouldInterpolate: shouldInterpolate
                                 intent: intent];
}

CGImageRef CGImageMaskCreate(
  size_t width, size_t height,
  size_t bitsPerComponent, size_t bitsPerPixel, size_t bytesPerRow,
  CGDataProviderRef provider, const CGFloat decode[], bool shouldInterpolate)
{
  CGImageRef img = [[CGImage alloc] initWithWidth: width
                                           height: height
                                 bitsPerComponent: bitsPerComponent
                                     bitsPerPixel: bitsPerPixel
                                      bytesPerRow: bytesPerRow
                                       colorSpace: nil // FIXME
                                       bitmapInfo: 0 // FIXME
                                         provider: provider
                                           decode: decode
                                shouldInterpolate: shouldInterpolate
                                   intent: 0]; // FIXME

  if (!img)
  {
    return nil;
  }

  img->ismask = true;

  return img;
}

CGImageRef CGImageCreateCopy(CGImageRef image)
{
  return [image retain];
}


CGImageRef CGImageCreateCopyWithColorSpace(
  CGImageRef image,
  CGColorSpaceRef colorspace)
{
  CGImageRef new;

  // FIXME: is this supposed to convert pixel data?

  if (image->ismask ||
    CGColorSpaceGetNumberOfComponents(image->cspace)
    != CGColorSpaceGetNumberOfComponents(colorspace))
  {
    return nil;
  }
  else
  {
    new = CGImageCreate(image->width, image->height,
      image->bitsPerComponent, image->bitsPerPixel, image->bytesPerRow,
      colorspace, image->bitmapInfo, image->dp, image->decode,
      image->shouldInterpolate, image->intent);
  }

  if (!new) return NULL;

  // Since CGImage is immutable, we can reference the source image's surface
  if (image->surf)
  {
    new->surf = cairo_surface_reference(image->surf);
  }
  return new;
}

CGImageRef CGImageCreateWithImageInRect(
  CGImageRef image,
  CGRect rect)
{
  CGImageRef new = CGImageCreate(image->width, image->height,
      image->bitsPerComponent, image->bitsPerPixel, image->bytesPerRow,
      image->cspace, image->bitmapInfo, image->dp, image->decode,
      image->shouldInterpolate, image->intent);
  if (!new) return NULL;

  // Set the crop rect
  rect = CGRectIntegral(rect);
  rect = CGRectIntersection(rect, CGRectMake(0, 0, image->width, image->height));
  new->crop = rect;

  if (image->surf)
  {
    new->surf = cairo_surface_reference(image->surf);
  }

  return new;
}

CGImageRef CGImageCreateWithMaskingColors (
  CGImageRef image,
  const CGFloat components[])
{
  //FIXME: Implement
  return nil;
}

static CGImageRef createWithDataProvider(
  CGDataProviderRef provider,
  const CGFloat decode[],
  bool shouldInterpolate,
  CGColorRenderingIntent intent,
  CFStringRef type)
{
  NSDictionary *opts = [[NSDictionary alloc] initWithObjectsAndKeys:
    type, kCGImageSourceTypeIdentifierHint,
    nil];

  CGImageSourceRef src = CGImageSourceCreateWithDataProvider(provider, opts);
  CGImageRef img = nil;
  if ([CGImageSourceGetType(src) isEqual: type])
  {
    if (CGImageSourceGetCount(src) >= 1)
    {
      img = CGImageSourceCreateImageAtIndex(src, 0, opts);
    }
    else
    {
      NSLog(@"No images found");
    }
  }
  else
  {
    NSLog(@"Unexpected type of image. expected %@, found %@", type, CGImageSourceGetType(src));
  }
  [src release];
  [opts release];

  if (img)
  {
    img->shouldInterpolate = shouldInterpolate;
    img->intent = intent;
    // FIXME: decode array???
  }

  return img;
}


CGImageRef CGImageCreateWithJPEGDataProvider(
  CGDataProviderRef source,
  const CGFloat decode[],
  bool shouldInterpolate,
  CGColorRenderingIntent intent)
{
  // FIXME: If cairo 1.9.x or greater, and the image is a PNG or JPEG, attach the
  // compressed data to the surface with cairo_surface_set_mime_data (so embedding
  // images in to PDF/SVG output works optimally)

  return createWithDataProvider(source, decode, shouldInterpolate, intent, @"public.jpeg");
}

CGImageRef CGImageCreateWithPNGDataProvider(
  CGDataProviderRef source,
  const CGFloat decode[],
  bool shouldInterpolate,
  CGColorRenderingIntent intent)
{
  return createWithDataProvider(source, decode, shouldInterpolate, intent, @"public.png");
}

CFTypeID CGImageGetTypeID()
{
  return (CFTypeID)[CGImage class];
}

CGImageRef CGImageRetain(CGImageRef image)
{
  return [image retain];
}

void CGImageRelease(CGImageRef image)
{
  [image release];
}

bool CGImageIsMask(CGImageRef image)
{
  return image->ismask;
}

size_t CGImageGetWidth(CGImageRef image)
{
  return image->width;
}

size_t CGImageGetHeight(CGImageRef image)
{
  return image->height;
}

size_t CGImageGetBitsPerComponent(CGImageRef image)
{
  return image->bitsPerComponent;
}

size_t CGImageGetBitsPerPixel(CGImageRef image)
{
  return image->bitsPerPixel;
}

size_t CGImageGetBytesPerRow(CGImageRef image)
{
  return image->bytesPerRow;
}

CGColorSpaceRef CGImageGetColorSpace(CGImageRef image)
{
  return image->cspace;
}

CGImageAlphaInfo CGImageGetAlphaInfo(CGImageRef image)
{
  return image->bitmapInfo & kCGBitmapAlphaInfoMask;
}

CGBitmapInfo CGImageGetBitmapInfo(CGImageRef image)
{
  return image->bitmapInfo;
}

CGDataProviderRef CGImageGetDataProvider(CGImageRef image)
{
  return image->dp;
}

const CGFloat *CGImageGetDecode(CGImageRef image)
{
  return image->decode;
}

bool CGImageGetShouldInterpolate(CGImageRef image)
{
  return image->shouldInterpolate;
}

CGColorRenderingIntent CGImageGetRenderingIntent(CGImageRef image)
{
  return image->intent;
}

/**
 * Use OPImageConvert to convert whatever image data the CGImage holds
 * into Cairo's format (premultiplied ARGB32), and cache this
 * surface. Hopefully cairo uploads image surfaces created with
 * cairo_image_surface_create to the graphics card.
 *
 *
 */
cairo_surface_t *opal_CGImageGetSurfaceForImage(CGImageRef img, cairo_surface_t *contextSurface)
{
  if (NULL == img)
  {
    return NULL;
  }
  if (NULL == img->surf)
  {
    cairo_surface_t *memSurf = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
                                           CGImageGetWidth(img),
                                           CGImageGetHeight(img));
    if (cairo_surface_status(memSurf) != CAIRO_STATUS_SUCCESS)
    {
      NSLog(@"Cairo error creating image\n");
      return NULL;
    }

    cairo_surface_flush(memSurf); // going to modify the surface outside of cairo

    const unsigned char *srcData = OPDataProviderGetBytePointer(img->dp);
    const size_t srcWidth = CGImageGetWidth(img);
    const size_t srcHeight = CGImageGetHeight(img);
    const size_t srcBitsPerComponent = CGImageGetBitsPerComponent(img);
    const size_t srcBitsPerPixel = CGImageGetBitsPerPixel(img);
    const size_t srcBytesPerRow = CGImageGetBytesPerRow(img);
    const CGBitmapInfo srcBitmapInfo = CGImageGetBitmapInfo(img);
    const CGColorSpaceRef srcColorSpace = CGImageGetColorSpace(img);
    const CGColorRenderingIntent srcIntent = CGImageGetRenderingIntent(img);

    unsigned char *dstData = cairo_image_surface_get_data(memSurf);
    const size_t dstBitsPerComponent = 8;
    const size_t dstBitsPerPixel = 32;
    const size_t dstBytesPerRow = cairo_image_surface_get_stride(memSurf);
    CGBitmapInfo dstBitmapInfo = kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst;
    const CGColorSpaceRef dstColorSpace = srcColorSpace;

    OPImageConvert(
      dstData, srcData,
      srcWidth, srcHeight,
      dstBitsPerComponent, srcBitsPerComponent,
      dstBitsPerPixel, srcBitsPerPixel,
      dstBytesPerRow, srcBytesPerRow,
      dstBitmapInfo, srcBitmapInfo,
      dstColorSpace, srcColorSpace,
      srcIntent);

    DumpPixel(srcData, @"OPImageConvert src (expecting R G B A)");
    DumpPixel(dstData, @"OPImageConvert dst (expecting A R G B premult)");
		
    OPDataProviderReleaseBytePointer(img->dp, srcData);

    cairo_surface_mark_dirty(memSurf); // done modifying the surface outside of cairo


    // Now, draw the image into (hopefully) a surface on the window server

    img->surf = cairo_surface_create_similar(contextSurface,
                                 CAIRO_CONTENT_COLOR_ALPHA,
                                 CGImageGetWidth(img),
                                 CGImageGetHeight(img));
    cairo_t *ctx = cairo_create(img->surf);
    cairo_set_source_surface(ctx, memSurf, 0, 0);
    cairo_paint(ctx);
    cairo_destroy(ctx);
    cairo_surface_destroy(memSurf);
  }

  return img->surf;
}

CGRect opal_CGImageGetSourceRect(CGImageRef image)
{
  if (NULL == image) {
    return CGRectMake(0, 0, 0, 0);
  }

  if (CGRectIsNull(image->crop)) {
    return CGRectMake(0, 0, image->width, image->height);
  } else {
    return image->crop;
  }
}
