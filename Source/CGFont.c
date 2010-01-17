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

#include "CoreGraphics/CGBase.h"
#include "CoreGraphics/CGDataProvider.h"
#include "CoreGraphics/CGFont.h"
#include <stdlib.h>
#include <string.h>
#include "cairo-ft.h"
#include FT_LIST_H
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

typedef struct CGFont
{
  struct objbase base;
  cairo_font_face_t *face;
} CGFont;

void opal_dealloc_CGFont(void *f)
{
  CGFontRef font = f;
  cairo_font_face_destroy(font->face);
  free(font);
}

CGFontRef opal_FontCreateWithName(const char *name)
{
  FcPattern *pat;
  CGFontRef font = opal_obj_alloc("CGFont", sizeof(CGFont));
  if (!font) return NULL;

  pat = opal_FcPatternCacheLookup(name);
  if(pat) {
    font->face = cairo_ft_font_face_create_for_pattern(pat);
  } else {
    CGFontRelease(font);
    return NULL;
  }
  return font;
}

bool CGFontCanCreatePostScriptSubset(
  CGFontRef font,
  CGFontPostScriptFormat format)
{
  return false;
}

CFStringRef CGFontCopyFullName(CGFontRef font)
{

}

CFStringRef CGFontCopyGlyphNameForGlyph(CGFontRef font, CGGlyph glyph)
{

}

CFStringRef CGFontCopyPostScriptName(CGFontRef font)
{

}

CFDataRef CGFontCopyTableForTag(CGFontRef font, uint32_t tag)
{

}

CFArrayRef CGFontCopyTableTags(CGFontRef font)
{

}

CFArrayRef CGFontCopyVariationAxes(CGFontRef font)
{

}

CFDictionaryRef CGFontCopyVariations(CGFontRef font)
{

}

CGFontRef CGFontCreateCopyWithVariations(
  CGFontRef font,
  CFDictionaryRef variations)
{

}

CFDataRef CGFontCreatePostScriptEncoding(
  CGFontRef font,
  const CGGlyph encoding[256])
{

}

CFDataRef CGFontCreatePostScriptSubset(
  CGFontRef font,
  CFStringRef name,
  CGFontPostScriptFormat format,
  const CGGlyph glyphs[],
  size_t count,
  const CGGlyph encoding[256])
{

}

CGFontRef CGFontCreateWithDataProvider(CGDataProviderRef provider)
{

}

CGFontRef CGFontCreateWithFontName(CFStringRef name)
{

}

CGFontRef CGFontCreateWithPlatformFont(void *platformFontReference)
{
  cairo_font_face_t *cfont;
  cairo_status_t cret;

  /* FIXME: The FT_Face should not be freed until cairo is done with it */
  cfont = cairo_ft_font_face_create_for_ft_face(platformFontReference,
            FT_LOAD_DEFAULT);
  cret = cairo_font_face_status(cfont);
  if (cret) {
    errlog("%s:%d: cairo_ft_font_face_create status: %s\n",
           __FILE__, __LINE__, cairo_status_to_string(cret));
    cairo_font_face_destroy(cfont);
    return NULL;
  }

  return (CGFontRef)cfont;
}

int CGFontGetAscent(CGFontRef font)
{

}

int CGFontGetCapHeight(CGFontRef font)
{

}

int CGFontGetDescent(CGFontRef font)
{

}

CGRect CGFontGetFontBBox(CGFontRef font)
{

}

bool CGFontGetGlyphAdvances(
  CGFontRef font,
  const CGGlyph glyphs[],
  size_t count,
  int advances[])
{
}

bool CGFontGetGlyphBBoxes(
  CGFontRef font,
  const CGGlyph glyphs[],
  size_t count,
  CGRect bboxes[])
{

}

CGGlyph CGFontGetGlyphWithGlyphName(CGFontRef font, CFStringRef glyphName)
{

}

CGFloat CGFontGetItalicAngle(CGFontRef font)
{

}

int CGFontGetLeading(CGFontRef font)
{

}

size_t CGFontGetNumberOfGlyphs(CGFontRef font)
{

}

CFTypeID CGFontGetTypeID()
{

}

int CGFontGetUnitsPerEm(CGFontRef font)
{

}

int CGFontGetXHeight(CGFontRef font)
{

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

