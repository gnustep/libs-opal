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

#include <CoreFoundation.h>
#include <CGBase.h>
#include <CGDataProvider.h>

/* Data Types */

typedef struct CGColorSpace * CGColorSpaceRef;

typedef enum CGColorSpaceModel {
  kCGColorSpaceModelUnknown = -1,
  kCGColorSpaceModelMonochrome = 0,
  kCGColorSpaceModelRGB = 1,
  kCGColorSpaceModelCMYK = 2,
  kCGColorSpaceModelLab = 3,
  kCGColorSpaceModelDeviceN = 4,
  kCGColorSpaceModelIndexed = 5,
  kCGColorSpaceModelPattern = 6
} CGColorSpaceModel;


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

CFDataRef CGColorSpaceCopyICCProfile(CGColorSpaceRef cs);

CFStringRef CGColorSpaceCopyName(CGColorSpaceRef cs);

CGColorSpaceRef CGColorSpaceCreateCalibratedGray(
  const CGFloat *whitePoint,
  const CGFloat *blackPoint,
  CGFloat gamma
);

CGColorSpaceRef CGColorSpaceCreateCalibratedRGB(
  const CGFloat *whitePoint,
  const CGFloat *blackPoint,
  const CGFloat *gamma,
  const CGFloat *matrix
);

CGColorSpaceRef CGColorSpaceCreateDeviceCMYK();

CGColorSpaceRef CGColorSpaceCreateDeviceGray();

CGColorSpaceRef CGColorSpaceCreateDeviceRGB();

CGColorSpaceRef CGColorSpaceCreateICCBased(
  size_t nComponents,
  const CGFloat *range,
  CGDataProviderRef profile,
  CGColorSpaceRef alternateSpace
);

CGColorSpaceRef CGColorSpaceCreateIndexed(
  CGColorSpaceRef baseSpace,
  size_t lastIndex,
  const unsigned char *colorTable
);

CGColorSpaceRef CGColorSpaceCreateLab(
  const CGFloat *whitePoint,
  const CGFloat *blackPoint,
  const CGFloat *range
);

CGColorSpaceRef CGColorSpaceCreatePattern(CGColorSpaceRef baseSpace);

CGColorSpaceRef CGColorSpaceCreateWithICCProfile(CFDataRef data);

CGColorSpaceRef CGColorSpaceCreateWithName(opal_GenericColorSpaceNames name);

CGColorSpaceRef CGColorSpaceCreateWithPlatformColorSpace(
  void *platformColorSpace
);

CGColorSpaceRef CGColorSpaceGetBaseColorSpace(CGColorSpaceRef cs);

void CGColorSpaceGetColorTable(CGColorSpaceRef cs, unsigned char *table);

size_t CGColorSpaceGetColorTableCount(CGColorSpaceRef cs);

CGColorSpaceModel CGColorSpaceGetModel(CGColorSpaceRef cs);

size_t CGColorSpaceGetNumberOfComponents(CGColorSpaceRef cs);

CGColorSpaceRef CGColorSpaceRetain(CGColorSpaceRef cs);

void CGColorSpaceRelease(CGColorSpaceRef cs);

#endif /* OPAL_CGColorSpace_h */
