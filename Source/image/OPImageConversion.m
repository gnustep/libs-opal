/** <title>CGImage-conversion.m</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen <ewasylishen@gmail.com>
   Date: July, 2010
   
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


#include <lcms.h>
#import <Foundation/NSString.h>
#include "CoreGraphics/CGColorSpace.h"
#include "CoreGraphics/CGImage.h"

static int LcmsIntentForCGColorRenderingIntent(CGColorRenderingIntent intent)
{
  switch (intent)
  {
    default:
    case kCGRenderingIntentDefault:
      return INTENT_RELATIVE_COLORIMETRIC; // FIXME: what should we do here?
    case kCGRenderingIntentAbsoluteColorimetric:
      return INTENT_ABSOLUTE_COLORIMETRIC;
    case kCGRenderingIntentRelativeColorimetric:
      return INTENT_RELATIVE_COLORIMETRIC;
    case kCGRenderingIntentPerceptual:
      return INTENT_PERCEPTUAL;
    case kCGRenderingIntentSaturation:
      return INTENT_SATURATION;
  }
}

static int LcmsPixelTypeForCGColorSpaceModel(CGColorSpaceModel model)
{
  switch (model)
  {
    case kCGColorSpaceModelMonochrome:
      return PT_GRAY;
    case kCGColorSpaceModelRGB:
      return PT_RGB;
    case kCGColorSpaceModelCMYK:
      return PT_CMYK;
    case kCGColorSpaceModelLab:
      return PT_Lab;
    case kCGColorSpaceModelUnknown:
    case kCGColorSpaceModelDeviceN:
    case kCGColorSpaceModelIndexed:
    case kCGColorSpaceModelPattern:
    default:
      return PT_ANY;
  }
}
  
static bool LcmsFormatForCGFormat(
  size_t bitsPerComponent,
  size_t bitsPerPixel,
  CGBitmapInfo info,
  CGColorSpaceRef colorSpace,
  DWORD *outFormat)
{    
  DWORD format = 0;
  
  if (info & kCGBitmapFloatComponents)
  {
    // LCMS 2 supports floats
    NSLog(@"Floats not supported");
    return false;
  }
  
  if (bitsPerComponent % 8 != 0)
  {
    NSLog(@"Only multiples of 8 BPC supported");
    return false;
  }

  if (bitsPerPixel % bitsPerComponent != 0)
  {
    NSLog(@"bitsPerPixel not a multiple of bitsPerComponent");
    return false;
  }
  
  size_t colorComponents = CGColorSpaceGetNumberOfComponents(colorSpace);
  size_t actualComponents = bitsPerPixel / bitsPerComponent;
  CGImageAlphaInfo alpha = info & kCGBitmapAlphaInfoMask;
  
  format |= BYTES_SH(bitsPerComponent / 8);
  format |= CHANNELS_SH(colorComponents);
  
  if (colorComponents == actualComponents - 1)
  {
    format |= EXTRA_SH(1);
    if (alpha == kCGImageAlphaFirst ||
       alpha == kCGImageAlphaNoneSkipFirst ||
       alpha == kCGImageAlphaPremultipliedFirst)
    {
      format |= SWAPFIRST_SH(1);
    }
  }
  else if (colorComponents != actualComponents)
  {
    NSLog(@"colorComponents don't make sense");
    return false;
  }  
  
  format |= COLORSPACE_SH(
      LcmsPixelTypeForCGColorSpaceModel(
        CGColorSpaceGetModel(colorSpace)
      )
    );
  
  *outFormat = format;
  return true;
}

bool OPImageConvert(
  unsigned char *dstData,
  const unsigned char *srcData, 
  size_t width,
  size_t height,
  size_t dstBitsPerComponent,
  size_t srcBitsPerComponent,
  size_t dstBitsPerPixel,
  size_t srcBitsPerPixel,
  size_t dstBytesPerRow,
  size_t srcBytesPerRow,
  CGBitmapInfo dstBitmapInfo,
  CGBitmapInfo srcBitmapInfo,
  CGColorSpaceRef dstColorSpace, 
  CGColorSpaceRef srcColorSpace,
  CGColorRenderingIntent intent)
{
  DWORD lcmsSrcFormat, lcmsDstFormat;
  
  if (!LcmsFormatForCGFormat(srcBitsPerComponent, srcBitsPerPixel, srcBitmapInfo, srcColorSpace, &lcmsSrcFormat))
  {
    NSLog(@"Couldn't find LCMS format for source format");
    return false;   
  }
  if (!LcmsFormatForCGFormat(dstBitsPerComponent, dstBitsPerPixel, dstBitmapInfo, dstColorSpace, &lcmsDstFormat))
  {
    NSLog(@"Couldn't find LCMS format for dest format");
    return false;   
  }
  
  cmsHPROFILE srgb = cmsCreate_sRGBProfile();
  
  cmsHTRANSFORM xform = cmsCreateTransform(srgb, lcmsSrcFormat, srgb, lcmsDstFormat, 
    LcmsIntentForCGColorRenderingIntent(intent), 0);
  
  for (size_t row = 0; row < height; row++)
  {
    unsigned char *dstRow = dstData + (dstBytesPerRow * row);
    const unsigned char *srcRow =  srcData + (srcBytesPerRow * row);
    cmsDoTransform(xform, (void*)srcRow, dstRow, width);
  }
  
  cmsDeleteTransform(xform);
  
  return true;
}
