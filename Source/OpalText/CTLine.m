/** <title>CTLine</title>

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

#include <CoreText/CTLine.h>
#include <CoreText/CTTypesetter.h>

/* Classes */

/**
 * Container of CTRun objects (glyph runs)
 */
@interface CTLine : NSObject
{
  NSArray *_runs;
}

@end

@implementation CTLine

- (NSArray*)runs
{
  return _runs;
}

- (void)drawOnContext: (CGContextRef)ctx
{
  const NSUInteger runsCount = [_runs count];
  for (NSUInteger i=0; i<runsCount; i++)
  {
    CTRunRef run = [_runs objectAtIndex: i];
    CTRunDraw(run, ctx, NSMakeRange(0, 0));
  }
}

- (CFIndex)glyphCount
{
  CFIndex sum = 0;
  const NSUInteger runsCount = [_runs count];
  for (NSUInteger i=0; i<runsCount; i++)
  {
    CTRunRef run = [_runs objectAtIndex: i];
    sum += CTRunGetGlyphCount(run);
  }
  return sum;
}

- (NSArray*)glyphRuns
{
  return _runs;
}

- (CTLine*) truncatedLineWithWidth: (double)width
                    truncationType: (CTLineTruncationType)truncationType
                   truncationToken:	(CTLineRef)truncationToken
{

}

- (double)penOffset
{

}

- (CFRange)stringRange
{

}
@end


/* Functions */

CTLineRef CTLineCreateWithAttributedString(CFAttributedStringRef string)
{
  CTTypesetterRef ts = CTTypesetterCreateWithAttributedString(string);
  CTLineRef line = CTTypesetterCreateLine(ts, NSMakeRange(0, 0));
  [ts release];
  return line;
}

CTLineRef CTLineCreateTruncatedLine(
	CTLineRef line,
	double width,
	CTLineTruncationType truncationType,
	CTLineRef truncationToken)
{
  return [[line truncatedLineWithWidth: width
                        truncationType: truncationType
                       truncationToken: truncationToken] retain];
}

CTLineRef CTLineCreateJustifiedLine(
	CTLineRef line,
	CGFloat justificationFactor,
	double justificationWidth)
{

}

CFIndex CTLineGetGlyphCount(CTLineRef line)
{
  return [line glyphCount];
}

CFArrayRef CTLineGetGlyphRuns(CTLineRef line)
{
  return [line glyphRuns];
}

CFRange CTLineGetStringRange(CTLineRef line)
{
  return [line stringRange];
}

double CTLineGetPenOffsetForFlush(
	CTLineRef line,
	CGFloat flushFactor,
	double flushWidth)
{
  return [line penOffset];
}
void CTLineDraw(CTLineRef line, CGContextRef context)
{
  return [line drawOnContext: context];
}

CGRect CTLineGetImageBounds(
	CTLineRef line,
	CGContextRef context)
{

}

double CTLineGetTypographicBounds(
	CTLineRef line,
	CGFloat* ascent,
	CGFloat* descent,
	CGFloat* leading)
{

}

double CTLineGetTrailingWhitespaceWidth(CTLineRef line)
{

}

CFIndex CTLineGetStringIndexForPosition(
	CTLineRef line,
	CGPoint position)
{

}

CGFloat CTLineGetOffsetForStringIndex(
	CTLineRef line,
	CFIndex charIndex,
	CGFloat* secondaryOffset)
{

}

CFTypeID CTLineGetTypeID()
{
  return (CFTypeID)[CTLine class];
}

