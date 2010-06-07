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

#import <Foundation/NSString.h>

#include "CoreGraphics/CGColorSpace.h"
#include "opal.h"

const CFStringRef kCGColorSpaceGenericGray = @"kCGColorSpaceGenericGray";
const CFStringRef kCGColorSpaceGenericRGB = @"kCGColorSpaceGenericRGB";
const CFStringRef kCGColorSpaceGenericCMYK = @"kCGColorSpaceGenericCMYK";
const CFStringRef kCGColorSpaceGenericRGBLinear = @"kCGColorSpaceGenericRGBLinear";
const CFStringRef kCGColorSpaceAdobeRGB1998 = @"kCGColorSpaceAdobeRGB1998";
const CFStringRef kCGColorSpaceSRGB = @"kCGColorSpaceSRGB";
const CFStringRef kCGColorSpaceGenericGrayGamma2_2 = @"kCGColorSpaceGenericGrayGamma2_2";

typedef struct CGColorSpace
{
  struct objbase base;
  int numcomps;
  CGColorSpaceModel model;
  void (*todevice)(CGFloat *dest, const CGFloat comps[]);
} CGColorSpace;

static void opal_todev_rgb(CGFloat *dest, const CGFloat comps[]);
static void opal_todev_gray(CGFloat *dest, const CGFloat comps[]);
static void opal_todev_cmyk(CGFloat *dest, const CGFloat comps[]);

/* Return these for everything now */
static CGColorSpace deviceRGB =
{
  {"CGColorSpace", NULL, -1},
  3,
  kCGColorSpaceModelRGB,
  opal_todev_rgb
};

static CGColorSpace deviceGray =
{
  {"CGColorSpace", NULL, -1},
  1,
  kCGColorSpaceModelMonochrome,
  opal_todev_gray
};

static CGColorSpace deviceCMYK =
{
  {"CGColorSpace", NULL, -1},
  4,
  kCGColorSpaceModelCMYK,
  opal_todev_cmyk
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
  return &deviceCMYK;  
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

CGColorSpaceRef CGColorSpaceCreateWithName(CFStringRef name)
{
  if ([name isEqualToString: kCGColorSpaceGenericGray])
  {
    return CGColorSpaceCreateDeviceGray();
  }
  else if ([name isEqualToString: kCGColorSpaceGenericRGB])
  {
    return CGColorSpaceCreateDeviceRGB();
  }
  else if ([name isEqualToString: kCGColorSpaceGenericCMYK])
  {
    return CGColorSpaceCreateDeviceCMYK();
  }
  else
  {
    errlog("%s:%d: Unknown colorspace name\n", __FILE__, __LINE__);
  }
  return NULL;
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

CFTypeID CGColorSpaceGetTypeID()
{
  return NULL; 
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

static void opal_todev_rgb(CGFloat *dest, const CGFloat comps[])
{
  dest[0] = comps[0];
  dest[1] = comps[1];
  dest[2] = comps[2];
  dest[3] = comps[3];
}

static void opal_todev_gray(CGFloat *dest, const CGFloat comps[])
{
  dest[0] = comps[0];
  dest[1] = comps[0];
  dest[2] = comps[0];
  dest[3] = comps[1];
}

static void opal_todev_cmyk(CGFloat *dest, const CGFloat comps[])
{
  // DeviceCMYK to DeviceRGB conversion from PostScript Language Reference
  // section 7.2.4
  dest[0] = 1 - MIN(1.0, comps[0] + comps[3]);
  dest[1] = 1 - MIN(1.0, comps[1] + comps[3]);
  dest[2] = 1 - MIN(1.0, comps[2] + comps[3]);
  dest[3] = comps[4];
}

/* FIXME: This sould really convert to the color space of the device,
 * but Cairo only knows about RGBA, so we convert to that */
void opal_cspace_todev(CGColorSpaceRef cs, CGFloat *dest, const CGFloat comps[])
{
  cs->todevice(dest, comps);
}
