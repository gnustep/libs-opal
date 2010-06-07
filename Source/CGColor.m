/** <title>CGColor</title>

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

#include "CoreGraphics/CGContext.h"
#include "CoreGraphics/CGColor.h"
#include "opal.h"
#include "stdlib.h"

typedef struct CGColor
{
  struct objbase base;
  CGColorSpaceRef cspace;
  CGFloat *comps;
  CGPatternRef pattern;
} CGColor;

// FIXME: Make real CFStrings
const CFStringRef kCGColorWhite = (void *)"kCGColorWhite";
const CFStringRef kCGColorBlack = (void *)"kCGColorBlack";
const CFStringRef kCGColorClear = (void *)"kCGColorClear";

static CGColorRef _whiteColor;
static CGColorRef _blackColor;
static CGColorRef _clearColor;

CGColorRef CGColorCreate(CGColorSpaceRef colorspace, const CGFloat components[])
{
  CGColorRef clr;
  size_t nc, i;

  clr = opal_obj_alloc("CGColor", sizeof(CGColor));
  if (!clr) return NULL;

  nc = CGColorSpaceGetNumberOfComponents(colorspace);
  clr->comps = malloc((nc+1)*sizeof(CGFloat));
  if (!clr->comps) {
    errlog("%s:%d: malloc failed\n", __FILE__, __LINE__);
    free(clr);
    return NULL;
  }
  clr->cspace = colorspace;
  CGColorSpaceRetain(colorspace);
  clr->pattern = NULL;
  for (i=0; i<=nc; i++)
    clr->comps[i] = components[i];

  return clr;
}

void opal_dealloc_CGColor(void *clr)
{
  CGColorRef c = clr;

  CGColorSpaceRelease(c->cspace);
  CGPatternRelease(c->pattern);
  free(c->comps);
  free(c);
}

CFTypeID CGColorGetTypeID()
{
   
}

CGColorRef CGColorRetain(CGColorRef clr)
{
  return (clr ? opal_obj_retain(clr) : clr);
}

void CGColorRelease(CGColorRef clr)
{
  if(clr) opal_obj_release(clr);
}

CGColorRef CGColorCreateCopy(CGColorRef clr)
{
  return CGColorCreate(clr->cspace, clr->comps);
}

CGColorRef CGColorCreateCopyWithAlpha(CGColorRef clr, CGFloat alpha)
{
  CGColorRef newclr;

  newclr = CGColorCreate(clr->cspace, clr->comps);
  if (!newclr) return NULL;

  newclr->comps[CGColorSpaceGetNumberOfComponents(newclr->cspace)] = alpha;
  return newclr;
}

CGColorRef CGColorCreateGenericCMYK(
  CGFloat cyan,
  CGFloat magenta,
  CGFloat yellow,
  CGFloat black,
  CGFloat alpha)
{
  CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceCMYK();
  const CGFloat components[] = {cyan, magenta, yellow, black, alpha};
  CGColorRef clr = CGColorCreate(colorspace, components);
  CGColorSpaceRelease(colorspace);
  return clr;
}

CGColorRef CGColorCreateGenericGray(CGFloat gray, CGFloat alpha)
{
  CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
  const CGFloat components[] = {gray, alpha};
  CGColorRef clr = CGColorCreate(colorspace, components);
  CGColorSpaceRelease(colorspace);
  return clr;
}

CGColorRef CGColorCreateGenericRGB(
  CGFloat red,
  CGFloat green,
  CGFloat blue,
  CGFloat alpha)
{
  CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
  const CGFloat components[] = {red, green, blue, alpha};
  CGColorRef clr = CGColorCreate(colorspace, components);
  CGColorSpaceRelease(colorspace);
  return clr;
}

CGColorRef CGColorCreateWithPattern(
  CGColorSpaceRef colorspace,
  CGPatternRef pattern,
  const CGFloat components[])
{
  CGColorRef clr = CGColorCreate(colorspace, components);
  clr->pattern = CGPatternRetain(pattern);
  return clr;
}

bool CGColorEqualToColor(CGColorRef color1, CGColorRef color2)
{
  int nc = CGColorSpaceGetNumberOfComponents(color1->cspace);
  int i;

  if (color1->cspace != color2->cspace) return false;
  if (color1->pattern != color2->pattern) return false;
  
  for (i = 0; i <= nc; i++) {
    if (color1->comps[i] != color2->comps[i])
      return false;
  }
  return true;
}

CGFloat CGColorGetAlpha(CGColorRef clr)
{
  return clr->comps[CGColorSpaceGetNumberOfComponents(clr->cspace)];
}

CGColorSpaceRef CGColorGetColorSpace(CGColorRef clr)
{
  return clr->cspace;
}

const CGFloat *CGColorGetComponents(CGColorRef clr)
{
  return clr->comps;
}

CGColorRef CGColorGetConstantColor(CFStringRef name)
{
  if (name == kCGColorWhite) {
    if (!_whiteColor) {
      _whiteColor = CGColorCreateGenericGray(1, 1);
    }
    return  _whiteColor;
  } else if (name == kCGColorBlack) {
    if (!_blackColor) {
      _blackColor = CGColorCreateGenericGray(0, 1);
    }
    return _whiteColor;
  } else if (name == kCGColorClear) {
    if (!_clearColor) {
      _clearColor = CGColorCreateGenericGray(0, 0);
    }
    return _clearColor;
  }
  return NULL;
}

size_t CGColorGetNumberOfComponents(CGColorRef clr)
{
  return CGColorSpaceGetNumberOfComponents(clr->cspace);
}

CGPatternRef CGColorGetPattern(CGColorRef clr)
{
  return clr->pattern;
}
