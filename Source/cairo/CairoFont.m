/** <title>CairoFont</title>
 
 <abstract>C Interface to graphics drawing library</abstract>
 
 Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

 Author: Eric Wasylishen
 Date: June 2010
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#import "CairoFont.h"


@implementation CairoFont

- (void) dealloc
{
  cairo_scaled_font_destroy(cairofont);
  [super dealloc];
}

- (bool) canCreatePostScriptSubset: (CGFontPostScriptFormat)format
{
  return false;
}

- (CFDataRef) createPostScriptSubset: (CFStringRef)name
                                    : (CGFontPostScriptFormat)format
                                    : (const CGGlyph[])glyphs
                                    : (size_t)count
                                    : (const CGGlyph[])encoding
{
  return NULL;
}

+ (CGFontRef) createWithDataProvider: (CGDataProviderRef)provider
{
  // FIXME: implement
}

/**
 * Returns the advances, in glpyh cooridinate space, of a series of glyphs.
 * No kerning is apllied, so the result of calling CGFontGetGlyphAdvances 
 * is the same whether it is called for each glyph or once for the array.
 * FIXME: double check that is correct
 */
- (bool) getGlyphAdvances: (const CGGlyph[])glyphs
                         : (size_t)count
                         : (int[]) advances
{
  for (int i=0; i<count; i++) {
    cairo_text_extents_t glyphExtents;
    
    cairo_glyph_t cairoGlyph;
    cairoGlyph.index = glyphs[i];
    cairoGlyph.x = 0;
    cairoGlyph.y = 0;
    
    cairo_scaled_font_glyph_extents(cairofont, &cairoGlyph, 1, &glyphExtents);
    // FIXME: scale?
    advances[i] = (int)glyphExtents.x_advance;
  }
  return true;
}

- (bool) getGlyphBBoxes: (const CGGlyph[])glyphs
                       : (size_t)count
                       : (CGRect[])bboxes
{
  for (int i=0; i<count; i++) {
    cairo_text_extents_t glyphExtents;
    
    cairo_glyph_t cairoGlyph;
    cairoGlyph.index = glyphs[i];
    cairoGlyph.x = 0;
    cairoGlyph.y = 0;
    
    cairo_scaled_font_glyph_extents(cairofont, &cairoGlyph, 1, &glyphExtents);
    
    // FIXME: flip? scale?
    bboxes[i] = CGRectMake(glyphExtents.x_bearing, glyphExtents.y_bearing, 
      glyphExtents.width, glyphExtents.height);
  }
  return true;   
}

@end
