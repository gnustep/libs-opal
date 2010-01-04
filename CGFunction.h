/** <title>CGFunction</title>

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

#ifndef OPAL_CGFunction_h
#define OPAL_CGFunction_h

/* Data Types */

typedef struct CGFunction *CGFunctionRef;

/* Callbacks */

typedef void (*CGFunctionEvaluateCallback)(
  void *info,
  const float *inData,
  float *outData
);

typedef void (*CGFunctionReleaseInfoCallback)(void *info);

typedef struct CGFunctionCallbacks {
  unsigned int version;
  CGFunctionEvaluateCallback evaluate;
  CGFunctionReleaseInfoCallback releaseInfo
} CGFunctionCallbacks;

/* Functions */

CGFunctionRef CGFunctionCreate(
  void *info,
  size_t domainDimension,
  const float *domain,
  size_t rangeDimension,
  const float *range,
  const CGFunctionCallbacks *callbacks
);

CGFunctionRef CGFunctionRetain(CGFunctionRef function);

void CGFunctionRelease(CGFunctionRef function);

#endif /* OPAL_CGFunction_h */
