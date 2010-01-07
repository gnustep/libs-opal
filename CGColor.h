/** <title>CGColor</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright (C) 2006 BALATON Zoltan <balaton@eik.bme.hu>

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

#ifndef OPAL_CGColor_h
#define OPAL_CGColor_h

#include <CGColorSpace.h>
#include <CGPattern.h>

/* Data Types */

typedef struct CGColor * CGColorRef;

/* Functions */

CGColorRef CGColorCreate(CGColorSpaceRef colorspace, const CGFloat components[]);

CGColorRef CGColorCreateCopy(CGColorRef clr);

CGColorRef CGColorCreateCopyWithAlpha(CGColorRef clr, CGFloat alpha);

CGColorRef CGColorCreateWithPattern(
  CGColorSpaceRef colorspace,
  CGPatternRef pattern,
  const CGFloat components[]
);

CGFloat CGColorGetAlpha(CGColorRef clr);

CGColorSpaceRef CGColorGetColorSpace(CGColorRef clr);

const CGFloat *CGColorGetComponents(CGColorRef clr);

size_t CGColorGetNumberOfComponents(CGColorRef clr);

CGPatternRef CGColorGetPattern(CGColorRef clr);

void CGColorRelease(CGColorRef clr);

CGColorRef CGColorRetain(CGColorRef clr);

#endif /* OPAL_CGColor_h */
