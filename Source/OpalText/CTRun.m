/** <title>CTRun</title>

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

#include <CoreText/CTRun.h>

/**
 * Container of adjacent glyphs with the same attributes which have been layed out
 */
@interface CTRun : NSObject
{
  size_t _count;
  CGGlyph *_glyphs; // pointer to C array of glphs
  CGSize *_advances;
  CGPoint *_positions;
  NSDictionary *_attributes;
}

- (void)drawRange: (CFRange)range onContext: (CGContextRef)ctx;

@end

@implementation CTRun

- (void)dealloc
{
  free(_glyphs);
  free(_advances);
  free(_positions);
  [_attributes release];
  [super dealloc];
}

- (void)drawRange: (CFRange)range onContext: (CGContextRef)ctx
{
  if (range.length == 0)
  {
    range.length = _count;
  }

  if (range.location > _count || (range.location + range.length) > _count)
  {
    NSLog(@"CTRunDraw range out of bounds"); 
    return;
  }

  CGContextShowGlyphsAtPositions(ctx, _glyphs + range.location, _positions, range.length);
}

@end

/* Functions */
 
CFIndex CTRunGetGlyphCount(CTRunRef run)
{
}

CFDictionaryRef CTRunGetAttributes(CTRunRef run)
{
}

CTRunStatus CTRunGetStatus(CTRunRef run)
{
}

const CGGlyph* CTRunGetGlyphsPtr(CTRunRef run)
{
}

void CTRunGetGlyphs(
	CTRunRef run,
	CFRange range,
	CGGlyph buffer[])
{
}

const CGPoint* CTRunGetPositionsPtr(CTRunRef run)
{
}

void CTRunGetPositions(
	CTRunRef run,
	CFRange range,
	CGPoint buffer[])
{
}

const CGSize* CTRunGetAdvancesPtr(CTRunRef run)
{
}

void CTRunGetAdvances(
	CTRunRef run,
	CFRange range,
	CGSize buffer[])
{
}

const CFIndex *CTRunGetStringIndicesPtr(CTRunRef run)
{
}

void CTRunGetStringIndices(
	CTRunRef run,
	CFRange range,
	CFIndex buffer[])
{
}

CFRange CTRunGetStringRange(CTRunRef run)
{
}

double CTRunGetTypographicBounds(
	CTRunRef run,
	CFRange range,
	CGFloat *ascent,
	CGFloat *descent,
	CGFloat *leading)
{
}

CGRect CTRunGetImageBounds(
	CTRunRef run,
	CGContextRef context,
	CFRange range)
{
}

CGAffineTransform CTRunGetTextMatrix(CTRunRef run)
{
}

void CTRunDraw(
	CTRunRef run,
	CGContextRef ctx,
	CFRange range)
{
  [run drawRange: range onContext: ctx];
}

CFTypeID CTRunGetTypeID()
{
  return (CFTypeID)[CTRun class];
}

