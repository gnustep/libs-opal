/** <title>CairoFontWin32</title>
 
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

// FIXME: hack, fix the build system
#ifdef __MINGW__

#import "CairoFontWin32.h"

@implementation CairoFontWin32

- (void) dealloc
{
  DeleteObject(hfont);
  [super dealloc];
}

- (CFStringRef) copyGlyphNameForGlyph: (CGGlyph)glyph
{

}

- (CFDataRef) copyTableForTag: (uint32_t)tag
{
  
}

- (CFArrayRef) copyTableTags
{
 
}

- (CFArrayRef) copyVariationAxes
{

}

- (CFDictionaryRef) copyVariations
{

}

- (CGFontRef) createCopyWithVariations: (CFDictionaryRef)variations
{

}

- (CFDataRef) createPostScriptEncoding: (const CGGlyph[])encoding
{

}

+ (CGFontRef) createWithFontName: (CFStringRef)name
{
  CairoFontWin32 *font = [[CairoFontWin32 alloc] init];
  cairo_font_face_t *unscaled;
  
  if (NULL == font) return nil;

  font->hfont = CreateFont(46, 28, 215, 0,
                           FW_NORMAL, FALSE, FALSE, FALSE,
                           ANSI_CHARSET, OUT_DEFAULT_PRECIS,
		         CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
		         DEFAULT_PITCH | FF_ROMAN,
			"Times New Roman");

  if (font->hfont) {
    unscaled = cairo_win32_font_face_create_for_hfont(font->hfont);
  } else {
    [font release];
    return nil;
  }

  // Create a cairo_scaled_font which we just use to access the underlying
  // FT_Face

  cairo_matrix_t ident;
  cairo_matrix_init_identity(&ident);

  cairo_font_options_t *opts = cairo_font_options_create();
  cairo_font_options_set_hint_metrics(opts, CAIRO_HINT_METRICS_OFF);
  cairo_font_options_set_hint_style(opts, CAIRO_HINT_STYLE_NONE);
  
  font->cairofont = cairo_scaled_font_create(unscaled, &ident, &ident, opts);
    
  cairo_font_options_destroy(opts);

  return (CGFontRef)font;
}

+ (CGFontRef) createWithPlatformFont: (void *)platformFontReference
{
  return nil;
}

- (CGGlyph) glyphWithGlyphName: (CFStringRef)glyphName
{

}

@end

#endif