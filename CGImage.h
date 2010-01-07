/** <title>CGImage</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright (C) 2006 BALATON Zoltan <balaton@eik.bme.hu>

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

#include <CGColorSpace.h>

/* Data Types */

typedef struct CGImage *  CGImageRef;

/* Constants */

typedef enum CGImageAlphaInfo
{
  kCGImageAlphaNone = 0,
  kCGImageAlphaPremultipliedLast = 1,
  kCGImageAlphaPremultipliedFirst = 2,
  kCGImageAlphaLast = 3,
  kCGImageAlphaFirst = 4,
  kCGImageAlphaNoneSkipLast = 5,
  kCGImageAlphaNoneSkipFirst = 6,
  kCGImageAlphaOnly = 7
} CGImageAlphaInfo;

/* Drawing Images */

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
  CGColorRenderingIntent intent
);

CGImageRef CGImageMaskCreate(
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bitsPerPixel,
  size_t bytesPerRow,
  CGDataProviderRef provider,
  const CGFloat *decode,
  int shouldInterpolate
);

CGImageRef CGImageRetain(CGImageRef image);

void CGImageRelease(CGImageRef image);

int CGImageIsMask(CGImageRef image);

size_t CGImageGetWidth(CGImageRef image);

size_t CGImageGetHeight(CGImageRef image);

size_t CGImageGetBitsPerComponent(CGImageRef image);

size_t CGImageGetBitsPerPixel(CGImageRef image);

size_t CGImageGetBytesPerRow(CGImageRef image);

CGColorSpaceRef CGImageGetColorSpace(CGImageRef image);

CGImageAlphaInfo CGImageGetAlphaInfo(CGImageRef image);

CGDataProviderRef CGImageGetDataProvider(CGImageRef image);

const CGFloat *CGImageGetDecode(CGImageRef image);

int CGImageGetShouldInterpolate(CGImageRef image);

CGColorRenderingIntent CGImageGetRenderingIntent(CGImageRef image);

#endif /* OPAL_CGImage_h */
