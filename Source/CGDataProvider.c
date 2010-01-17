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

#include "CGDataProvider-private.h"
#include <stdlib.h>
#include <string.h>

typedef struct DirectInfo {
  size_t offset;
  CGDataProviderDirectAccessCallbacks cb;
  void *info;

  size_t size;
  const void *data;
  void (*releaseData)(void *info, const void *data, size_t size);
} DirectInfo; 

static size_t opal_DirectGetBytes(void *info, void *buffer, size_t count)
{
  DirectInfo *i = info;

  if (i->data) {
    if (i->offset + count > i->size) count = i->size - i->offset;
    if (count) memcpy(buffer, i->data + i->offset, count);
  } else {
    count = i->cb.getBytes(i->info, buffer, i->offset, count);
  }
  i->offset += count;
  return count;
}

static void opal_DirectSkipBytes(void *info, size_t count)
{
  ((DirectInfo *)info)->offset += count;
}  

static void opal_DirectRewind(void *info)
{
  ((DirectInfo *)info)->offset = 0;
}

static void opal_DirectReleaseInfo(void *info)
{
  DirectInfo *i = info;

  if (i->releaseData) i->releaseData(i->info, i->data, i->size);
  if (i->cb.releaseProvider) i->cb.releaseProvider(i->info);
  free(i);
}

static CGDataProviderCallbacks opal_DirectCallbacks = {
  opal_DirectGetBytes,
  opal_DirectSkipBytes,
  opal_DirectRewind,
  opal_DirectReleaseInfo
};

static void opal_DirectReleaseData(void *info, const void *data, size_t size)
{
  DirectInfo *i = info;

  if (i->cb.releaseBytePointer) i->cb.releaseBytePointer(i->info, i->data);
}

void opal_dealloc_CGDataProvider(void *d)
{
  CGDataProviderRef dp = d;

  if (dp->cb.releaseProvider) dp->cb.releaseProvider(dp->info);
  free(dp);
}

CGDataProviderRef CGDataProviderCreate(
  void *info, const CGDataProviderCallbacks *callbacks)
{
  CGDataProviderRef dp;

  if (!(callbacks && callbacks->getBytes &&
        callbacks->skipBytes && callbacks->rewind))
    return NULL;

  dp = opal_obj_alloc("CGDataProvider", sizeof(CGDataProvider));
  if (!dp) return NULL;

  dp->cb = *callbacks;
  dp->info = info;

  return dp;
}

static inline CGDataProviderRef opal_CreateDirectAccess(
 void *info, size_t size, const CGDataProviderDirectAccessCallbacks *callbacks)
{
  CGDataProviderRef dp;
  DirectInfo *i;

  i = calloc(1, sizeof(DirectInfo));
  if (!i) {
    errlog("%s:%d: calloc failed\n", __FILE__, __LINE__);
    return NULL;
  }

  dp = CGDataProviderCreate(i, &opal_DirectCallbacks);
  if (!dp) {
    free(i);
    return NULL;
  }

  if (callbacks) i->cb = *callbacks;
  i->info = info;
  i->size = size;
  if (i->cb.getBytePointer) {
    i->data = i->cb.getBytePointer(info);
    if (i->data) i->releaseData = opal_DirectReleaseData;
  }

  return dp;
}

CGDataProviderRef CGDataProviderCreateDirectAccess(
 void *info, size_t size, const CGDataProviderDirectAccessCallbacks *callbacks)
{
  if (!size) return NULL;
  if (!(callbacks && (callbacks->getBytes || callbacks->getBytePointer)))
    return NULL;

  return opal_CreateDirectAccess(info, size, callbacks);
}

CGDataProviderRef CGDataProviderCreateWithData(
  void *info,
  const void *data,
  size_t size,
  void (*releaseData)(void *info, const void *data, size_t size))
{
  CGDataProviderRef dp;
  DirectInfo *i;

  if (!size || !data) return NULL;

  dp = opal_CreateDirectAccess(info, size, NULL);
  if (!dp) return NULL;

  i = dp->info;
  i->data = data;
  i->releaseData = releaseData;

  return dp;
}

CGDataProviderRef CGDataProviderRetain(CGDataProviderRef provider)
{
  return (provider ? opal_obj_retain(provider) : NULL);
}

void CGDataProviderRelease(CGDataProviderRef provider)
{
  if(provider) opal_obj_release(provider);
}
