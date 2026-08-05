/* CTRunDraw with a range draws that part of the run where those glyphs sit,
   not at the start of the run.

   Measured against Apple CoreText with Helvetica 24 and a run of four H at a
   text position of x 10: the whole run paints x 11..77, the last two glyphs
   paint x 46..77, and the last glyph alone paints x 63..77.  Rasterisers
   differ on the ink of a glyph, so what is asserted is that a trailing range
   starts further right than the whole run and ends where the whole run
   ends. */
#include "Testing.h"

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>

#include <CoreText/CoreText.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGContext.h>
#include <string.h>

#define W 220
#define H 60

static CGContextRef newContext(void)
{
  CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(NULL, W, H, 8, W * 4, space,
                                               kCGImageAlphaPremultipliedFirst);

  CGColorSpaceRelease(space);
  if (context)
    {
      memset(CGBitmapContextGetData(context), 0, W * H * 4);
    }
  return context;
}

/* The horizontal extent of everything painted.  Answers NO where nothing
   was. */
static BOOL paintedSpan(CGContextRef context, int *x0, int *x1, int *count)
{
  unsigned char *data = CGBitmapContextGetData(context);
  int x, y;

  *x0 = W; *x1 = -1; *count = 0;
  for (y = 0; y < H; y++)
    for (x = 0; x < W; x++)
      {
        unsigned char *p = data + (y * W + x) * 4;

        if (p[0] || p[1] || p[2] || p[3])
          {
            (*count)++;
            if (x < *x0) *x0 = x;
            if (x > *x1) *x1 = x;
          }
      }
  return *x1 >= 0;
}

static CTRunRef firstRunOf(NSString *text, CTLineRef *lineOut)
{
  CTFontRef font = CTFontCreateWithName((CFStringRef)@"Helvetica", 24, NULL);
  NSAttributedString *as;
  NSArray *runs;

  if (font == NULL)
    return NULL;

  as = [[[NSAttributedString alloc]
          initWithString: text
              attributes: [NSDictionary dictionaryWithObject: (id)font
                                        forKey: (id)kCTFontAttributeName]]
         autorelease];
  [(id)font release];

  *lineOut = CTLineCreateWithAttributedString((CFAttributedStringRef)as);
  if (*lineOut == NULL)
    return NULL;
  runs = (NSArray *)CTLineGetGlyphRuns(*lineOut);
  if ([runs count] == 0)
    return NULL;
  return (CTRunRef)[runs objectAtIndex: 0];
}

static void drawRange(CTRunRef run, CGContextRef context, CFRange range)
{
  CGContextSetTextPosition(context, 10, 20);
  CTRunDraw(run, context, range);
}

int main(void)
{
  START_SET("drawing part of a run")

  CTLineRef line = NULL;
  CTRunRef run = firstRunOf(@"HHHH", &line);
  CGContextRef whole = newContext();
  CGContextRef tail = newContext();
  CGContextRef last = newContext();
  int wx0, wx1, wn, tx0, tx1, tn, lx0, lx1, ln;

  if (run == NULL || CTRunGetGlyphCount(run) != 4)
    {
      SKIP("this build's CoreText typesets no runs")
    }

  drawRange(run, whole, CFRangeMake(0, 0));
  if (!paintedSpan(whole, &wx0, &wx1, &wn))
    {
      SKIP("this build draws no glyphs")
    }

  drawRange(run, tail, CFRangeMake(2, 2));
  PASS(paintedSpan(tail, &tx0, &tx1, &tn),
       "drawing part of a run paints something");
  PASS(tn < wn, "less of it than the whole run paints");
  PASS(tx0 > wx0, "starting further across than the whole run starts");
  PASS(tx1 == wx1, "and ending where the whole run ends");

  drawRange(run, last, CFRangeMake(3, 1));
  PASS(paintedSpan(last, &lx0, &lx1, &ln) && lx0 > tx0,
       "and the last glyph alone starts further across still");
  PASS(lx1 == wx1, "ending where the whole run ends as well");

  CGContextRelease(whole);
  CGContextRelease(tail);
  CGContextRelease(last);
  [(id)line release];

  END_SET("drawing part of a run")

  return 0;
}
