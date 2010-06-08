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

//FIXME: should not need
#import <Foundation/NSString.h>
#import <Foundation/NSObject.h>
#include <CoreFoundation/CFString.h>
#include "CoreGraphics/CGContext.h"
#include "CoreGraphics/CGColor.h"
#include "opal.h"

const CFStringRef kCGColorWhite = CFSTR("kCGColorWhite");
const CFStringRef kCGColorBlack = CFSTR("kCGColorBlack");
const CFStringRef kCGColorClear = CFSTR("kCGColorClear");

static CGColorRef _whiteColor;
static CGColorRef _blackColor;
static CGColorRef _clearColor;


@interface CGColor : NSObject
{
@public
  CGColorSpaceRef cspace;
  CGFloat *comps;
  CGPatternRef pattern;
}
@end

@implementation CGColor

- (id) initWithColorSpace: (CGColorSpaceRef)cs components: (const CGFloat*)components
{
  self = [super init];
  if (NULL == self) return NULL;

  size_t nc, i;
  nc = CGColorSpaceGetNumberOfComponents(cs);
  self->comps = malloc((nc+1)*sizeof(CGFloat));
  if (NULL == self->comps) {
    errlog("%s:%d: malloc failed\n", __FILE__, __LINE__);
    [self release];
    return NULL;
  }
  self->cspace = CGColorSpaceRetain(cs);
  self->pattern = NULL;
  for (i=0; i<=nc; i++)
    self->comps[i] = components[i];    
  return self;  
}

- (void) dealloc
{
  CGColorSpaceRelease(self->cspace);
  CGPatternRelease(self->pattern);
  free(self->comps);
  [super dealloc];    
}

- (BOOL) isEqual: (id)other
{
  if (![other isKindOfClass: [CGColor class]]) return NO;
  
  int nc = CGColorSpaceGetNumberOfComponents(((CGColor*)self)->cspace);
  int i;

  if (!CFEqual(((CGColor*)self)->cspace, ((CGColor*)other)->cspace)) return NO;
  if (!CFEqual(((CGColor*)self)->pattern, ((CGColor*)other)->pattern)) return NO;
  
  for (int i = 0; i <= nc; i++) {
    if (((CGColor*)self)->comps[i] != ((CGColor*)other)->comps[i])
      return NO;
  }
  return YES;
}

@end


CGColorRef CGColorCreate(CGColorSpaceRef colorspace, const CGFloat components[])
{
  CGColor *clr = [[CGColor alloc] initWithColorSpace: colorspace components: components];
  return (CGColorRef)clr;
}

CFTypeID CGColorGetTypeID()
{
  return (CFTypeID)[CGColor class];   
}

CGColorRef CGColorRetain(CGColorRef clr)
{
  return [(CGColor*)clr retain];
}

void CGColorRelease(CGColorRef clr)
{
  [(CGColor*)clr release];
}

CGColorRef CGColorCreateCopy(CGColorRef clr)
{
  return CGColorCreate(((CGColor*)clr)->cspace, ((CGColor*)clr)->comps);
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
  ((CGColor*)clr)->pattern = CGPatternRetain(pattern);
  return clr;
}

bool CGColorEqualToColor(CGColorRef color1, CGColorRef color2)
{
  return CFEqual(color1, color2);
}

CGFloat CGColorGetAlpha(CGColorRef clr)
{
  int alphaIndex = CGColorSpaceGetNumberOfComponents(((CGColor*)clr)->cspace);
  return ((CGColor*)clr)->comps[alphaIndex];
}

CGColorSpaceRef CGColorGetColorSpace(CGColorRef clr)
{
  return ((CGColor*)clr)->cspace;
}

const CGFloat *CGColorGetComponents(CGColorRef clr)
{
  return ((CGColor*)clr)->comps;
}

CGColorRef CGColorGetConstantColor(CFStringRef name)
{
  if (CFEqual(name, kCGColorWhite))
  {
    if (NULL == _whiteColor)
    {
      _whiteColor = CGColorCreateGenericGray(1, 1);
    }
    return  _whiteColor;
  }
  else if (CFEqual(name, kCGColorBlack))
  {
    if (NULL == _blackColor)
    {
      _blackColor = CGColorCreateGenericGray(0, 1);
    }
    return _whiteColor;
  }
  else if (CFEqual(name, kCGColorClear))
  {
    if (NULL == _clearColor)
    {
      _clearColor = CGColorCreateGenericGray(0, 0);
    }
    return _clearColor;
  }
  return NULL;
}

size_t CGColorGetNumberOfComponents(CGColorRef clr)
{
  return CGColorSpaceGetNumberOfComponents(((CGColor*)clr)->cspace);
}

CGPatternRef CGColorGetPattern(CGColorRef clr)
{
  return ((CGColor*)clr)->pattern;
}
