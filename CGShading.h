/** <title>CGShading</title>

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

#ifndef OPAL_CGShading_h
#define OPAL_CGShading_h

#include <CGFunction.h>

/* Data Types */

typedef struct CGShading * CGShadingRef;

/* Functions */

CGShadingRef CGShadingCreateAxial (
  CGColorSpaceRef colorspace,
  CGPoint start,
  CGPoint end,
  CGFunctionRef function,
  int extendStart,
  int extendEnd
);

CGShadingRef CGShadingCreateRadial(
  CGColorSpaceRef colorspace,
  CGPoint start,
  float startRadius,
  CGPoint end,
  float endRadius,
  CGFunctionRef function,
  int extendStart,
  int extendEnd
);

CGShadingRef CGShadingRetain(CGShadingRef shading);

void CGShadingRelease(CGShadingRef shading);

#endif /* OPAL_CGShading_h */
