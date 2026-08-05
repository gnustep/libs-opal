/** <title>CGShading</title>

 <abstract>C Interface to graphics drawing library</abstract>

 Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

 Author: Eric Wasylishen
 Date: June 2010

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
#include "CGShading-private.h"
#include "CoreGraphics/CGColorSpace.h"

@interface CGShading : NSObject
{
@public
  bool radial;
  CGColorSpaceRef colorspace;
  CGPoint start;
  CGPoint end;
  CGFloat startRadius;
  CGFloat endRadius;
  CGFunctionRef function;
  bool extendStart;
  bool extendEnd;
}
@end

@implementation CGShading

- (void) dealloc
{
  CGColorSpaceRelease(colorspace);
  CGFunctionRelease(function);
  [super dealloc];
}

@end

CGShadingRef CGShadingCreateAxial(
  CGColorSpaceRef colorspace,
  CGPoint start,
  CGPoint end,
  CGFunctionRef function,
  int extendStart,
  int extendEnd)
{
  CGShading *shading = [[CGShading alloc] init];

  shading->radial = false;
  shading->colorspace = CGColorSpaceRetain(colorspace);
  shading->start = start;
  shading->end = end;
  shading->startRadius = 0;
  shading->endRadius = 0;
  shading->function = CGFunctionRetain(function);
  shading->extendStart = extendStart ? true : false;
  shading->extendEnd = extendEnd ? true : false;

  return shading;
}

CGShadingRef CGShadingCreateRadial(
  CGColorSpaceRef colorspace,
  CGPoint start,
  CGFloat startRadius,
  CGPoint end,
  CGFloat endRadius,
  CGFunctionRef function,
  int extendStart,
  int extendEnd)
{
  CGShading *shading = [[CGShading alloc] init];

  shading->radial = true;
  shading->colorspace = CGColorSpaceRetain(colorspace);
  shading->start = start;
  shading->end = end;
  shading->startRadius = startRadius;
  shading->endRadius = endRadius;
  shading->function = CGFunctionRetain(function);
  shading->extendStart = extendStart ? true : false;
  shading->extendEnd = extendEnd ? true : false;

  return shading;
}

CFTypeID CGShadingGetTypeID()
{
  return (CFTypeID)[CGShading class];
}

CGShadingRef CGShadingRetain(CGShadingRef shading)
{
  return [shading retain];
}

void CGShadingRelease(CGShadingRef shading)
{
  [shading release];
}

bool OPShadingIsRadial(CGShadingRef shading)
{
  return shading ? shading->radial : false;
}

CGColorSpaceRef OPShadingGetColorSpace(CGShadingRef shading)
{
  return shading ? shading->colorspace : NULL;
}

CGFunctionRef OPShadingGetFunction(CGShadingRef shading)
{
  return shading ? shading->function : NULL;
}

CGPoint OPShadingGetStart(CGShadingRef shading)
{
  return shading ? shading->start : CGPointZero;
}

CGPoint OPShadingGetEnd(CGShadingRef shading)
{
  return shading ? shading->end : CGPointZero;
}

CGFloat OPShadingGetStartRadius(CGShadingRef shading)
{
  return shading ? shading->startRadius : 0;
}

CGFloat OPShadingGetEndRadius(CGShadingRef shading)
{
  return shading ? shading->endRadius : 0;
}

bool OPShadingGetExtendStart(CGShadingRef shading)
{
  return shading ? shading->extendStart : false;
}

bool OPShadingGetExtendEnd(CGShadingRef shading)
{
  return shading ? shading->extendEnd : false;
}
