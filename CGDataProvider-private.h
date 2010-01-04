/** <title>CGDataProvider</title>

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

#include "CGDataProvider.h"
#include "opal.h"

typedef struct CGDataProvider
{
  struct objbase base;
  CGDataProviderCallbacks cb;
  void *info;
} CGDataProvider;

static inline size_t opal_DataProviderRead(CGDataProviderRef dp, void *buffer, size_t count)
{
  return dp->cb.getBytes(dp->info, buffer, count);
}

static inline void opal_DataProviderSkip(CGDataProviderRef dp, size_t count)
{
  return dp->cb.skipBytes(dp->info, count);
}

static inline void opal_DataProviderRewind(CGDataProviderRef dp)
{
  return dp->cb.rewind(dp->info);
}
