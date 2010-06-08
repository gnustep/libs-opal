/** <title>CGDataProvider</title>

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

#ifndef OPAL_CGDataProvider_h
#define OPAL_CGDataProvider_h

/* Data Types */

typedef struct CGDataProvider *  CGDataProviderRef;

#include <CoreFoundation/CFURL.h>
#include <CoreFoundation/CFData.h>
#include <CoreGraphics/CGBase.h>

/* Callbacks */

typedef void *(*CGDataProviderGetBytePointerCallback)(void *info);

typedef size_t (*CGDataProviderGetBytesAtOffsetCallback)(
  void *info,
  void *buffer,
  size_t offset,
  size_t count
);

typedef size_t (*CGDataProviderGetBytesCallback)(
  void *info,
  void *buffer,
  size_t count
);

typedef void (*CGDataProviderSkipBytesCallback)(void *info, size_t count);

typedef void (*CGDataProviderReleaseBytePointerCallback)(
  void *info,
  const void *pointer
);

typedef void (*CGDataProviderReleaseDataCallback)(
  void *info,
  const void *data,
  size_t size
);

typedef void (*CGDataProviderReleaseInfoCallback)(void *info);

typedef void (*CGDataProviderRewindCallback)(void *info);

typedef struct CGDataProviderCallbacks
{
  CGDataProviderGetBytesCallback getBytes;
  CGDataProviderSkipBytesCallback skipBytes;
  CGDataProviderRewindCallback rewind;
  CGDataProviderReleaseInfoCallback releaseProvider;
} CGDataProviderCallbacks;

typedef struct CGDataProviderDirectAccessCallbacks
{
  CGDataProviderGetBytePointerCallback getBytePointer;
  CGDataProviderReleaseBytePointerCallback releaseBytePointer;
  CGDataProviderGetBytesAtOffsetCallback getBytes;
  CGDataProviderReleaseInfoCallback releaseProvider;
} CGDataProviderDirectAccessCallbacks;

/* Functions */

CGDataProviderRef CGDataProviderCreate(
  void *info,
  const CGDataProviderCallbacks *callbacks
);

CGDataProviderRef CGDataProviderCreateDirectAccess(
  void *info,
  size_t size,
  const CGDataProviderDirectAccessCallbacks *callbacks
);

CGDataProviderRef CGDataProviderCreateWithData(
  void *info,
  const void *data,
  size_t size,
  void (*releaseData)(void *info, const void *data, size_t size)
);

CGDataProviderRef CGDataProviderCreateWithCFData(CFDataRef data);

CGDataProviderRef CGDataProviderCreateWithURL(CFURLRef url);

CGDataProviderRef CGDataProviderRetain(CGDataProviderRef provider);

void CGDataProviderRelease(CGDataProviderRef provider);

#endif /* OPAL_CGDataProvider_h */
