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

static void opal_todev_rgb(CGFloat *dest, const CGFloat comps[]);
static void opal_todev_gray(CGFloat *dest, const CGFloat comps[]);
static void opal_todev_cmyk(CGFloat *dest, const CGFloat comps[]);

static CGColorSpaceRef _deviceRGB;
static CGColorSpaceRef _deviceGray;
static CGColorSpaceRef _deviceCMYK;



@interface CGColorSpace : NSObject
{
@public
  CGColorSpaceRef cspace;
  int numcomps;
  CGColorSpaceModel model;
  void (*todevice)(CGFloat *dest, const CGFloat comps[]);
}
@end

@implementation CGColorSpace

+ (void) load
{
  _deviceRGB = [[CGColorSpace alloc] init];
  _deviceRGB->numcomps = 3;
  _deviceRGB->model = kCGColorSpaceModelRGB;
  _deviceRGB->todevice = opal_todev_rgb;
  
  _deviceGray = [[CGColorSpace alloc] init];
  _deviceGray->numcomps = 1;
  _deviceGray->model = kCGColorSpaceModelMonochrome;
  _deviceGray->todevice = opal_todev_gray;
  
  _deviceCMYK = [[CGColorSpace alloc] init];
  _deviceCMYK->numcomps = 4;
  _deviceCMYK->model = kCGColorSpaceModelCMYK;
  _deviceCMYK->todevice = opal_todev_cmyk;  
} 

- (void) dealloc
{
  [super dealloc];    
}

- (BOOL) isEqual: (id)other
{
  if (![other isKindOfClass: [CGColorSpace class]])
  {
    return NO;
  }
  
  CGColorSpace *otherCS = (CGColorSpace *)other;
   
  return (otherCS->numcomps == self->numcomps
    && otherCS->model == self->model
    && otherCS->cspace == self->cspace
    && otherCS->todevice == self->todevice); // FIXME: will not accomodate all colorspace types
}

@end




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
  return _deviceGray;
}

CGColorSpaceRef CGColorSpaceCreateCalibratedRGB(
  const CGFloat *whitePoint,
  const CGFloat *blackPoint,
  const CGFloat *gamma,
  const CGFloat *matrix)
{
  return _deviceRGB;  
}

CGColorSpaceRef CGColorSpaceCreateDeviceCMYK()
{
  return _deviceCMYK;  
}

CGColorSpaceRef CGColorSpaceCreateDeviceGray()
{
  return _deviceGray;  
}

CGColorSpaceRef CGColorSpaceCreateDeviceRGB()
{
  return _deviceRGB;  
}

CGColorSpaceRef CGColorSpaceCreateICCBased(
  size_t nComponents,
  const CGFloat *range,
  CGDataProviderRef profile,
  CGColorSpaceRef alternateSpace)
{
  return _deviceRGB;  
}

CGColorSpaceRef CGColorSpaceCreateIndexed(
  CGColorSpaceRef baseSpace,
  size_t lastIndex,
  const unsigned char *colorTable)
{
  return _deviceRGB;  
}  

CGColorSpaceRef CGColorSpaceCreateLab(
  const CGFloat *whitePoint,
  const CGFloat *blackPoint,
  const CGFloat *range)
{
  return _deviceRGB;  
}

CGColorSpaceRef CGColorSpaceCreatePattern(CGColorSpaceRef baseSpace)
{
  return baseSpace;
}

CGColorSpaceRef CGColorSpaceCreateWithICCProfile(CFDataRef data)
{
  return _deviceRGB;  
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
  return _deviceRGB;  
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
  return ((CGColorSpace *)cs)->model;
}

size_t CGColorSpaceGetNumberOfComponents(CGColorSpaceRef cs)
{
  return ((CGColorSpace *)cs)->numcomps;
}

CFTypeID CGColorSpaceGetTypeID()
{
  return [CGColorSpace class]; 
}

CGColorSpaceRef CGColorSpaceRetain(CGColorSpaceRef cs)
{
  return (CGColorSpaceRef)[(CGColorSpace *)cs retain];
}

void CGColorSpaceRelease(CGColorSpaceRef cs)
{
  [(CGColorSpace *)cs release];
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
  ((CGColorSpace *)cs)->todevice(dest, comps);
}
