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

#import "CTLine-private.h"
#import "CTRun-private.h"

/* Classes */

@implementation CTLine

- (id)initWithRuns: (NSArray*)runs
{
  if ((self = [super init]))
  {
    const NSUInteger count = [runs count];
    CGFloat x = 0;
    NSUInteger i;

    _runs = [runs retain];

    /* A run's positions are relative to the origin of the line holding it, so
       each run is laid out where the one before it ended. */
    for (i = 0; i < count; i++)
    {
      CTRun *run = [runs objectAtIndex: i];

      [run placeAtX: x];
      x += [run typographicBoundsForRange: CFRangeMake(0, 0)
                                   ascent: NULL
                                  descent: NULL
                                  leading: NULL];
    }
  }
  return self;
}

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
    CTRunDraw(run, ctx, CFRangeMake(0, 0));
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

/* The advance width of every glyph in the line, in order.  The caller frees
   the array. */
- (CGFloat *)glyphWidthsCount: (CFIndex *)countOut
{
  const NSUInteger runsCount = [_runs count];
  CFIndex total = [self glyphCount];
  CGFloat *widths;
  CFIndex at = 0;
  NSUInteger i;

  *countOut = total;
  if (total == 0)
  {
    return NULL;
  }

  widths = malloc(sizeof(CGFloat) * total);
  if (widths == NULL)
  {
    return NULL;
  }

  for (i = 0; i < runsCount; i++)
  {
    CTRun *run = [_runs objectAtIndex: i];
    const CGSize *advances = [run advances];
    CFIndex j, count = [run glyphCount];

    for (j = 0; j < count && at < total; j++)
    {
      widths[at++] = advances[j].width;
    }
  }
  return widths;
}

/* How many glyphs fit in room, counted from the start of the line or from its
   end.  A glyph fits when the glyphs up to and including it are no wider than
   room. */
static CFIndex
OPGlyphsFitting(const CGFloat *widths, CFIndex count, double room, BOOL fromEnd)
{
  double used = 0;
  CFIndex kept = 0, i;

  for (i = 0; i < count; i++)
  {
    CGFloat advance = widths[fromEnd ? count - 1 - i : i];

    if (used + advance > room)
    {
      break;
    }
    used += advance;
    kept++;
  }
  return kept;
}

/* The runs covering count glyphs of this line from index, trimming the runs
   at either end where the range falls inside one. */
- (NSArray *)runsForGlyphsFrom: (CFIndex)index count: (CFIndex)count
{
  NSMutableArray *kept = [NSMutableArray array];
  const NSUInteger runsCount = [_runs count];
  CFIndex at = 0;
  NSUInteger i;

  for (i = 0; i < runsCount && count > 0; i++)
  {
    CTRun *run = [_runs objectAtIndex: i];
    CFIndex glyphs = [run glyphCount];
    CFIndex first, take;

    if (at + glyphs <= index)
    {
      at += glyphs;
      continue;
    }

    first = (index > at) ? index - at : 0;
    take = glyphs - first;
    if (take > count)
    {
      take = count;
    }
    if (take > 0)
    {
      CTRun *piece = [run runWithGlyphsFrom: first count: take];

      if (piece != nil)
      {
        [kept addObject: piece];
      }
      count -= take;
    }
    at += glyphs;
  }
  return kept;
}

- (CTLine*) truncatedLineWithWidth: (double)width
                    truncationType: (CTLineTruncationType)truncationType
                   truncationToken:	(CTLineRef)truncationToken
{
  CFIndex total = 0;
  CGFloat *widths = [self glyphWidthsCount: &total];
  NSMutableArray *runs;
  double whole = 0, tokenWidth = 0, room;
  CFIndex head = 0, tail = 0, i;

  if (widths == NULL)
  {
    return self;
  }
  for (i = 0; i < total; i++)
  {
    whole += widths[i];
  }

  /* A line that already fits is answered as it stands, which is what Apple
     answers. */
  if (whole <= width)
  {
    free(widths);
    return self;
  }

  if (truncationToken != NULL)
  {
    tokenWidth = CTLineGetTypographicBounds(truncationToken, NULL, NULL, NULL);
  }

  /* Nothing can be drawn where even the token does not fit. */
  room = width - tokenWidth;
  if (room < 0)
  {
    free(widths);
    return nil;
  }

  switch (truncationType)
  {
    case kCTLineTruncationStart:
      tail = OPGlyphsFitting(widths, total, room, YES);
      break;

    case kCTLineTruncationMiddle:
      head = OPGlyphsFitting(widths, total, room / 2.0, NO);
      tail = OPGlyphsFitting(widths, total, room / 2.0, YES);
      if (head + tail > total)
      {
        tail = total - head;
      }
      break;

    case kCTLineTruncationEnd:
    default:
      head = OPGlyphsFitting(widths, total, room, NO);
      break;
  }
  free(widths);

  runs = [NSMutableArray array];
  if (head > 0)
  {
    [runs addObjectsFromArray: [self runsForGlyphsFrom: 0 count: head]];
  }
  if (truncationToken != NULL)
  {
    /* The token's own runs belong to the token's line, which keeps them, so
       the truncated line takes copies to lay out for itself. */
    NSArray *tokenRuns = [(CTLine *)truncationToken glyphRuns];
    NSUInteger j;

    for (j = 0; j < [tokenRuns count]; j++)
    {
      CTRun *run = [tokenRuns objectAtIndex: j];
      CTRun *copy = [run runWithGlyphsFrom: 0 count: [run glyphCount]];

      if (copy != nil)
      {
        [runs addObject: copy];
      }
    }
  }
  if (tail > 0)
  {
    [runs addObjectsFromArray: [self runsForGlyphsFrom: total - tail
                                                 count: tail]];
  }

  return [[[CTLine alloc] initWithRuns: runs] autorelease];
}

- (double)penOffset
{
  return 0;
}

- (CFRange)stringRange
{
  return CFRangeMake(0,0);
}
@end


/* Functions */

CTLineRef CTLineCreateWithAttributedString(CFAttributedStringRef string)
{
  CTTypesetterRef ts = CTTypesetterCreateWithAttributedString(string);
  CTLineRef line = CTTypesetterCreateLine(ts, CFRangeMake(0, 0));
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
  return nil;
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
  return CGRectMake(0,0,0,0);
}

double CTLineGetTypographicBounds(
	CTLineRef line,
	CGFloat* ascent,
	CGFloat* descent,
	CGFloat* leading)
{
  NSArray *runs = [line glyphRuns];
  NSUInteger i, count = [runs count];
  CGFloat maxAscent = 0, maxDescent = 0, maxLeading = 0;
  double width = 0;

  /* The line is as wide as its runs together, and as tall as the tallest of
     them. */
  for (i = 0; i < count; i++)
  {
    CTRunRef run = [runs objectAtIndex: i];
    CGFloat a = 0, d = 0, l = 0;

    width += CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &a, &d, &l);
    if (a > maxAscent) maxAscent = a;
    if (d > maxDescent) maxDescent = d;
    if (l > maxLeading) maxLeading = l;
  }

  if (ascent) *ascent = maxAscent;
  if (descent) *descent = maxDescent;
  if (leading) *leading = maxLeading;
  return width;
}

double CTLineGetTrailingWhitespaceWidth(CTLineRef line)
{
  return 0;
}

CFIndex CTLineGetStringIndexForPosition(
	CTLineRef line,
	CGPoint position)
{
  return 0;
}

CGFloat CTLineGetOffsetForStringIndex(
	CTLineRef line,
	CFIndex charIndex,
	CGFloat* secondaryOffset)
{
  return 0;
}

CFTypeID CTLineGetTypeID()
{
  return (CFTypeID)[CTLine class];
}

CGRect CTLineGetBoundsWithOptions(
  CTLineRef line,
  CTLineBoundsOptions options)
{
  return CGRectZero;
}
