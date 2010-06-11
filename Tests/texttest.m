#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#else
#include <CoreGraphics/CoreGraphics.h>
#endif
#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>

static const char *fontName = "Times-Roman";

static CGGlyph glyphs[100];
static int advances[100];
static CGSize sizeAdvances[100];
static int len;

/** This treats each character in str as a glyph name.
 * It then looks up these glyph names in the given font, and stores
 * the glyph numbers, their advances in glyph space units, 
 * and their CGSize advances in text space units.
 */
void getGlyphs(CGFontRef font, CGFloat size, CFStringRef str)
{
  len = CFStringGetLength(str);
  for (int i=0; i<len; i++)
  {
    CFStringRef chr = CFStringCreateWithSubstring(NULL, str, CFRangeMake(i, 1));
    glyphs[i] = CGFontGetGlyphWithGlyphName(font, chr);
    CFRelease(chr);
  }
  CGFontGetGlyphAdvances(font, glyphs, len, advances);
  
  CGFloat glpyhSpaceToTextSpaceFactor = 
    (1.0f / (CGFloat)CGFontGetUnitsPerEm(font)) * (size);
    
  for (int i=0; i<len; i++)
  {
    sizeAdvances[i] = CGSizeMake(advances[i] * glpyhSpaceToTextSpaceFactor, 0);
  }
}

static char string[256];
char *getString(CFStringRef s)
{
  CFStringGetCString(s, string, 256, kCFStringEncodingUTF8);
  return string;
}

void dumpGlpyhNames(CGFontRef f)
{
  int nglyphs = CGFontGetNumberOfGlyphs(f);
  printf("Dumping glpyhs for %p, %d glyphs:\n", f, nglyphs);
  for (int i=0; i<nglyphs; i++){
    CFStringRef str = CGFontCopyGlyphNameForGlyph(f, i);
    printf("Glyph %d = '%s'\n", i, getString(str));
    CFRelease(str);
  }
}

void dumpFontInfo(CGFontRef f)
{
  printf("Dumping font info for %p\n", f);
  printf("CGFontCopyFullName: %s\n", getString(CGFontCopyFullName(f)));
  printf("CGFontCopyPostScriptName: %s\n", getString(CGFontCopyPostScriptName(f)));
  printf("CGFontCanCreatePostScriptSubset type1: %d\n", (int)CGFontCanCreatePostScriptSubset(f, kCGFontPostScriptFormatType1));
  printf("CGFontCanCreatePostScriptSubset type3: %d\n", (int)CGFontCanCreatePostScriptSubset(f, kCGFontPostScriptFormatType3));
  printf("CGFontCanCreatePostScriptSubset type42: %d\n", (int)CGFontCanCreatePostScriptSubset(f, kCGFontPostScriptFormatType42));
  printf("CGFontGetAscent: %d\n", CGFontGetAscent(f));  
  printf("CGFontGetCapHeight: %d\n", CGFontGetCapHeight(f));  
  printf("CGFontGetDescent: %d\n", CGFontGetDescent(f));
  CGRect r = CGFontGetFontBBox(f);  
  printf("CGFontGetFontBBox: ((%f,%f),(%f,%f))\n", (float)r.origin.x, (float)r.origin.y, (float)r.size.width, (float)r.size.height);
    
  for (int i=0; i<CGFontGetNumberOfGlyphs(f); i++)
  {
    CFStringRef name = CGFontCopyGlyphNameForGlyph(f, i);
    if (i != CGFontGetGlyphWithGlyphName(f, name))
    {
      printf("!!! CGFontCopyGlyphNameForGlyph and CGFontGetGlyphWithGlyphName disagree on glyph %d\n", i);
    }
    CFRelease(name);
  }
  printf("CGFontGetItalicAngle: %f\n", (float)CGFontGetItalicAngle(f));  
  printf("CGFontGetLeading: %d\n", CGFontGetLeading(f));
  printf("CGFontGetNumberOfGlyphs: %d\n", (int)CGFontGetNumberOfGlyphs(f));
  printf("CGFontGetStemV: %f\n", (float)CGFontGetStemV(f));  
  printf("CGFontGetUnitsPerEm: %d\n", (int)CGFontGetUnitsPerEm(f));
  printf("CGFontGetXHeight: %d\n", (int)CGFontGetXHeight(f));

/* To test:
CFDataRef CGFontCopyTableForTag(CGFontRef font, uint32_t tag);

CFArrayRef CGFontCopyTableTags(CGFontRef font);

CFArrayRef CGFontCopyVariationAxes(CGFontRef font);

CFDictionaryRef CGFontCopyVariations(CGFontRef font);

CGFontRef CGFontCreateCopyWithVariations(
  CGFontRef font,
  CFDictionaryRef variations
);

CFDataRef CGFontCreatePostScriptEncoding(
  CGFontRef font,
  const CGGlyph encoding[256]
);

CFDataRef CGFontCreatePostScriptSubset(
  CGFontRef font,
  CFStringRef name,
  CGFontPostScriptFormat format,
  const CGGlyph glyphs[],
  size_t count,
  const CGGlyph encoding[256]
);*/
}


void draw(CGContextRef ctx, CGRect rect)
{
  // Test CGContextSelectFont and CGContextShowTextAtPoint

  CGContextSetGrayFillColor(ctx, 0, 1);

  CGContextSelectFont(ctx, fontName, 5, kCGEncodingMacRoman);
  CGContextShowTextAtPoint(ctx, 10, 20, "5 pt text", 9);
  CGContextSelectFont(ctx, fontName, 10, kCGEncodingMacRoman);
  CGContextShowTextAtPoint(ctx, 10, 40, "10 pt text", 10);
  CGContextSelectFont(ctx, fontName, 20, kCGEncodingMacRoman);
  CGContextShowTextAtPoint(ctx, 10, 60, "20 pt text", 10);

  // Test that the current position is being updated
  
  CGContextShowText(ctx, ", and some more", 15);


  // Test CGContextSetFont / SetFontSize / CGContextShowGlyphsWithAdvances
  
  CGFontRef f = CGFontCreateWithFontName(CFSTR("Helvetica"));
  dumpFontInfo(f);  
  CGContextSetFont(ctx, f);
  CGContextSetFontSize(ctx, 20);
  getGlyphs(f, 20, CFSTR("ShowGlpyhsWithAdvances"));
  CGContextShowGlyphsWithAdvances(ctx, glyphs, sizeAdvances, len);


  // Try some fancy glyphs
  CGFontRef f2 = CGFontCreateWithFontName(CFSTR("Times-Roman"));
  dumpFontInfo(f2);
  CGContextSetFont(ctx, f2);
  dumpGlpyhNames(f2);
  CGGlyph ligatures[2] = {CGFontGetGlyphWithGlyphName(f, CFSTR("fl")),
    CGFontGetGlyphWithGlyphName(f2, CFSTR("fi"))};
  CGContextShowGlyphsAtPoint(ctx, 10, 80, ligatures, 2);
  
  
  // Test out the text matrix.
  CGGlyph AEligatures[2] = {CGFontGetGlyphWithGlyphName(f, CFSTR("AE")),
    CGFontGetGlyphWithGlyphName(f2, CFSTR("ae"))};

  CGAffineTransform xform = CGAffineTransformIdentity;
  xform = CGAffineTransformTranslate(xform, 10, 100);
  CGContextSetTextMatrix(ctx, xform); // Shows that the text position is part of the text matrix
  CGContextShowGlyphs(ctx, AEligatures, 2);

  xform = CGAffineTransformIdentity;
  xform = CGAffineTransformScale(xform, 2, 2); // Font size is 20, scaling by 2, means 40 pt text
  xform = CGAffineTransformTranslate(xform, 5, 60);
  CGContextSetTextMatrix(ctx, xform);
  CGContextSetFontSize(ctx, 20); // This line should do nothing because the text matrix and font size are independent
  CGContextShowGlyphs(ctx, AEligatures, 2);
}
