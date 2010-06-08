/** <title>CGFont</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

   Author: BALATON Zoltan <balaton@eik.bme.hu>
   Date: 2006
   Author: Eric Wasylishen <ewasylishen@gmail.com>
   Date: January, 2010

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

#ifdef __MINGW__

#import <Foundation/NSObject.h>
#include "CoreGraphics/CGBase.h"
#include "CoreGraphics/CGDataProvider.h"
#include "CoreGraphics/CGFont.h"
#include <CoreFoundation/CoreFoundation.h>
#include <stdlib.h>
#include <string.h>
#include <cairo-win32.h>
#include <windows.h>

#include "opal.h"

@interface CGFont : NSObject
{
@public
  cairo_font_face_t *cairo_face;
  cairo_scaled_font_t *metrics_face;
}
@end

@implementation CGFont

- (void) dealloc
{
  cairo_font_face_destroy(self->cairo_face);
  [super dealloc];
}

@end


cairo_font_face_t *opal_font_get_cairo_font(CGFontRef font)
{
  return ((CGFont *)font)->cairo_face;
}

bool CGFontCanCreatePostScriptSubset(
  CGFontRef font,
  CGFontPostScriptFormat format)
{
  return false;
}

CFStringRef CGFontCopyFullName(CGFontRef font)
{
  /*FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  CFStringRef result = NULL;
  
  if (ft_face) {
    const int FULL_NAME = 4;
    FT_SfntName nameStruct;
    if (0 == FT_Get_Sfnt_Name(ft_face, FULL_NAME, &nameStruct))
    {
      if (nameStruct.platform_id == TT_PLATFORM_APPLE_UNICODE)
      {
        result = CFStringCreateWithBytes(NULL, nameStruct.string, nameStruct.string_len, kCFStringEncodingUTF16BE, false);  
      }
      else if (nameStruct.platform_id == TT_PLATFORM_MACINTOSH &&
               nameStruct.encoding_id == TT_MAC_ID_ROMAN)
      {
        result = CFStringCreateWithBytes(NULL, nameStruct.string, nameStruct.string_len, kCFStringEncodingMacRoman, false);        
      }
      else if (nameStruct.platform_id == TT_PLATFORM_MICROSOFT &&
               nameStruct.encoding_id == TT_MS_ID_UNICODE_CS)
      {
        result = CFStringCreateWithBytes(NULL, nameStruct.string, nameStruct.string_len, kCFStringEncodingUTF16BE, false);        
      }
    }
    
    if (NULL != ft_face->family_name) {
      result = CFStringCreateWithCString(NULL, ft_face->family_name, kCFStringEncodingASCII);
    }
  }
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);*/
  return NULL;
}

CFStringRef CGFontCopyGlyphNameForGlyph(CGFontRef font, CGGlyph glyph)
{
  /*FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  CFStringRef result = NULL;
  
  if (ft_face) {
    char buffer[256];
    FT_Get_Glyph_Name(ft_face, glyph, buffer, 256);
    result = CFStringCreateWithCString(NULL, buffer, kCFStringEncodingASCII);
  }
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);*/
  return NULL;
}

CFStringRef CGFontCopyPostScriptName(CGFontRef font)
{
  /*FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  CFStringRef result = NULL;
  
  if (ft_face) {
    const char *psname = FT_Get_Postscript_Name(ft_face);
    if (NULL != psname) {
      result = CFStringCreateWithCString(NULL, psname, kCFStringEncodingASCII);
    } 
  }
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);  */
  return NULL;
}

CFDataRef CGFontCopyTableForTag(CGFontRef font, uint32_t tag)
{
  /*FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  CFDataRef result = NULL;
  
  if (ft_face) {
    FT_ULong length = 0;
    void *buffer;
    
    if (0 == FT_Load_Sfnt_Table(ft_face, tag, 0, NULL, &length)) {
      buffer = malloc(length);
      if (buffer) {
        if (0 == FT_Load_Sfnt_Table(ft_face, tag, 0, buffer, &length)) {
          result = CFDataCreate(NULL, buffer, length);
        }
        free(buffer);
      }
    }
  }
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);*/
  return NULL;
}

CFArrayRef CGFontCopyTableTags(CGFontRef font)
{
  /*FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  CFArrayRef result = CFArrayCreateMutable(NULL, 0, NULL);
  
  if (ft_face) {
    unsigned int i = 0;
    unsigned long tag, length;

    while (FT_Err_Table_Missing !=
           FT_Sfnt_Table_Info(ft_face, i, &tag, &length))
    {
      CFArrayAppendValue(result, (void *)tag);    
      i++;
    }
  }

  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);*/
  return NULL;
}

CFArrayRef CGFontCopyVariationAxes(CGFontRef font)
{
  return NULL;
}

CFDictionaryRef CGFontCopyVariations(CGFontRef font)
{
  return NULL;
}

CGFontRef CGFontCreateCopyWithVariations(
  CGFontRef font,
  CFDictionaryRef variations)
{
  return NULL;
}

CFDataRef CGFontCreatePostScriptEncoding(
  CGFontRef font,
  const CGGlyph encoding[256])
{
  return NULL;
}

CFDataRef CGFontCreatePostScriptSubset(
  CGFontRef font,
  CFStringRef name,
  CGFontPostScriptFormat format,
  const CGGlyph glyphs[],
  size_t count,
  const CGGlyph encoding[256])
{
  return NULL;
}

CGFontRef CGFontCreateWithDataProvider(CGDataProviderRef provider)
{
  //FIXME: implement
  return NULL;
}

CGFontRef CGFontCreateWithFontName(CFStringRef name)
{
  CGFontRef font = [[CGFont alloc] init];
  if (!font) return NULL;

  HFONT hfont = CreateFont(46, 28, 215, 0,
                           FW_NORMAL, FALSE, FALSE, FALSE,
                           ANSI_CHARSET, OUT_DEFAULT_PRECIS,
		         CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
		         DEFAULT_PITCH | FF_ROMAN,
			"Times New Roman");

  if (hfont) {
    ((CGFont *)font)->cairo_face = cairo_win32_font_face_create_for_hfont(hfont);
  } else {
    CGFontRelease(font);
    return NULL;
  }

  // Create a cairo_scaled_font which we just use to access the underlying
  // FT_Face

  cairo_matrix_t ident;
  cairo_matrix_init_identity(&ident);

  cairo_font_options_t *opts = cairo_font_options_create();
  cairo_font_options_set_hint_metrics(opts, CAIRO_HINT_METRICS_OFF);
  cairo_font_options_set_hint_style(opts, CAIRO_HINT_STYLE_NONE);
  
  ((CGFont *)font)->metrics_face = cairo_scaled_font_create(((CGFont *)font)->cairo_face,
    &ident, &ident, opts);
    
  cairo_font_options_destroy(opts);

  return font;
}

CGFontRef CGFontCreateWithPlatformFont(void *platformFontReference)
{
  // FIXME: implement
  return NULL;
}

int CGFontGetAscent(CGFontRef font)
{
  /*FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  int result = ft_face->bbox.yMax;
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);*/
  return 0;
}

int CGFontGetCapHeight(CGFontRef font)
{
  /*FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  int result = 0;
  
  TT_OS2 *os2table = (TT_OS2 *)FT_Get_Sfnt_Table(ft_face, ft_sfnt_os2);
  if (NULL != os2table) {
    result = os2table->sCapHeight;
  }
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);*/
  return 0;
}

int CGFontGetDescent(CGFontRef font)
{
  /*FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  int result = 0;
  
  result = ft_face->bbox.yMax;
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);*/
  return 0;
}

CGRect CGFontGetFontBBox(CGFontRef font)
{
  /*FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  FT_BBox bbox = ft_face->bbox;
  CGRect result = CGRectMake(
    bbox.xMin,
    bbox.yMin, 
    bbox.xMax - bbox.xMin,
    bbox.yMax - bbox.yMin);
    
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);
  return result;*/
  return CGRectMake(0,0,0,0);
}

/**
 * Returns the advances, in glpyh cooridinate space, of a series of glyphs.
 * No kerning is apllied, so the result of calling CGFontGetGlyphAdvances 
 * is the same whether it is called for each glyph or once for the array.
 * FIXME: double check that is correct
 */
bool CGFontGetGlyphAdvances(
  CGFontRef font,
  const CGGlyph glyphs[],
  size_t count,
  int advances[])
{
  for (int i=0; i<count; i++) {
    cairo_text_extents_t glyphExtents;
    
    cairo_glyph_t cairoGlyph;
    cairoGlyph.index = glyphs[i];
    cairoGlyph.x = 0;
    cairoGlyph.y = 0;
    
    cairo_scaled_font_glyph_extents(((CGFont *)font)->metrics_face, &cairoGlyph, 1, &glyphExtents);
    // FIXME: scale?
    advances[i] = (int)glyphExtents.x_advance;
  }
  return true;
}

bool CGFontGetGlyphBBoxes(
  CGFontRef font,
  const CGGlyph glyphs[],
  size_t count,
  CGRect bboxes[])
{
  for (int i=0; i<count; i++) {
    cairo_text_extents_t glyphExtents;
    
    cairo_glyph_t cairoGlyph;
    cairoGlyph.index = glyphs[i];
    cairoGlyph.x = 0;
    cairoGlyph.y = 0;
    
    cairo_scaled_font_glyph_extents(((CGFont *)font)->metrics_face, &cairoGlyph, 1, &glyphExtents);
    
    // FIXME: flip? scale?
    bboxes[i] = CGRectMake(glyphExtents.x_bearing, glyphExtents.y_bearing, 
      glyphExtents.width, glyphExtents.height);
  }
  return true;
}

CGGlyph CGFontGetGlyphWithGlyphName(CGFontRef font, CFStringRef glyphName)
{
  /*FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  CGGlyph result = 0;
  
  const char *name = CFStringGetCStringPtr(glyphName, kCFStringEncodingASCII);
  if (NULL != name) {
    result = (CGGlyph)FT_Get_Name_Index(ft_face, name);
  }
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);*/
  return 0;
}

CGFloat CGFontGetItalicAngle(CGFontRef font)
{
  /*FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  CGFloat result = 0;
  
  TT_Postscript *pstable = (TT_Postscript *)FT_Get_Sfnt_Table(ft_face, ft_sfnt_post);
  if (NULL != pstable) {
    result = pstable->italicAngle;
  }
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);*/
  return 0;
}

int CGFontGetLeading(CGFontRef font)
{
  /*FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  
  // see http://www.typophile.com/node/13081
  int result =  ft_face->height - ft_face->ascender + 
    ft_face->descender;
    
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);*/
  return 0;
}

size_t CGFontGetNumberOfGlyphs(CGFontRef font)
{
  /*FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);

  int result = ft_face->num_glyphs;
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);*/
  return 0;
}

CGFloat CGFontGetStemV(CGFontRef font)
{
  return 0;
}

CFTypeID CGFontGetTypeID()
{
  return 0;
}

int CGFontGetUnitsPerEm(CGFontRef font)
{
  /*FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  
  int result = ft_face->units_per_EM;
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);*/
  return 0;
}

int CGFontGetXHeight(CGFontRef font)
{
  /*FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  int result = 0;
  
  TT_OS2 *os2table = (TT_OS2 *)FT_Get_Sfnt_Table(ft_face, ft_sfnt_os2);
  if (NULL != os2table) {
    result = os2table->sxHeight;
  }
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);*/
  return 0;
}

CGFontRef CGFontRetain(CGFontRef font)
{
  return (CGFontRef)[(CGFont *)font retain];
}

void CGFontRelease(CGFontRef font)
{
  [(CGFont *)font release];
}

#endif
