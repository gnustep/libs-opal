/** <title>ImageIOBase</title>

   Copyright (C) 2017 Free Software Foundation, Inc.
   Author: Daniel Ferreira <dtf@stanford.edu>
    
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

#ifndef OPAL_ImageIOBase_h
#define OPAL_ImageIOBase_h

#include <CoreFoundation/CoreFoundation.h>

#define IMAGEIO_AVAILABLE_STARTING(_mac,_iphone)
#define IMAGEIO_AVAILABLE_BUT_DEPRECATED(_mac,_macDep,_iphone,_iphoneDep)

#ifndef IMAGEIO_EXTERN
#if defined(__MINGW32__)

#ifdef __cplusplus
#define IMAGEIO_EXTERN extern "C" __declspec(dllexport)
#else
#define IMAGEIO_EXTERN extern __declspec(dllexport)
#endif

#else

#if defined(__cplusplus)
#define IMAGEIO_EXTERN extern "C"
#else
#define IMAGEIO_EXTERN extern
#endif

#endif
#endif

#if !defined(IMAGEIO_EXTERN_C_BEGIN)
#ifdef __cplusplus
#define IMAGEIO_EXTERN_C_BEGIN extern "C" {
#define IMAGEIO_EXTERN_C_END }
#else
#define IMAGEIO_EXTERN_C_BEGIN
#define IMAGEIO_EXTERN_C_END
#endif
#endif

#define IIO_HAS_IOSURFACE 0

#endif
