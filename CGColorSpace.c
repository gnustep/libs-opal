/** <title>CGColorSpace</title>

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

/* FIXME: Color Management is not implemented yet. Consequently, color spaces
 * are usually ignored and assumed to be deviceRGB. With most current equipment
 * supporting the sRGB color space, this may be OK in most cases, though.
 *
 * We should properly implement this once Cairo supports color management.
 */

#include "CGColorSpace.h"
#include "opal.h"

typedef struct CGColorSpace
{
  struct objbase base;
  int numcomps;
  CGColorSpaceModel model;
} CGColorSpace;

/* Return these for everything now */
static CGColorSpace deviceRGB =
{
  {"CGColorSpace", NULL, -1},
  3,
  kCGColorSpaceModelRGB
};

static CGColorSpace deviceGray =
{
  {"CGColorSpace", NULL, -1},
  1,
  kCGColorSpaceModelMonochrome
};



CFDataRef CGColorSpaceCopyICCProfile(CGColorSpaceRef cs)
{
  return NULL;
}

CFStringRef CGColorSpaceCopyName(CGColorSpaceRef cs)
{
  return NULL;
}

CGColorSpaceRef CGColorSpaceCreateCalibratedGray(
  const CGFloat *whitePoint,
  const CGFloat *blackPoint,
  CGFloat gamma)
{
  return &deviceGray;
}

CGColorSpaceRef CGColorSpaceCreateCalibratedRGB(
  const CGFloat *whitePoint,
  const CGFloat *blackPoint,
  const CGFloat *gamma,
  const CGFloat *matrix)
{
  return &deviceRGB;  
}

CGColorSpaceRef CGColorSpaceCreateDeviceCMYK()
{
  return &deviceRGB;  
}

CGColorSpaceRef CGColorSpaceCreateDeviceGray()
{
  return &deviceGray;  
}

CGColorSpaceRef CGColorSpaceCreateDeviceRGB()
{
  return &deviceRGB;  
}

CGColorSpaceRef CGColorSpaceCreateICCBased(
  size_t nComponents,
  const CGFloat *range,
  CGDataProviderRef profile,
  CGColorSpaceRef alternateSpace)
{
  return &deviceRGB;  
}

CGColorSpaceRef CGColorSpaceCreateIndexed(
  CGColorSpaceRef baseSpace,
  size_t lastIndex,
  const unsigned char *colorTable)
{
  return &deviceRGB;  
}  

CGColorSpaceRef CGColorSpaceCreateLab(
  const CGFloat *whitePoint,
  const CGFloat *blackPoint,
  const CGFloat *range)
{
  return &deviceRGB;  
}

CGColorSpaceRef CGColorSpaceCreatePattern(CGColorSpaceRef baseSpace)
{
  return baseSpace;
}

CGColorSpaceRef CGColorSpaceCreateWithICCProfile(CFDataRef data)
{
  return &deviceRGB;  
}

CGColorSpaceRef CGColorSpaceCreateWithName(opal_GenericColorSpaceNames name)
{
  switch (name) {
    case kCGColorSpaceGenericGray:
      return CGColorSpaceCreateDeviceGray();
    case kCGColorSpaceGenericRGB:
      return CGColorSpaceCreateDeviceRGB();
    case kCGColorSpaceGenericCMYK:
    default:
      errlog("%s:%d: Unknown colorspace name\n", __FILE__, __LINE__);
      return NULL;
  }
}

CGColorSpaceRef CGColorSpaceCreateWithPlatformColorSpace(
  void *platformColorSpace)
{
  return &deviceRGB;  
}

CGColorSpaceRef CGColorSpaceGetBaseColorSpace(CGColorSpaceRef cs)
{
  return cs;  
}

void CGColorSpaceGetColorTable(CGColorSpaceRef cs, unsigned char *table)
{
}

size_t CGColorSpaceGetColorTableCount(CGColorSpaceRef cs)
{
  return 0;
}

CGColorSpaceModel CGColorSpaceGetModel(CGColorSpaceRef cs)
{
  return cs->model;
}

size_t CGColorSpaceGetNumberOfComponents(CGColorSpaceRef cs)
{
  return cs->numcomps;
}


CGColorSpaceRef CGColorSpaceRetain(CGColorSpaceRef cs)
{
  /* NOP */
  return cs;
}

void CGColorSpaceRelease(CGColorSpaceRef cs)
{
  /* NOP */
}
