#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#else
#include <CoreGraphics/CoreGraphics.h>
#endif
#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>

static const char *fontName = "Times-Roman";

void draw(CGContextRef currentContext, CGRect rect)
{
    // Test CGContextSelectFont and CGContextShowTextAtPoint

    CGContextSetGrayFillColor(currentContext, 0, 1);

    CGContextSelectFont(currentContext, fontName, 1, kCGEncodingMacRoman);
    CGContextShowTextAtPoint(currentContext, 40, 200, "1: M x", 6);

    CGContextSelectFont(currentContext, fontName, 2, kCGEncodingMacRoman);
    CGContextShowTextAtPoint(currentContext, 40, 150, "2: M x", 6);

    CGContextSelectFont(currentContext, fontName, 3, kCGEncodingMacRoman);
    CGContextShowTextAtPoint(currentContext, 40, 100, "3: M x", 6);

    CGContextSelectFont(currentContext, fontName, 4, kCGEncodingMacRoman);
    CGContextShowTextAtPoint(currentContext, 40, 50, "4: M x", 6);

    // Test CGContextShowText
    
    CGContextSelectFont(currentContext, fontName, 1, kCGEncodingMacRoman);
    CGContextShowTextAtPoint(currentContext, 40, 250, "This-", 5);    
    CGContextShowText(currentContext, "and-that", 8);
  

    CGFontRef font = CGFontCreateWithFontName(@"Times-Roman");
    int i;
    for ( i=0; i<CGFontGetNumberOfGlyphs(font); i++){
      printf("%d", i);
      NSLog(@"%@", CGFontCopyGlyphNameForGlyph(font, i));
    }

    CGContextSetFont(currentContext, font);
    CGContextSetFontSize(currentContext, 4);

    CGGlyph glyphs[2] = {36, 57};
    CGContextShowGlyphs(currentContext, glyphs, 2);
}
