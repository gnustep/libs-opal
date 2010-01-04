/** <title>CGAffineTransform</title>

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

#define IN_CGAFFINETRANSFORM_C
#include "CGAffineTransform.h"
#undef IN_CGAFFINETRANSFORM_C
#include <math.h>
#include "opal.h"

const CGAffineTransform CGAffineTransformIdentity = {1,0,0,1,0,0};

CGAffineTransform CGAffineTransformMakeRotation(float angle)
{
  CGAffineTransform matrix;
  float cosa = cos(angle);
  float sina = sin(angle);

  matrix.a = matrix.d = cosa;
  matrix.b = sina;
  matrix.c = -sina;
  matrix.tx = matrix.ty = 0;

  return matrix;
}

CGAffineTransform CGAffineTransformInvert(CGAffineTransform t)
{
  CGAffineTransform inv;
  float det;

  det = t.a * t.d - t.b *t.c;
  if (det == 0) {
    errlog("%s:%d: Cannot invert matrix, determinant is 0\n",
           __FILE__, __LINE__);
    return t;
  }

  inv.a = t.d / det;
  inv.b = -t.b / det;
  inv.c = -t.c / det;
  inv.d = t.a / det;
  inv.tx = (t.c * t.ty - t.d * t.tx) / det;
  inv.ty = (t.b * t.tx - t.a * t.ty) / det;

  return inv;
}
