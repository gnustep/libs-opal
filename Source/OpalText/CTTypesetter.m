/** <title>CTTypesetter</title>

   <abstract>C Interface to text layout library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Aug 2010

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#include <CoreText/CTTypesetter.h>

/* Constants */

const CFStringRef kCTTypesetterOptionDisableBidiProcessing = @"kCTTypesetterOptionDisableBidiProcessing";
const CFStringRef kCTTypesetterOptionForcedEmbeddingLevel = @"kCTTypesetterOptionForcedEmbeddingLevel";

/* Classes */

/**
 * Typesetter
 */
@interface CTTypesetter : NSObject
{
}

- (id)initWithAttributedString: (NSAttributedString*)string
                       options: (NSDictionary*)options;

- (CTLineRef)createLineWithRange: (CFRange)range;
- (CFIndex)suggestClusterBreakAtIndex: (CFIndex)start
                                width: (double)width;
- (CFIndex)suggestLineBreakAtIndex: (CFIndex)start
                             width: (double)width;

@end

@implementation CTTypesetter

- (id)initWithAttributedString: (NSAttributedString*)string
                       options: (NSDictionary*)options
{
  return nil;
}

- (CTLineRef)createLineWithRange: (CFRange)range
{
  return nil;
}
- (CFIndex)suggestClusterBreakAtIndex: (CFIndex)start
                                width: (double)width
{
  return 0;
}
- (CFIndex)suggestLineBreakAtIndex: (CFIndex)start
                             width: (double)width
{
  return 0;
}

@end

/* Functions */

CTTypesetterRef CTTypesetterCreateWithAttributedString(CFAttributedStringRef string)
{
  return [[CTTypesetter alloc] initWithAttributedString: string
                                                options: nil];
}

CTTypesetterRef CTTypesetterCreateWithAttributedStringAndOptions(
	CFAttributedStringRef string,
	CFDictionaryRef opts)
{
  return [[CTTypesetter alloc] initWithAttributedString: string
                                                options: opts];
}

CTLineRef CTTypesetterCreateLine(CTTypesetterRef ts, CFRange range)
{
  return [ts createLineWithRange: range];
}

CFIndex CTTypesetterSuggestClusterBreak(
	CTTypesetterRef ts,
	CFIndex start,
	double width)
{
  return [ts suggestClusterBreakAtIndex: start width: width];
}

CFIndex CTTypesetterSuggestLineBreak(
	CTTypesetterRef ts,
	CFIndex start,
	double width)
{
  return [ts suggestLineBreakAtIndex: start width: width];
}

CFTypeID CTTypesetterGetTypeID()
{
  return (CFTypeID)[CTTypesetter class];
}

