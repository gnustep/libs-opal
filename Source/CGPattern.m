/** <title>CGPattern</title>
 
 <abstract>C Interface to graphics drawing library</abstract>
 
 Copyright <copy>(C) 2009 Free Software Foundation, Inc.</copy>

 Author: Eric Wasylishen
 Date: Dec 2009
 
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

#include <stdlib.h>
#include "CoreGraphics/CGPattern.h"
#include "opal.h"

typedef struct CGPattern
{
  struct objbase base;
  void *info;
  
} CGPattern;

void opal_dealloc_CGPattern(void *p)
{
  CGPatternRef pattern = p;
  free(pattern);
}

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
  CGPatternRef pattern = opal_obj_alloc("CGPattern", sizeof(CGPattern));
  if (!pattern) return NULL;
  
  // FIXME

  return pattern;
}

CGPatternRef CGPatternRetain(CGPatternRef pattern)
{
  return (pattern ? opal_obj_retain(pattern) : NULL);
}

void CGPatternRelease(CGPatternRef pattern)
{
  if (pattern) opal_obj_release(pattern);
}


