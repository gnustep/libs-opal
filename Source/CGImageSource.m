/** <title>CGImageSource</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright (C) 2010 Free Software Foundation, Inc.
   Author: Eric Wasylishen <ewasylishen@gmail.com>
    
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

#include "CoreGraphics/CGImageSource.h"

/* Constants */

const CFStringRef kCGImageSourceTypeIdentifierHint = @"kCGImageSourceTypeIdentifierHint";
const CFStringRef kCGImageSourceShouldAllowFloat = @"kCGImageSourceShouldAllowFloat";
const CFStringRef kCGImageSourceShouldCache = @"kCGImageSourceShouldCache";
const CFStringRef kCGImageSourceCreateThumbnailFromImageIfAbsent = @"kCGImageSourceCreateThumbnailFromImageIfAbsent";
const CFStringRef kCGImageSourceCreateThumbnailFromImageAlways = @"kCGImageSourceCreateThumbnailFromImageAlways";
const CFStringRef kCGImageSourceThumbnailMaxPixelSize = @"kCGImageSourceThumbnailMaxPixelSize";
const CFStringRef kCGImageSourceCreateThumbnailWithTransform = @"kCGImageSourceCreateThumbnailWithTransform";


@interface CGImageSource : NSObject


@end

@implementation CGImageSource

- (id) copyWithZone: (NSZone*)zone
{
}

- (void) dealloc
{
  [super dealloc];
}

@end


/* Functions */

/* Creating */

CGImageSourceRef CGImageSourceCreateIncremental(CFDictionaryRef opts)
{
  
}

CGImageSourceRef CGImageSourceCreateWithData(
  CFDataRef data,
  CFDictionaryRef opts)
{
  
}

CGImageSourceRef CGImageSourceCreateWithDataProvider(
  CGDataProviderRef provider,
  CFDictionaryRef opts)
{
  
}

CGImageSourceRef CGImageSourceCreateWithURL(
  CFURLRef url,
  CFDictionaryRef opts)
{
  
}

/* Accessing Properties */

CFDictionaryRef CGImageSourceCopyProperties(
  CGImageSourceRef source,
  CFDictionaryRef opts)
{
  
}

CFDictionaryRef CGImageSourceCopyPropertiesAtIndex(
  CGImageSourceRef source,
  size_t index,
  CFDictionaryRef opts)
{
  
}

/* Getting Supported Image Types */

CFArrayRef CGImageSourceCopyTypeIdentifiers()
{
  
}

/* Accessing Images */

size_t CGImageSourceGetCount(CGImageSourceRef source)
{
  
}

CGImageRef CGImageSourceCreateImageAtIndex(
  CGImageSourceRef source,
  size_t index,
  CFDictionaryRef opts)
{
  
}

CGImageRef CGImageSourceCreateThumbnailAtIndex(
  CGImageSourceRef source,
  size_t index,
  CFDictionaryRef opts)
{
  
}

CGImageSourceStatus CGImageSourceGetStatus(CGImageSourceRef source)
{
  
}

CGImageSourceStatus CGImageSourceGetStatusAtIndex(
  CGImageSourceRef source,
  size_t index)
{
  
}

CFStringRef CGImageSourceGetType(CGImageSourceRef source)
{
  
}

void CGImageSourceUpdateData(
  CGImageSourceRef source,
  CFDataRef data,
  bool finalUpdate)
{
  
}

void CGImageSourceUpdateDataProvider(
  CGImageSourceRef source,
  CGDataProviderRef provider,
  bool finalUpdate)
{
  
}

CFTypeID CGImageSourceGetTypeID()
{
  return (CFTypeID)[CGImageSource class];
}
