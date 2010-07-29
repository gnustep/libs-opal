/** <title>CGColorSpace</title>

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

#import <Foundation/NSObject.h>

#include "CoreGraphics/CGColorSpace.h"

#import "OPImageConversion.h"

@interface OPColorTransform : NSObject
{
}

- (void) transformPixelData: (const unsigned char *)input
                     output: (char *)output;

@end


/** 
 * Abstract superclass for color spaces.
 */
@interface CGColorSpace : NSObject
{
}

+ (CGColorSpace *)colorSpaceGenericGray;
+ (CGColorSpace *)colorSpaceGenericRGB;
+ (CGColorSpace *)colorSpaceGenericCMYK;
+ (CGColorSpace *)colorSpaceGenericRGBLinear;
+ (CGColorSpace *)colorSpaceAdobeRGB1998;
+ (CGColorSpace *)colorSpaceSRGB;
+ (CGColorSpace *)colorSpaceGenericGrayGamma2_2;

- (NSData*)ICCProfile;
- (NSString*)name;
- (id)initWithCalibratedGrayWithWhitePoint: (const CGFloat*)whitePoint
                                blackPoint: (const CGFloat*)blackPoint
                                     gamma: (CGFloat)gamma;
- (id)initWithCalibratedRGBWithWhitePoint: (const CGFloat*)whitePoint
                               blackPoint: (const CGFloat*)blackPoint
                                    gamma: (const CGFloat *)gamma
                                   matrix: (const CGFloat *)matrix;
- (id)initDeviceCMYK;
- (id)initDeviceGray;
- (id)initDeviceRGB;
- (id)initICCBasedWithComponents: (size_t)nComponents
                           range: (const CGFloat*)range
                         profile: (CGDataProviderRef)profile
                  alternateSpace: (CGColorSpaceRef)alternateSpace;
- (CGColorSpaceRef) initIndexedWithBaseSpace: (CGColorSpaceRef)baseSpace
                                   lastIndex: (size_t)lastIndex
                                  colorTable: (const unsigned char *)colorTable;
- (CGColorSpaceRef) initLabWithWhitePoint: (const CGFloat*)whitePoint
                               blackPoint: (const CGFloat*)blackPoint
                                    range: (const CGFloat*)range;
- (CGColorSpaceRef) initPatternWithBaseSpace: (CGColorSpaceRef)baseSpace;
- (CGColorSpaceRef) initWithICCProfile: (CFDataRef)data;
- (CGColorSpaceRef) initWithName: (NSString *)name;
- (CGColorSpaceRef) initWithPlatformColorSpace: (void *)platformColorSpace;
- (CGColorSpaceRef) baseColorSpace;
- (void) getColorTable: (uint8_t*)table;
- (size_t) colorTableCount;
- (CGColorSpaceModel) model;
- (size_t) numberOfComponents;

- (OPColorTransform*) colorTransformTo: (CGColorSpace *)aColorSpace
                          sourceFormat: (OPImageFormat)aSourceFormat
                     destinationFormat: (OPImageFormat)aDestFormat
                       renderingIntent: (CGColorRenderingIntent)anIntent
                            pixelCount: (size_t)aPixelCount;

@end

