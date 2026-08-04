/* CTLine typesetting: an attributed string becomes a line of glyph runs, one
   run for each stretch of the string with the same attributes, and the line
   reports the summed advance width with the font's ascent and descent.  The
   typesetter takes the attributed string as an NSAttributedString, which is
   what it asks for its attributes as, so the tests build one. */
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

int main(void)
{
  START_SET("a line of one run")

  NSAttributedString *as = styled(@"Hi", 24);
  CTLineRef line;
  NSArray *runs;
  CGFloat ascent = -1, descent = -1, leading = -1;
  double width;

  if (as == nil)
    SKIP("no usable font available to typeset with")

  line = CTLineCreateWithAttributedString((CFAttributedStringRef)as);
  PASS(line != NULL, "a line can be made from an attributed string");

  runs = (NSArray *)CTLineGetGlyphRuns(line);
  PASS(runs != nil && [runs count] == 1,
       "and it holds one run for one set of attributes");
  PASS(CTLineGetGlyphCount(line) == 2, "with a glyph for each character");

  width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
  PASS(width > 0, "the line has a width");
  PASS(ascent > 0 && descent >= 0, "and the font's ascent and descent");
  PASS(ascent < 24 * 2, "which are in points, not em units");

  [(id)line release];

  END_SET("a line of one run")

  START_SET("a line of two runs")

  NSAttributedString *small = styled(@"Hi", 12);
  NSAttributedString *big = styled(@"There", 24);
  NSMutableAttributedString *mixed;
  CTLineRef line;
  NSArray *runs;

  if (small == nil || big == nil)
    SKIP("no usable font available to typeset with")

  mixed = [[[NSMutableAttributedString alloc] init] autorelease];
  [mixed appendAttributedString: small];
  [mixed appendAttributedString: big];

  line = CTLineCreateWithAttributedString((CFAttributedStringRef)mixed);
  runs = (NSArray *)CTLineGetGlyphRuns(line);
  PASS(runs != nil && [runs count] == 2,
       "two sets of attributes make two runs");
  PASS(CTLineGetGlyphCount(line) == 7,
       "and the runs together hold every glyph of the string");

  [(id)line release];

  END_SET("a line of two runs")

  return 0;
}
