/* CTLineCreateTruncatedLine: a line too wide for the space it is given is cut
   down to fit, with a token standing in for what was dropped.

   The rules were measured against Apple CoreText with Helvetica 24, a line of
   16 H and an ellipsis token: a line that already fits comes back as it went
   in; the token is kept and glyphs are dropped until the rest fits; a width
   narrower than the token alone answers nothing; and the truncated line is no
   wider than the width asked for.  Glyph advances differ between rasterisers,
   so the counts here are relative to the line's own metrics. */
#include "Testing.h"

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>

#include <CoreText/CoreText.h>
#include <stdlib.h>

static NSAttributedString *styled(NSString *text, CGFloat size)
{
  CTFontRef font = CTFontCreateWithName((CFStringRef)@"Helvetica", size, NULL);
  NSAttributedString *as;

  if (font == NULL)
    return nil;

  as = [[[NSAttributedString alloc]
          initWithString: text
              attributes: [NSDictionary dictionaryWithObject: (id)font
                                        forKey: (id)kCTFontAttributeName]]
         autorelease];
  [(id)font release];
  return as;
}

static CTLineRef lineOf(NSString *text)
{
  NSAttributedString *as = styled(text, 24);

  if (as == nil)
    return NULL;
  return CTLineCreateWithAttributedString((CFAttributedStringRef)as);
}

int main(void)
{
  START_SET("truncating a line")

  CTLineRef full = lineOf(@"HHHHHHHHHHHHHHHH");
  CTLineRef token;
  double whole, tokenWidth;

  if (full == NULL || CTLineGetGlyphCount(full) == 0)
    SKIP("this build's CoreText typesets no runs")

  token = lineOf(@"...");
  whole = CTLineGetTypographicBounds(full, NULL, NULL, NULL);
  tokenWidth = CTLineGetTypographicBounds(token, NULL, NULL, NULL);
  PASS(whole > 0 && tokenWidth > 0, "the line and the token have a width");

  {
    CTLineRef fits = CTLineCreateTruncatedLine(full, whole + 50,
                                               kCTLineTruncationEnd, token);

    PASS(fits == full, "a line that already fits is answered as it stands");
    [(id)fits release];
  }

  {
    CTLineRef cut = CTLineCreateTruncatedLine(full, whole / 2,
                                              kCTLineTruncationEnd, token);

    PASS(cut != NULL, "a line too wide for the width is truncated");
    PASS(CTLineGetGlyphCount(cut) < CTLineGetGlyphCount(full),
         "with fewer glyphs than it had");
    PASS(CTLineGetTypographicBounds(cut, NULL, NULL, NULL) <= whole / 2,
         "and no wider than the width it was given");
    PASS([(NSArray *)CTLineGetGlyphRuns(cut) count] == 2,
         "in a run of what was kept and a run of the token");
    [(id)cut release];
  }

  {
    CTLineRef cut = CTLineCreateTruncatedLine(full, whole / 2,
                                              kCTLineTruncationEnd, NULL);

    PASS(cut != NULL && [(NSArray *)CTLineGetGlyphRuns(cut) count] == 1,
         "with no token there is nothing but what was kept");
    PASS(CTLineGetTypographicBounds(cut, NULL, NULL, NULL) <= whole / 2,
         "and it fits the width as well");
    [(id)cut release];
  }

  {
    CTLineRef start = CTLineCreateTruncatedLine(full, whole / 2,
                                                kCTLineTruncationStart, token);
    CTLineRef middle = CTLineCreateTruncatedLine(full, whole / 2,
                                                 kCTLineTruncationMiddle,
                                                 token);

    PASS(start != NULL && [(NSArray *)CTLineGetGlyphRuns(start) count] == 2,
         "truncating at the start puts the token before what was kept");
    PASS(middle != NULL && [(NSArray *)CTLineGetGlyphRuns(middle) count] == 3,
         "and in the middle it goes between the two ends that were kept");
    PASS(CTLineGetTypographicBounds(start, NULL, NULL, NULL) <= whole / 2
         && CTLineGetTypographicBounds(middle, NULL, NULL, NULL) <= whole / 2,
         "both fitting the width");
    [(id)start release];
    [(id)middle release];
  }

  {
    CTLineRef none = CTLineCreateTruncatedLine(full, tokenWidth / 2,
                                               kCTLineTruncationEnd, token);
    CTLineRef zero = CTLineCreateTruncatedLine(full, 0,
                                               kCTLineTruncationEnd, token);
    CTLineRef negative = CTLineCreateTruncatedLine(full, -10,
                                                   kCTLineTruncationEnd,
                                                   token);

    PASS(none == NULL, "a width narrower than the token answers nothing");
    PASS(zero == NULL, "and so does a width of nothing");
    PASS(negative == NULL, "and a width below nothing");
  }

  {
    /* Room for the token and not one glyph more. */
    CTLineRef only = CTLineCreateTruncatedLine(full, tokenWidth,
                                               kCTLineTruncationEnd, token);

    PASS(only != NULL && CTLineGetGlyphCount(only)
                           == CTLineGetGlyphCount(token),
         "a width holding the token alone answers the token alone");
    [(id)only release];
  }

  /* The runs of a line are laid out one after another, so a truncated line
     draws its token where the glyphs it kept end. */
  {
    CTLineRef cut = CTLineCreateTruncatedLine(full, whole / 2,
                                              kCTLineTruncationEnd, token);
    NSArray *runs = (NSArray *)CTLineGetGlyphRuns(cut);

    if ([runs count] < 2)
      {
        PASS(NO, "a truncated line holds the glyphs kept and the token");
      }
    else
      {
        CTRunRef kept = [runs objectAtIndex: 0];
        CTRunRef tokenRun = [runs objectAtIndex: 1];
        CGPoint keptStart = CTRunGetPositionsPtr(kept)[0];
        CGPoint tokenStart = CTRunGetPositionsPtr(tokenRun)[0];
        double keptWidth = CTRunGetTypographicBounds(kept, CFRangeMake(0, 0),
                                                     NULL, NULL, NULL);

        PASS(keptStart.x == 0, "the first run of a line starts at its origin");
        PASS(tokenStart.x == keptWidth,
             "and the token starts where that run ended");
      }
    [(id)cut release];
  }

  [(id)token release];
  [(id)full release];

  END_SET("truncating a line")

  return 0;
}
