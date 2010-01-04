/** <title>CGColorSpace</title>

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

/* FIXME: Color Management is not implemented yet. Consequently, color spaces
 * are usually ignored and assumed to be deviceRGB. With most current equipment
 * supporting the sRGB color space, this may be OK in most cases, though.
 */

#include "CGColorSpace.h"
#include "opal.h"

typedef struct CGColorSpace
{
  struct objbase base;
  int numcomps;
  void (*todevice)(double *dest, const float comps[]);
} CGColorSpace;

static void opal_todev_rgb(double *dest, const float comps[]);
static void opal_todev_gray(double *dest, const float comps[]);

/* Return these for everything now */
static CGColorSpace deviceRGB =
{
  {"CGColorSpace", NULL, -1},
  3,
  opal_todev_rgb
};

static CGColorSpace deviceGray =
{
  {"CGColorSpace", NULL, -1},
  1,
  opal_todev_gray
};

CGColorSpaceRef CGColorSpaceCreateDeviceRGB(void)
{
  return &deviceRGB;
}

CGColorSpaceRef CGColorSpaceCreateDeviceGray(void)
{
  return &deviceGray;
}

CGColorSpaceRef CGColorSpaceCreateWithName(opal_GenericColorSpaceNames name)
{
  switch (name) {
    case kCGColorSpaceGenericGray:
      return CGColorSpaceCreateDeviceGray();
    case kCGColorSpaceGenericRGB:
      return CGColorSpaceCreateDeviceRGB();
    case kCGColorSpaceGenericCMYK:
    default:
      errlog("%s:%d: Unknown colorspace name\n", __FILE__, __LINE__);
      return NULL;
  }
}

CGColorSpaceRef CGColorSpaceRetain(CGColorSpaceRef cs)
{
  /* NOP */
  return cs;
}

void CGColorSpaceRelease(CGColorSpaceRef cs)
{
  /* NOP */
}

size_t CGColorSpaceGetNumberOfComponents(CGColorSpaceRef cs)
{
  return cs->numcomps;
}

static void opal_todev_rgb(double *dest, const float comps[])
{
  dest[0] = comps[0];
  dest[1] = comps[1];
  dest[2] = comps[2];
  dest[3] = comps[3];
}

static void opal_todev_gray(double *dest, const float comps[])
{
  dest[0] = comps[0];
  dest[1] = comps[0];
  dest[2] = comps[0];
  dest[3] = comps[1];
}

/* FIXME: This sould really convert to the color space of the device,
 * but Cairo only knows about RGBA, so we convert to that */
void opal_cspace_todev(CGColorSpaceRef cs, double *dest, const float comps[])
{
  cs->todevice(dest, comps);
}
