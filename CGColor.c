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

#include <CGContext.h>
#include "opal.h"
#include "stdlib.h"

typedef struct CGColor
{
  struct objbase base;
  CGColorSpaceRef cspace;
  float *comps;
} CGColor;

CGColorRef CGColorCreate(CGColorSpaceRef colorspace, const float components[])
{
  CGColorRef clr;
  size_t nc, i;

  clr = opal_obj_alloc("CGColor", sizeof(CGColor));
  if (!clr) return NULL;

  nc = CGColorSpaceGetNumberOfComponents(colorspace);
  clr->comps = malloc((nc+1)*sizeof(float));
  if (!clr->comps) {
    errlog("%s:%d: malloc failed\n", __FILE__, __LINE__);
    free(clr);
    return NULL;
  }
  clr->cspace = colorspace;
  CGColorSpaceRetain(colorspace);
  for (i=0; i<=nc; i++)
    clr->comps[i] = components[i];

  return clr;
}

void opal_dealloc_CGColor(void *clr)
{
  CGColorRef c = clr;

  CGColorSpaceRelease(c->cspace);
  free(c->comps);
  free(c);
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

CGColorRef CGColorCreateCopyWithAlpha(CGColorRef clr, float alpha)
{
  CGColorRef newclr;

  newclr = CGColorCreate(clr->cspace, clr->comps);
  if (!newclr) return NULL;

  newclr->comps[CGColorSpaceGetNumberOfComponents(newclr->cspace)] = alpha;
  return newclr;
}

float CGColorGetAlpha(CGColorRef clr)
{
  return clr->comps[CGColorSpaceGetNumberOfComponents(clr->cspace)];
}

CGColorSpaceRef CGColorGetColorSpace(CGColorRef clr)
{
  return clr->cspace;
}

const float *CGColorGetComponents(CGColorRef clr)
{
  return clr->comps;
}

size_t CGColorGetNumberOfComponents(CGColorRef clr)
{
  return CGColorSpaceGetNumberOfComponents(clr->cspace);
}
