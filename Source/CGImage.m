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
#include "CGDataProvider-private.h"
#include <stdlib.h>
#include <cairo.h>
#include "opal.h"

typedef struct CGImage
{
  struct objbase base;
  bool ismask;

  size_t width;
  size_t height;
  size_t bitsPerComponent;
  size_t bitsPerPixel;
  size_t bytesPerRow;
  CGDataProviderRef dp;
  CGFloat *decode;
  bool shouldInterpolate;
  /* alphaInfo is always AlphaNone for mask */
  CGBitmapInfo bitmapInfo;
  /* cspace and intent are only set for image */
  CGColorSpaceRef cspace;
  CGColorRenderingIntent intent;
  
  /* used for CGImageCreateWithImageInRect */
  CGRect crop;
  cairo_surface_t *surf;
} CGImage;

void opal_dealloc_CGImage(void *i)
{
  CGImageRef img = i;

  CGColorSpaceRelease(img->cspace);
  CGDataProviderRelease(img->dp);
  if (img->decode) free(img->decode);
  if (img->surf) cairo_surface_destroy(img->surf);
  free(i);
}

static inline CGImageRef opal_CreateImage(
  size_t width, size_t height,
  size_t bitsPerComponent, size_t bitsPerPixel, size_t bytesPerRow,
  CGDataProviderRef provider, const CGFloat *decode, bool shouldInterpolate,
  size_t numComponents, bool hasAlpha)
{
  CGImageRef img;

  if (bitsPerComponent != 8 && bitsPerComponent != 4 &&
      bitsPerComponent != 2 && bitsPerComponent != 1) {
    errlog("%s:%d: Invalid bitsPerComponent (allowed: 1,2,4,8)\n",
      __FILE__, __LINE__);
    return NULL;
  }
  if (bitsPerPixel != 32 && bitsPerPixel != 16 &&
      bitsPerPixel != 8) {
    errlog("%s:%d: Unsupported bitsPerPixel (allowed: 8, 16, 32)\n",
      __FILE__, __LINE__);
    return NULL;
  }
  if (bitsPerPixel < bitsPerComponent * (numComponents + (hasAlpha ? 1 : 0))) {
    errlog("%s:%d: Too few bitsPerPixel for bitsPerComponent\n",
      __FILE__, __LINE__);
    return NULL;
  }

  img = opal_obj_alloc("CGImage", sizeof(CGImage));
  if (!img) return NULL;
  if(decode && numComponents) {
    size_t i;

    img->decode = malloc(2*numComponents*sizeof(CGFloat));
    if (!img->decode) {
      errlog("%s:%d: malloc failed\n", __FILE__, __LINE__);
      free(img);
      return NULL;
    }
    for(i=0; i<2*numComponents; i++) img->decode[i] = decode[i];
  }

  img->width = width;
  img->height = height;
  img->bitsPerComponent = bitsPerComponent;
  img->bitsPerPixel = bitsPerPixel;
  img->bytesPerRow = bytesPerRow;
  img->dp = CGDataProviderRetain(provider);
  img->shouldInterpolate = shouldInterpolate;
  img->crop = CGRectNull;
  img->surf = NULL;
  
  return img;
}

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
  CGImageRef img;
  size_t numComponents;
  CGImageAlphaInfo alphaInfo;
  bool hasAlpha;
  
  alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
  if (alphaInfo == kCGImageAlphaOnly)
    numComponents = 0;
  else
    numComponents = CGColorSpaceGetNumberOfComponents(colorspace);
  hasAlpha = (alphaInfo == kCGImageAlphaPremultipliedLast) ||
             (alphaInfo == kCGImageAlphaPremultipliedFirst) ||
             (alphaInfo == kCGImageAlphaLast) ||
             (alphaInfo == kCGImageAlphaFirst) ||
             (alphaInfo == kCGImageAlphaOnly);

  if (!provider || !colorspace) return NULL;
  img = opal_CreateImage(width, height,
                         bitsPerComponent, bitsPerPixel, bytesPerRow,
                         provider, decode, shouldInterpolate,
                         numComponents, hasAlpha);
  if (!img) return NULL;

  img->bitmapInfo = bitmapInfo;
  img->cspace = CGColorSpaceRetain(colorspace);
  img->intent = intent;

  return img;
}

CGImageRef CGImageMaskCreate(
  size_t width, size_t height,
  size_t bitsPerComponent, size_t bitsPerPixel, size_t bytesPerRow,
  CGDataProviderRef provider, const CGFloat decode[], bool shouldInterpolate)
{
  CGImageRef img;

  if (!provider) return NULL;
  img = opal_CreateImage(width, height,
                         bitsPerComponent, bitsPerPixel, bytesPerRow,
                         provider, decode, shouldInterpolate, 0, 1);
  if (!img) return NULL;

  img->ismask = true;

  return img;
}

CGImageRef CGImageCreateCopy(CGImageRef image)
{
  CGImageRef new;
  
  if (image->ismask) {
    new = CGImageMaskCreate(image->width, image->height,
      image->bitsPerComponent, image->bitsPerPixel, image->bytesPerRow,
      image->dp, image->decode, image->shouldInterpolate);
  } else {
    new = CGImageCreate(image->width, image->height,
      image->bitsPerComponent, image->bitsPerPixel, image->bytesPerRow,
      image->cspace, image->bitmapInfo, image->dp, image->decode,
      image->shouldInterpolate, image->intent);
  }
      
  if (!new) return NULL;
  
  // Since CGImage is immutable, we can reference the source image's surface
  if (image->surf) {
    new->surf = cairo_surface_reference(image->surf);
  }
  return new;
}


CGImageRef CGImageCreateCopyWithColorSpace(
  CGImageRef image,
  CGColorSpaceRef colorspace)
{
  CGImageRef new = CGImageCreateCopy(image);
  if (!new) return NULL;
    
  CGColorSpaceRelease(new->cspace);
  new->cspace = CGColorSpaceRetain(colorspace);
  
  return new;
}

CGImageRef CGImageCreateWithImageInRect(
  CGImageRef image,
  CGRect rect)
{
  CGImageRef new = CGImageCreateCopy(image);
  if (!new) return NULL;
    
  // Set the crop rect
  rect = CGRectIntegral(rect);
  rect = CGRectIntersection(rect, CGRectMake(0, 0, image->width, image->height));
  new->crop = rect;

  return new;
}

CGImageRef CGImageCreateWithJPEGDataProvider (
  CGDataProviderRef source,
  const CGFloat decode[],
  bool shouldInterpolate,
  CGColorRenderingIntent intent)
{
  //FIXME: Implement
}

CGImageRef CGImageCreateWithMaskingColors (
  CGImageRef image,
  const CGFloat components[])
{
  //FIXME: Implement
}

CGImageRef CGImageCreateWithPNGDataProvider (
  CGDataProviderRef source,
  const CGFloat decode[],
  bool shouldInterpolate,
  CGColorRenderingIntent intent)
{
  //FIXME: Implement
}

CFTypeID CGImageGetTypeID()
{

}

CGImageRef CGImageRetain(CGImageRef image)
{
  return (image ? opal_obj_retain(image) : NULL);
}

void CGImageRelease(CGImageRef image)
{
  if(image) opal_obj_release(image);
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

cairo_surface_t *opal_CGImageGetSurfaceForImage(CGImageRef img)
{
  cairo_format_t cformat;
  unsigned char *data;
  size_t datalen;
  size_t numComponents = 0;
  int alphaLast = 0;
  int mask;

  // Return the cached surface if it already exists
  if (NULL != img->surf)
    return img->surf;

  /* The target is always 8 BPC 32 BPP for Cairo so should convert to this */
  /* (see also QA1037) */
  if (img->cspace)
    numComponents = CGColorSpaceGetNumberOfComponents(img->cspace);

  switch (CGImageGetAlphaInfo(img)) {
    case kCGImageAlphaNone:
    case kCGImageAlphaNoneSkipLast:
      alphaLast = 1;
    case kCGImageAlphaNoneSkipFirst:
      break;
    case kCGImageAlphaLast:
      alphaLast = 1;
    case kCGImageAlphaFirst:
      numComponents++;
      break;
    case kCGImageAlphaPremultipliedLast:
    case kCGImageAlphaPremultipliedFirst:
      errlog("%s:%d: FIXME: premultiplied alpha is not supported\n",
        __FILE__, __LINE__);
      return NULL;
      break;
    case kCGImageAlphaOnly:
      numComponents = 1;
  }

  datalen = img->bytesPerRow * img->height;

  // FIXME: ???
  mask = (1 << img->bitsPerComponent) - 1;

  // FIXME: the following is just a rough sketch
  data = malloc(datalen);

  int read = 0;
  while (read < datalen)
  {
    read += opal_DataProviderRead(img->dp, data, 10000000);
  }

  img->surf = cairo_image_surface_create_for_data(data,
						CAIRO_FORMAT_ARGB32,
						img->width,
						img->height,
						cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, img->width));
            
  if (cairo_surface_status(img->surf) != CAIRO_STATUS_SUCCESS)
  {
    errlog("%s:%d: Cairo error creating surface\n", __FILE__, __LINE__);
  }

  // FIXME: If cairo 1.9.x or greater, and the image is a PNG or JPEG, attach the
  // compressed data to the surface with cairo_surface_set_mime_data (so embedding
  // images in to PDF/SVG output works optimally)

  free(data);
  return img->surf;
}

CGRect opal_CGImageGetSourceRect(CGImageRef image)
{
  if (CGRectIsNull(image->crop)) {
    return CGRectMake(0, 0, image->width, image->height);
  } else {
    return image->crop;
  }
}
