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

#ifndef __MINGW__

#include "CoreGraphics/CGBase.h"
#include "CoreGraphics/CGDataProvider.h"
#include "CoreGraphics/CGFont.h"
#include <stdlib.h>
#include <string.h>
#include "cairo-ft.h"
#include FT_LIST_H
#include FT_SFNT_NAMES_H
#include FT_TRUETYPE_IDS_H
#include FT_TRUETYPE_TABLES_H
#include "opal.h"

/* We just return a (cairo_font_face_t *) as a (CGFontRef) */

static FcPattern *opal_FcPatternCreateFromName(const char *name);

/* We keep an LRU cache of patterns looked up by name to avoid calling
 * fontconfig too frequently (like when refreshing a window repeatedly) */
/* But we cache patterns and let cairo handle FT_Face objects because of
 * memory management problems (lack of reference counting on FT_Face) */
/* We can't use Freetype's Cache Manager to implement our cache because its API
 * seems to be in a flux (for other than Face, CMap, Image and SBit at least) */

/* Number of entries to keep in the cache */
#define CACHE_SIZE  10

static FT_ListRec pattern_cache;

typedef struct cache_entry {
  FT_ListNodeRec node;
  unsigned int hash;
  FcPattern *pat;
} cache_entry;

typedef struct iter_state {
  unsigned int hash;
  FcPattern *pat;
  int cnt;
} iter_state;

static FT_Error cache_iterator(FT_ListNode node, void *user)
{
  cache_entry *entry = (cache_entry *)node;
  iter_state *state = user;

  state->cnt++;
  if (!node) return 1;
  if (entry->hash == state->hash) {
    state->pat = entry->pat;
    FT_List_Up(&pattern_cache, node);
    return 2;
  }
  return 0;
}

static unsigned int hash_string(const char *str)
{
  unsigned int hash;

  for (hash = 0; *str != '\0'; str++)
    hash = 31 * hash + *str;

  return hash;
}

static FcPattern *opal_FcPatternCacheLookup(const char *name)
{
  iter_state state;

  state.cnt = 0;
  state.pat = NULL;
  state.hash = hash_string(name);
  FT_List_Iterate(&pattern_cache, cache_iterator, &state);

  if (state.pat)
    return state.pat;

  state.pat = opal_FcPatternCreateFromName(name);
  if (!state.pat) return NULL;

  if (state.cnt >= CACHE_SIZE) {  /* Remove last entry from the cache */
    FT_ListNode node;

    node = pattern_cache.tail;
    FT_List_Remove(&pattern_cache, node);
    FcPatternDestroy(((cache_entry *)node)->pat);
    free(node);
  }
  /* Add new entry to the cache */
  {
    cache_entry *entry;

    entry = calloc(1, sizeof(*entry));
    if (!entry) {
      errlog("%s:%d: calloc failed\n", __FILE__, __LINE__);
      return state.pat;
    }
    entry->hash = state.hash;
    entry->pat = state.pat;
    FT_List_Insert(&pattern_cache, (FT_ListNode)entry);
  }
  return state.pat;
}

/* End of cache related things */

//
// Note on CGFont: we really need  David Turner's cairo-ft rewrite,
// which is on the roadmap for cairo 1.12.
//
// The current cairo_ft_scaled_font_lock_face function is almost useless.
// With it, we can only (safely) look at immutable parts of the FT_Face.
//

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
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
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
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);
  return result;
}

CFStringRef CGFontCopyGlyphNameForGlyph(CGFontRef font, CGGlyph glyph)
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  CFStringRef result = NULL;
  
  if (ft_face) {
    char buffer[256];
    FT_Get_Glyph_Name(ft_face, glyph, buffer, 256);
    result = CFStringCreateWithCString(NULL, buffer, kCFStringEncodingASCII);
  }
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);
  return result;
}

CFStringRef CGFontCopyPostScriptName(CGFontRef font)
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  CFStringRef result = NULL;
  
  if (ft_face) {
    const char *psname = FT_Get_Postscript_Name(ft_face);
    if (NULL != psname) {
      result = CFStringCreateWithCString(NULL, psname, kCFStringEncodingASCII);
    } 
  }
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);  
  return result;
}

CFDataRef CGFontCopyTableForTag(CGFontRef font, uint32_t tag)
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
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
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);
  return result;
}

CFArrayRef CGFontCopyTableTags(CGFontRef font)
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
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

  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);
  return result;
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
  FcPattern *pat;
  CGFont *font = [[CGFont alloc] init];
  if (!font) return NULL;

  pat = opal_FcPatternCacheLookup(name);
  if(pat) {
    ((CGFont *)font)->cairo_face = cairo_ft_font_face_create_for_pattern(pat);
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

  return (CGFontRef)font;
}

CGFontRef CGFontCreateWithPlatformFont(void *platformFontReference)
{
  // FIXME: implement
  return NULL;
}

int CGFontGetAscent(CGFontRef font)
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  int result = ft_face->bbox.yMax;
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);
  return result;
}

int CGFontGetCapHeight(CGFontRef font)
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  int result = 0;
  
  TT_OS2 *os2table = (TT_OS2 *)FT_Get_Sfnt_Table(ft_face, ft_sfnt_os2);
  if (NULL != os2table) {
    result = os2table->sCapHeight;
  }
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);
  return result;
}

int CGFontGetDescent(CGFontRef font)
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  int result = 0;
  
  result = ft_face->bbox.yMax;
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);
  return result;
}

CGRect CGFontGetFontBBox(CGFontRef font)
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  FT_BBox bbox = ft_face->bbox;
  CGRect result = CGRectMake(
    bbox.xMin,
    bbox.yMin, 
    bbox.xMax - bbox.xMin,
    bbox.yMax - bbox.yMin);
    
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);
  return result;
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
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  CGGlyph result = 0;
  
  const char *name = CFStringGetCStringPtr(glyphName, kCFStringEncodingASCII);
  if (NULL != name) {
    result = (CGGlyph)FT_Get_Name_Index(ft_face, name);
  }
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);
  return result;
}

CGFloat CGFontGetItalicAngle(CGFontRef font)
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  CGFloat result = 0;
  
  TT_Postscript *pstable = (TT_Postscript *)FT_Get_Sfnt_Table(ft_face, ft_sfnt_post);
  if (NULL != pstable) {
    result = pstable->italicAngle;
  }
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);
  return result;
}

int CGFontGetLeading(CGFontRef font)
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  
  // see http://www.typophile.com/node/13081
  int result =  ft_face->height - ft_face->ascender + 
    ft_face->descender;
    
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);
  return result;
}

size_t CGFontGetNumberOfGlyphs(CGFontRef font)
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);

  int result = ft_face->num_glyphs;
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);
  return result;
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
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  
  int result = ft_face->units_per_EM;
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);
  return result;
}

int CGFontGetXHeight(CGFontRef font)
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(((CGFont *)font)->metrics_face);
  int result = 0;
  
  TT_OS2 *os2table = (TT_OS2 *)FT_Get_Sfnt_Table(ft_face, ft_sfnt_os2);
  if (NULL != os2table) {
    result = os2table->sxHeight;
  }
  
  cairo_ft_scaled_font_unlock_face(((CGFont *)font)->metrics_face);
  return result;
}

CGFontRef CGFontRetain(CGFontRef font)
{
  return (font ? opal_obj_retain(font) : NULL);
}

void CGFontRelease(CGFontRef font)
{
  if(font) opal_obj_release(font);
}

static FcPattern *opal_FcPatternCreateFromName(const char *name)
{
  char *family, *traits;
  FcPattern *pat;
  FcResult fcres;
  FcBool success;

  if (!name) return NULL;
  family = strdup(name);
  pat = FcPatternCreate();
  if (!family || !pat) goto error;

  /* Try to parse a Postscript font name and make a corresponding pattern */
  /* Consider everything up to the first dash to be the family name */
  traits = strchr(family, '-');
  if (traits) {
    *traits = '\0';
    traits++;
  }
  success = FcPatternAddString(pat, FC_FAMILY, (FcChar8 *)family);
  if (!success) goto error;
  if (traits) {
    /* FIXME: The following is incomplete and may also be wrong */
    /* Fontconfig assumes Medium Roman Regular so don't care about theese */
    if (strstr(traits, "Bold"))
      success |= FcPatternAddInteger(pat, FC_WEIGHT, FC_WEIGHT_BOLD);
    if (strstr(traits, "Italic"))
      success |= FcPatternAddInteger(pat, FC_SLANT, FC_SLANT_ITALIC);
    if (strstr(traits, "Oblique"))
      success |= FcPatternAddInteger(pat, FC_SLANT, FC_SLANT_OBLIQUE);
    if (strstr(traits, "Condensed"))
      success |= FcPatternAddInteger(pat, FC_WIDTH, FC_WIDTH_CONDENSED);
    if (!success) goto error;
  }

  success = FcConfigSubstitute(NULL, pat, FcMatchPattern);
  if (!success) goto error;
  FcDefaultSubstitute(pat);
  pat = FcFontMatch(NULL, pat, &fcres);
  if (!pat) goto error;
  free(family);
  return pat;

error:
  errlog("%s:%d: opal_FcPatternCreateFromName failed\n", __FILE__, __LINE__);
  if (family) free (family);
  if (pat) FcPatternDestroy(pat);
  return NULL;
}

#endif
