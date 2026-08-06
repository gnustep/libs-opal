/** <title>CGPattern</title>

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
#include "CGPattern-private.h"

@interface CGPattern : NSObject
{
@public
  void *info;
  CGRect bounds;
  CGAffineTransform matrix;
  CGFloat xStep;
  CGFloat yStep;
  CGPatternTiling tiling;
  bool isColored;
  CGPatternCallbacks callbacks;
}
@end

@implementation CGPattern

- (void) dealloc
{
  if (callbacks.releaseInfo)
    {
      callbacks.releaseInfo(info);
    }
  [super dealloc];
}

@end


CGPatternRef CGPatternCreate(
  void *info,
  CGRect bounds,
  CGAffineTransform matrix,
  CGFloat xStep,
  CGFloat yStep,
  CGPatternTiling tiling,
  int isColored,
  const CGPatternCallbacks *callbacks)
{
  CGPattern *pattern = [[CGPattern alloc] init];

  pattern->info = info;
  pattern->bounds = bounds;
  pattern->matrix = matrix;
  pattern->xStep = xStep;
  pattern->yStep = yStep;
  pattern->tiling = tiling;
  pattern->isColored = isColored ? true : false;
  if (callbacks)
    {
      pattern->callbacks = *callbacks;
    }
  else
    {
      memset(&pattern->callbacks, 0, sizeof(CGPatternCallbacks));
    }

  return pattern;
}

CFTypeID CGPatternGetTypeID()
{
  return (CFTypeID)[CGPattern class];
}

CGPatternRef CGPatternRetain(CGPatternRef pattern)
{
  return [pattern retain];
}

void CGPatternRelease(CGPatternRef pattern)
{
  [pattern release];
}

CGRect OPPatternGetBounds(CGPatternRef pattern)
{
  return pattern ? pattern->bounds : CGRectZero;
}

CGAffineTransform OPPatternGetMatrix(CGPatternRef pattern)
{
  return pattern ? pattern->matrix : CGAffineTransformIdentity;
}

CGFloat OPPatternGetXStep(CGPatternRef pattern)
{
  return pattern ? pattern->xStep : 0;
}

CGFloat OPPatternGetYStep(CGPatternRef pattern)
{
  return pattern ? pattern->yStep : 0;
}

bool OPPatternIsColored(CGPatternRef pattern)
{
  return pattern ? pattern->isColored : false;
}

void OPPatternDrawInContext(CGPatternRef pattern, CGContextRef ctx)
{
  if (pattern && pattern->callbacks.drawPattern)
    {
      pattern->callbacks.drawPattern(pattern->info, ctx);
    }
}
