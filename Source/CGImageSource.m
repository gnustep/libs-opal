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

#import <Foundation/NSArray.h>
#import <Foundation/NSSet.h>

/* Constants */

const CFStringRef kCGImageSourceTypeIdentifierHint = @"kCGImageSourceTypeIdentifierHint";
const CFStringRef kCGImageSourceShouldAllowFloat = @"kCGImageSourceShouldAllowFloat";
const CFStringRef kCGImageSourceShouldCache = @"kCGImageSourceShouldCache";
const CFStringRef kCGImageSourceCreateThumbnailFromImageIfAbsent = @"kCGImageSourceCreateThumbnailFromImageIfAbsent";
const CFStringRef kCGImageSourceCreateThumbnailFromImageAlways = @"kCGImageSourceCreateThumbnailFromImageAlways";
const CFStringRef kCGImageSourceThumbnailMaxPixelSize = @"kCGImageSourceThumbnailMaxPixelSize";
const CFStringRef kCGImageSourceCreateThumbnailWithTransform = @"kCGImageSourceCreateThumbnailWithTransform";


static NSMutableArray *sourceClasses = nil;

@interface CGImageSource : NSObject
{
}

+ (void) registerSourceClass: (Class)cls;
+ (NSArray*) sourceClasses;
+ (Class) sourceClassForType: (NSString*)type;

+ (NSArray *)typeIdentifiers;
+ (BOOL)canDecodeData: (CGDataProviderRef)provider;
- (id)initWitProvider: (CGDataProviderRef)provider;
- (NSDictionary*)propertiesWithOptions: (NSDictionary*)opts;
- (NSDictionary*)propertiesWithOptions: (NSDictionary*)opts atIndex: (size_t)index;
- (size_t)count;
- (CGImageRef)createImageAtIndex: (size_t)index options: (NSDictionary*)opts;
- (CGImageRef)createThumbnailAtIndex: (size_t)index options: (NSDictionary*)opts;
- (CGImageSourceStatus)status;
- (CGImageSourceStatus)statusAtIndex: (size_t)index;
- (NSString*)type;
- (void)updateData: (NSData*)data finalUpdate: (bool)finalUpdate;
- (void)updateDataProvider: (CGDataProviderRef)provider finalUpdate: (bool)finalUpdate;

@end

@implementation CGImageSource

+ (void) registerSourceClass: (Class)cls
{
  if (nil == sourceClasses)
  {
    sourceClasses = [[NSMutableArray alloc] init];
  }
  [sourceClasses addObject: cls];
}
+ (NSArray*) sourceClasses
{
  return sourceClasses;
}

+ (NSArray *)typeIdentifiers
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}
+ (BOOL)canDecodeData: (CGDataProviderRef)provider
{
  [self doesNotRecognizeSelector: _cmd];
  return NO;
}
- (id)initWitProvider: (CGDataProviderRef)provider
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}
- (NSDictionary*)propertiesWithOptions: (NSDictionary*)opts
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}
- (NSDictionary*)propertiesWithOptions: (NSDictionary*)opts atIndex: (size_t)index
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}
- (size_t)count
{
  [self doesNotRecognizeSelector: _cmd];
  return 0;
}
- (CGImageRef)createImageAtIndex: (size_t)index options: (NSDictionary*)opts
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}
- (CGImageRef)createThumbnailAtIndex: (size_t)index options: (NSDictionary*)opts
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}
- (CGImageSourceStatus)status
{
  [self doesNotRecognizeSelector: _cmd];
  return 0;
}
- (CGImageSourceStatus)statusAtIndex: (size_t)index
{
  [self doesNotRecognizeSelector: _cmd];
  return 0;
}
- (NSString*)type
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}
- (void)updateData: (NSData*)data finalUpdate: (bool)finalUpdate
{
  [self doesNotRecognizeSelector: _cmd];
}
- (void)updateDataProvider: (CGDataProviderRef)provider finalUpdate: (bool)finalUpdate
{
  [self doesNotRecognizeSelector: _cmd];
}

@end

/* Functions */

/* Creating */

CGImageSourceRef CGImageSourceCreateIncremental(CFDictionaryRef opts)
{
  return nil;//FIXME
}

CGImageSourceRef CGImageSourceCreateWithData(
  CFDataRef data,
  CFDictionaryRef opts)
{
  CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
  CGImageSourceRef source;
  source = CGImageSourceCreateWithDataProvider(provider, opts);
  CGDataProviderRelease(provider);
  return source;
}

CGImageSourceRef CGImageSourceCreateWithDataProvider(
  CGDataProviderRef provider,
  CFDictionaryRef opts)
{
  NSString *possibleType = [(NSDictionary*)opts valueForKey:
    (NSString*)kCGImageSourceTypeIdentifierHint];
  if (possibleType)
  {
    Class cls = [CGImageSource sourceClassForType: possibleType]; 
    if ([cls canDecodeData: provider])
    {
      return [[cls alloc] initWithProvider: provider];
    } 
  }
  
  NSUInteger cnt = [sourceClasses count];
  for (NSUInteger i=0; i<cnt; i++)
  {    
    Class cls = [sourceClasses objectAtIndex: i];
    if ([cls canDecodeData: provider])
    {
      return [[cls alloc] initWithProvider: provider];
    }
  }
  
  return nil;
}

CGImageSourceRef CGImageSourceCreateWithURL(
  CFURLRef url,
  CFDictionaryRef opts)
{
  CGDataProviderRef provider = CGDataProviderCreateWithURL(url);
  CGImageSourceRef source;
  source = CGImageSourceCreateWithDataProvider(provider, opts);
  CGDataProviderRelease(provider);
  return source;
}


/* Accessing Properties */

CFDictionaryRef CGImageSourceCopyProperties(
  CGImageSourceRef source,
  CFDictionaryRef opts)
{
  return (CFDictionaryRef)[source propertiesWithOptions: (NSDictionary*)opts];
}

CFDictionaryRef CGImageSourceCopyPropertiesAtIndex(
  CGImageSourceRef source,
  size_t index,
  CFDictionaryRef opts)
{
  return (CFDictionaryRef)[source propertiesWithOptions: (NSDictionary*)opts atIndex: index];
}

/* Getting Supported Image Types */

CFArrayRef CGImageSourceCopyTypeIdentifiers()
{
  NSMutableSet *set = [NSMutableSet set];
  NSArray *classes = [CGImageSource sourceClasses];
  NSUInteger cnt = [classes count];
  for (NSUInteger i=0; i<cnt; i++)
  {    
    [set addObjectsFromArray: [[classes objectAtIndex: i] typeIdentifiers]];
  }
  return (CFArrayRef)[[set allObjects] retain];
}

/* Accessing Images */

size_t CGImageSourceGetCount(CGImageSourceRef source)
{
  return [(CGImageSource*)source count];
}

CGImageRef CGImageSourceCreateImageAtIndex(
  CGImageSourceRef source,
  size_t index,
  CFDictionaryRef opts)
{
  return [(CGImageSource*)source createImageAtIndex: index options: (NSDictionary*)opts];
}

CGImageRef CGImageSourceCreateThumbnailAtIndex(
  CGImageSourceRef source,
  size_t index,
  CFDictionaryRef opts)
{
  return [(CGImageSource*)source createThumbnailAtIndex: index options: (NSDictionary*)opts];
}

CGImageSourceStatus CGImageSourceGetStatus(CGImageSourceRef source)
{
  return [(CGImageSource*)source status];  
}

CGImageSourceStatus CGImageSourceGetStatusAtIndex(
  CGImageSourceRef source,
  size_t index)
{
  return [(CGImageSource*)source statusAtIndex: index];
}

CFStringRef CGImageSourceGetType(CGImageSourceRef source)
{
  return [(CGImageSource*)source type];
}

void CGImageSourceUpdateData(
  CGImageSourceRef source,
  CFDataRef data,
  bool finalUpdate)
{
  [(CGImageSource*)source updateData: (NSData*)data finalUpdate: finalUpdate];
}

void CGImageSourceUpdateDataProvider(
  CGImageSourceRef source,
  CGDataProviderRef provider,
  bool finalUpdate)
{
  [(CGImageSource*)source updateDataProvider: provider finalUpdate: finalUpdate];
}

CFTypeID CGImageSourceGetTypeID()
{
  return (CFTypeID)[CGImageSource class];
}
