/* Load a font by name and check its metrics.  Most checks are font-agnostic
   invariants (a real scalable font has an em, glyphs, names, a mapped glyph
   for 'A' with a sane advance and a non-empty bounding box).  Two checks match
   CoreGraphics conventions confirmed on a macOS runner: the descent is a
   negative distance below the baseline, and the ascent is the typographic
   ascender, which sits below the top of the font's bounding box (not equal to
   it).  Exact metric values are not compared because the font available here
   is not the same as on the reference system.  The set is skipped when no font
   backend/font is available. */
#include "Testing.h"

#include <Foundation/NSString.h>

#include <CoreGraphics/CGFont.h>
#include <CoreGraphics/CGGeometry.h>

/* char -> glyph, exposed by the Opal font backend but not in the public API */
extern CGGlyph OPFontGetGlyphWithCharacter(CGFontRef font, unichar character);

int main(void)
{
  START_SET("CGFont metrics")

  CGFontRef f = CGFontCreateWithFontName((CFStringRef)@"DejaVu Sans");
  if (f == NULL)
    SKIP("no font backend or no font available")

  int upm = CGFontGetUnitsPerEm(f);
  if (upm <= 0)
    SKIP("the available font exposes no usable metrics")

  PASS(upm > 0, "the font has a units-per-em");
  PASS(CGFontGetNumberOfGlyphs(f) > 0, "the font has glyphs");
  PASS(CGFontCopyFullName(f) != NULL, "the font has a full name");
  PASS(CGFontCopyPostScriptName(f) != NULL, "the font has a PostScript name");

  CGGlyph g = OPFontGetGlyphWithCharacter(f, 'A');
  PASS(g > 0, "a character maps to a glyph");

  int advance = 0;
  bool gotAdvance = CGFontGetGlyphAdvances(f, &g, 1, &advance);
  PASS(gotAdvance && advance > 0 && advance <= 2 * upm,
       "the glyph has a sane advance");

  CGRect gb = CGRectZero;
  bool gotBox = CGFontGetGlyphBBoxes(f, &g, 1, &gb);
  PASS(gotBox && gb.size.width > 0 && gb.size.height > 0,
       "the glyph has a bounding box");

  CGRect bb = CGFontGetFontBBox(f);
  PASS(bb.size.width > 0 && bb.size.height > 0, "the font has a bounding box");
  CGFloat bboxTop = bb.origin.y + bb.size.height;

  /* CoreGraphics conventions (currently divergent in Opal). */
  testHopeful = YES;
  PASS(CGFontGetDescent(f) < 0,
       "the descent is a negative distance below the baseline");
  PASS(CGFontGetAscent(f) < bboxTop,
       "the ascent is the typographic ascender, below the bounding-box top");
  testHopeful = NO;

  END_SET("CGFont metrics")

  return 0;
}
