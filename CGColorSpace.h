/** <title>CGColorSpace</title>

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

#ifndef OPAL_CGColorSpace_h
#define OPAL_CGColorSpace_h

#include <CGDataProvider.h>

/* Data Types */

typedef struct CGColorSpace * CGColorSpaceRef;

/* Constants */

typedef enum CGColorRenderingIntent {
  kCGRenderingIntentDefault = 0,
  kCGRenderingIntentAbsoluteColorimetric = 1,
  kCGRenderingIntentRelativeColorimetric = 2,
  kCGRenderingIntentPerceptual = 3,
  kCGRenderingIntentSaturation = 4
} CGColorRenderingIntent;

typedef enum opal_GenericColorSpaceNames {
  kCGColorSpaceGenericGray = 0,
  kCGColorSpaceGenericRGB = 1,
  kCGColorSpaceGenericCMYK = 2
} opal_GenericColorSpaceNames;

/* Functions */

CGColorSpaceRef CGColorSpaceCreateDeviceGray(void);

CGColorSpaceRef CGColorSpaceCreateDeviceRGB(void);

CGColorSpaceRef CGColorSpaceCreateDeviceCMYK(void);

CGColorSpaceRef CGColorSpaceCreateCalibratedGray(
  const float *whitePoint,
  const float *blackPoint,
  float gamma
);

CGColorSpaceRef CGColorSpaceCreateCalibratedRGB(
  const float *whitePoint,
  const float *blackPoint,
  const float *gamma,
  const float *matrix
);

CGColorSpaceRef CGColorSpaceCreateLab(
  const float *whitePoint,
  const float *blackPoint,
  const float *range
);

CGColorSpaceRef CGColorSpaceCreateICCBased(
  size_t nComponents,
  const float *range,
  CGDataProviderRef profile,
  CGColorSpaceRef alternateSpace
);

CGColorSpaceRef CGColorSpaceCreateIndexed(
  CGColorSpaceRef baseSpace,
  size_t lastIndex,
  const unsigned char *colorTable
);

CGColorSpaceRef CGColorSpaceCreateWithPlatformColorSpace(
  void *platformColorSpace
);

CGColorSpaceRef CGColorSpaceCreateWithName(opal_GenericColorSpaceNames name);

CGColorSpaceRef CGColorSpaceCreatePattern(CGColorSpaceRef baseSpace);

size_t CGColorSpaceGetNumberOfComponents(CGColorSpaceRef cs);

CGColorSpaceRef CGColorSpaceRetain(CGColorSpaceRef cs);

void CGColorSpaceRelease(CGColorSpaceRef cs);

#endif /* OPAL_CGColorSpace_h */
