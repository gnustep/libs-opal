/** <title>CGBase</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Jan 2010

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

#ifndef OPAL_CGBase_h
#define OPAL_CGBase_h

#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

// for off_t
#include <sys/types.h>

#import <CoreFoundation/CoreFoundation.h>

// Note: GNUstep Foundation defines CGFloat
#ifdef __OBJC__
#import <Foundation/Foundation.h>
#else

#ifndef CGFLOAT_DEFINED
#define CGFLOAT_DEFINED 1

#if INTPTR_MAX == INT64_MAX
#define CGFLOAT_TYPE double
#define CGFLOAT_IS_DOUBLE 1
#define CGFLOAT_MIN DBL_MIN
#define CGFLOAT_MAX DBL_MAX
#else
#define CGFLOAT_TYPE float
#define CGFLOAT_IS_DOUBLE 0
#define CGFLOAT_MIN FLT_MIN
#define CGFLOAT_MAX FLT_MAX
#endif
	
typedef CGFLOAT_TYPE CGFloat;
#endif // CGFLOAT_DEFINED

typedef uintptr_t NSUInteger;

typedef struct _NSRange NSRange;
struct _NSRange
{
  NSUInteger location;
  NSUInteger length;
};

typedef struct _NSPoint NSPoint;
struct _NSPoint
{
  CGFloat x;
  CGFloat y;
};

typedef struct _NSSize NSSize;
struct _NSSize
{
  CGFloat width;
  CGFloat height;
};

typedef struct _NSRect NSRect;
struct _NSRect
{
  NSPoint origin;
  NSSize size;
};

typedef uint16_t unichar;
typedef NSUInteger NSStringEncoding;

#endif // __OBJC__

#ifndef MAX
#define MAX(a,b) ((a)>(b)?(a):(b))
#endif

#ifndef MIN
#define MIN(a,b) ((a)<(b)?(a):(b))
#endif

#endif /* OPAL_CGBase_h */

