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
  int ismask;

  size_t width;
  size_t height;
  size_t bitsPerComponent;
  size_t bitsPerPixel;
  size_t bytesPerRow;
  CGDataProviderRef dp;
  CGFloat *decode;
  int shouldInterpolate;
  /* alphaInfo is always AlphaNone for mask */
  CGImageAlphaInfo alphaInfo;
  /* cspace and intent are only set for image */
  CGColorSpaceRef cspace;
  CGColorRenderingIntent intent;
} CGImage;

void opal_dealloc_CGImage(void *i)
{
  CGImageRef img = i;

  CGColorSpaceRelease(img->cspace);
  CGDataProviderRelease(img->dp);
  if (img->decode) free(img->decode);
  free(i);
}

static inline CGImageRef opal_CreateImage(
  size_t width, size_t height,
  size_t bitsPerComponent, size_t bitsPerPixel, size_t bytesPerRow,
  CGDataProviderRef provider, const CGFloat *decode, int shouldInterpolate,
  size_t numComponents, int hasAlpha)
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

  return img;
}

CGImageRef CGImageCreate(
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bitsPerPixel,
  size_t bytesPerRow,
  CGColorSpaceRef colorspace,
  CGImageAlphaInfo alphaInfo,
  CGDataProviderRef provider,
  const CGFloat *decode,
  int shouldInterpolate,
  CGColorRenderingIntent intent)
{
  CGImageRef img;
  size_t numComponents;
  int hasAlpha;

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

  img->alphaInfo = alphaInfo;
  img->cspace = CGColorSpaceRetain(colorspace);
  img->intent = intent;

  return img;
}

CGImageRef CGImageMaskCreate(
  size_t width, size_t height,
  size_t bitsPerComponent, size_t bitsPerPixel, size_t bytesPerRow,
  CGDataProviderRef provider, const CGFloat *decode, int shouldInterpolate)
{
  CGImageRef img;

  if (!provider) return NULL;
  img = opal_CreateImage(width, height,
                         bitsPerComponent, bitsPerPixel, bytesPerRow,
                         provider, decode, shouldInterpolate, 0, 1);
  if (!img) return NULL;

  img->ismask = 1;

  return img;
}

CGImageRef CGImageRetain(CGImageRef image)
{
  return (image ? opal_obj_retain(image) : NULL);
}

void CGImageRelease(CGImageRef image)
{
  if(image) opal_obj_release(image);
}

int CGImageIsMask(CGImageRef image)
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
  return image->alphaInfo;
}

CGDataProviderRef CGImageGetDataProvider(CGImageRef image)
{
  return image->dp;
}

const CGFloat *CGImageGetDecode(CGImageRef image)
{
  return image->decode;
}

int CGImageGetShouldInterpolate(CGImageRef image)
{
  return image->shouldInterpolate;
}

CGColorRenderingIntent CGImageGetRenderingIntent(CGImageRef image)
{
  return image->intent;
}

cairo_surface_t *opal_CGImageCreateSurfaceForImage(CGImageRef img)
{
  cairo_surface_t *surf;
  cairo_format_t cformat;
  unsigned char *data;
  size_t datalen;
  size_t numComponents = 0;
  int alphaLast = 0;
  int mask;

  /* The target is always 8 BPC 32 BPP for Cairo so should convert to this */
  /* (see also QA1037) */
  if (img->cspace)
    numComponents = CGColorSpaceGetNumberOfComponents(img->cspace);

  switch (img->alphaInfo) {
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

  /* FIXME: implement this */
  /* datalen = */

  mask = (1 << img->bitsPerComponent) - 1;

}
