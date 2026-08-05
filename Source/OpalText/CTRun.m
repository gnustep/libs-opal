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

#import "CTRun-private.h"

#import <CoreText/CTFont.h>
#import <CoreText/CTStringAttributes.h>

/* Classes */

@implementation CTRun

- (id)initWithGlyphs: (const CGGlyph *)glyphs
            advances: (const CGSize *)advances
               count: (size_t)count
          attributes: (NSDictionary *)attributes
         stringRange: (CFRange)stringRange
{
  if ((self = [super init]))
  {
    CGFloat x = 0;
    size_t i;

    _count = count;
    _glyphs = malloc(sizeof(CGGlyph) * count);
    _advances = malloc(sizeof(CGSize) * count);
    _positions = malloc(sizeof(CGPoint) * count);
    if (_glyphs == NULL || _advances == NULL || _positions == NULL)
    {
      [self release];
      return nil;
    }
    memcpy(_glyphs, glyphs, sizeof(CGGlyph) * count);
    memcpy(_advances, advances, sizeof(CGSize) * count);

    /* Each glyph sits where the ones before it left off. */
    for (i = 0; i < count; i++)
    {
      _positions[i] = CGPointMake(x, 0);
      x += advances[i].width;
    }

    _attributes = [attributes retain];
    _stringRange = stringRange;
    _status = 0;
    _matrix = CGAffineTransformIdentity;
  }
  return self;
}

- (void)dealloc
{
  free(_glyphs);
  free(_advances);
  free(_positions);
  [_attributes release];
  [super dealloc];
}

- (CFIndex)glyphCount
{
  return _count;
}

- (NSDictionary*)attributes
{
  return _attributes;
}

- (CTRunStatus)status
{
  return _status;
}

- (const CGGlyph *)glyphs
{
  return _glyphs;
}
- (const CGPoint *)positions
{
  return _positions;
}
- (const CGSize *)advances
{
  return _advances;
}
- (const CFIndex *)stringIndices
{
  return _stringIndices;
}
- (CFRange)stringRange
{
  return _stringRange;
}
- (double)typographicBoundsForRange: (CFRange)range
			     ascent: (CGFloat*)ascent
			    descent: (CGFloat*)descent
			    leading: (CGFloat*)leading
{
  CTFontRef font = [_attributes objectForKey: (id)kCTFontAttributeName];
  double width = 0;
  size_t first, limit, i;

  first = range.location;
  limit = (range.length == 0) ? _count : range.location + range.length;
  if (limit > _count)
  {
    limit = _count;
  }
  for (i = first; i < limit; i++)
  {
    width += _advances[i].width;
  }

  if (ascent)
  {
    *ascent = font ? CTFontGetAscent(font) : 0;
  }
  if (descent)
  {
    *descent = font ? CTFontGetDescent(font) : 0;
  }
  if (leading)
  {
    *leading = font ? CTFontGetLeading(font) : 0;
  }
  return width;
}
- (CGRect)imageBoundsForRange: (CFRange)range
		  withContext: (CGContextRef)context
{
  return CGRectMake(0,0,0,0);
}

- (CGAffineTransform)matrix
{
  return _matrix;
}

- (void)placeAtX: (CGFloat)x
{
  size_t i;

  for (i = 0; i < _count; i++)
  {
    _positions[i] = CGPointMake(x, 0);
    x += _advances[i].width;
  }
}

- (CTRun *)runWithGlyphsFrom: (CFIndex)index count: (CFIndex)count
{
  if (index < 0 || count < 0 || (size_t)(index + count) > _count)
  {
    return nil;
  }

  return [[[CTRun alloc] initWithGlyphs: _glyphs + index
                               advances: _advances + index
                                  count: count
                             attributes: _attributes
                            stringRange:
                              CFRangeMake(_stringRange.location + index,
                                          count)] autorelease];
}

- (void)drawRange: (CFRange)range onContext: (CGContextRef)ctx
{
  CTFontRef font = [_attributes objectForKey: (id)kCTFontAttributeName];

  if (range.length == 0)
  {
    range.length = _count;
  }

  if (range.location > _count || (range.location + range.length) > _count)
  {
    NSLog(@"CTRunDraw range out of bounds");
    return;
  }

  /* The run carries the font it was laid out with, so the caller does not
     have to select one on the context first.  Nothing is drawn while the
     context's font size is zero, so that is set either way. */
  if (font != NULL)
  {
    CGFontRef graphicsFont = CTFontCopyGraphicsFont(font, NULL);

    if (graphicsFont != NULL)
    {
      CGContextSetFont(ctx, graphicsFont);
      CGFontRelease(graphicsFont);
    }
    CGContextSetFontSize(ctx, CTFontGetSize(font));
  }

  CGContextShowGlyphsAtPositions(ctx, _glyphs + range.location, _positions, range.length);
}

@end


/* Functions */
 
CFIndex CTRunGetGlyphCount(CTRunRef run)
{
  return [run glyphCount];
}

CFDictionaryRef CTRunGetAttributes(CTRunRef run)
{
  return [run attributes];
}

CTRunStatus CTRunGetStatus(CTRunRef run)
{
  return [run status];
}

const CGGlyph* CTRunGetGlyphsPtr(CTRunRef run)
{
  return [run glyphs];
}

void CTRunGetGlyphs(
	CTRunRef run,
	CFRange range,
	CGGlyph buffer[])
{
  memcpy(buffer, [run glyphs] + range.location, sizeof(CGGlyph) * range.length);
}

const CGPoint* CTRunGetPositionsPtr(CTRunRef run)
{
  return [run positions];
}

void CTRunGetPositions(
	CTRunRef run,
	CFRange range,
	CGPoint buffer[])
{
  memcpy(buffer, [run positions] + range.location, sizeof(CGPoint) * range.length);
}

const CGSize* CTRunGetAdvancesPtr(CTRunRef run)
{
  return [run advances];
}

void CTRunGetAdvances(
	CTRunRef run,
	CFRange range,
	CGSize buffer[])
{
   memcpy(buffer, [run advances] + range.location, sizeof(CGSize) * range.length);
}

const CFIndex *CTRunGetStringIndicesPtr(CTRunRef run)
{
  return [run stringIndices];
}

void CTRunGetStringIndices(
	CTRunRef run,
	CFRange range,
	CFIndex buffer[])
{
  memcpy(buffer, [run stringIndices] + range.location, sizeof(CFIndex) * range.length);
}

CFRange CTRunGetStringRange(CTRunRef run)
{
  return [run stringRange];
}

double CTRunGetTypographicBounds(
	CTRunRef run,
	CFRange range,
	CGFloat *ascent,
	CGFloat *descent,
	CGFloat *leading)
{
  return [run typographicBoundsForRange: range
				 ascent: ascent
				descent: descent
				leading: leading];
}

CGRect CTRunGetImageBounds(
	CTRunRef run,
	CGContextRef context,
	CFRange range)
{
  return [run imageBoundsForRange: range
		      withContext: context];
}

CGAffineTransform CTRunGetTextMatrix(CTRunRef run)
{
  return [run matrix];
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

