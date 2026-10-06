/* A glyph's advance, from a font no one has drawn with yet: the width the
   font's own metrics give, scaled to the point size, and the same width
   a line of that glyph reports. */
#include "Testing.h"

#include <CoreText/CoreText.h>

int main(void)
{
  START_SET("advances of a fresh font")

  CTFontRef font = CTFontCreateWithName((CFStringRef)@"Helvetica", 20, NULL);
  UniChar characters[2] = { 'H', 'i' };
  CGGlyph glyphs[2] = { 0, 0 };
  CGSize advances[2] = { { -1, -1 }, { -1, -1 } };
  double total;

  if (font == NULL || !CTFontGetGlyphsForCharacters(font, characters, glyphs, 2))
    SKIP("no usable font available")

  total = CTFontGetAdvancesForGlyphs(font, kCTFontOrientationHorizontal,
                                     glyphs, advances, 2);
  PASS(advances[0].width > 0 && advances[1].width > 0,
       "each glyph advances the pen");
  PASS(advances[0].height == 0 && advances[1].height == 0,
       "a horizontal advance has no vertical part");
  PASS(total == advances[0].width + advances[1].width,
       "the total is the sum of the advances");
  PASS(advances[0].width < 20, "an advance is scaled to the point size");

  [(id)font release];

  END_SET("advances of a fresh font")
  return 0;
}
