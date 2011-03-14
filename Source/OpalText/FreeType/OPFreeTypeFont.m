/** <title>OPFreeTypeFont</title>

   <abstract>Font Handling Class using FreeType2</abstract>

   Copyright <copy>(C) 2011 Free Software Foundation, Inc.</copy>

   Author: Niels Grewe
   Date: Feb 2011

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */


#import "OPFreeTypeFont.h"
#import "OPFreeTypeUtil.h"
#include <stdint.h>

#include FT_TRUETYPE_TABLES_H
#include FT_TRUETYPE_TAGS_H
#include FT_TYPE1_TABLES_H
#include FT_GLYPH_H


#define REAL_SIZE(x) CGFloatFromFontUnits(x, [_descriptor pointSize], fontFace->units_per_EM)

static FT_Library OPFreeTypeLibrary = 0;


@interface NSObject (NSFontconfigFontDescriptorInternals)
- (NSString*)_fontPath;
- (NSInteger)_fontfaceIndex;
@end

@implementation OPFreeTypeFont
+ (void)initialize
{
  if ([OPFreeTypeFont class] == self)
  {
    NSInteger error = FT_Init_FreeType(&OPFreeTypeLibrary);
    if (0 != error)
    {
      [NSException raise: @"OTFontSystemException"
                  format: @"An error (%ld) occurred when initializing the FreeType library.", error];
    }
  }
}

- (id)_initWithDescriptor: (NSFontDescriptor*)aDescriptor
                  options: (CTFontOptions)options
{
  NSInteger error = 0;
  const char* path;
  NSInteger faceIndex = NSNotFound;
  if (nil == (self = [super _initWithDescriptor: aDescriptor
                                        options: options]))
  {
    return nil;
  }
  /*
   * FIXME: It is ugly to rely on the font descriptor being a
   * NSFontconfigFontDescriptor but it is probably the most common situation.
   */
  if ([aDescriptor respondsToSelector: @selector(_fontPath)])
  {
    path = [[_descriptor _fontPath] UTF8String];
  }
  else
  {
    path = NULL;
  }
  if ([aDescriptor respondsToSelector: @selector(_fontfaceIndex)])
  {
    faceIndex = [_descriptor _fontfaceIndex];
  }

  if ((NSNotFound == faceIndex) || (NULL == path))
  {
    NSWarnMLog(@"Could not read freetype intialization information from font descriptor");
    [self release];
    return nil;
  }

  error = FT_New_Face(OPFreeTypeLibrary, path, faceIndex, &fontFace);
  if (0 != error)
  {
    NSWarnMLog(@"Could not initialize freetype font (error: %ld)",
      error);
    [self release];
    return nil;
  }

  /*
   * Check whether we are dealing with an sfnt packaged font. If not, we may be
   * loading a Type-1 font. We can use those as well, but we need to load the
   * metrics from the corresponding afm file.
   */
  if ((0 == faceIndex) && (NO == (BOOL)FT_IS_SFNT(fontFace)))
  {
    if (NO == [self attachMetricsForFontAtPath: [_descriptor _fontPath]])
    {
      [self release];
      return nil;
    }
    else
    {
      /*
       * We were able to load the metrics for the font and flag the font object
       * accordingly.
       * FIXME: Move to another subclass in this case.
       */
      isType1 = YES;
    }
  }
  // At this point, we are sure that freetype has a proper reference to the
  // font, so it's worth setting up our table cache now.
  tableCache = [[NSCache alloc] init];
  [tableCache setEvictsObjectsWithDiscardedContent: YES];

  //FIXME: Do more stuff
  return self;
}

- (BOOL)attachMetricsForFontAtPath: (NSString*)path
{
  NSString *extension = [[path pathExtension] lowercaseString];
  NSString *afmPath = nil;
  NSInteger error = 0;

  if ([@"pfa" isEqual: extension] || [@"pfb" isEqual: extension])
  {
    /*
     * If the file already has a proper Type-1 extension, we assume that we need
     * to replace that with .afm. Hence, we remove the extension from the path
     * at this point.
     */
    afmPath = [path substringToIndex: ([path length] - 4)];
  }
  else
  {
    afmPath = path;
  }

  // Add the proper extension
  afmPath = [afmPath stringByAppendingString: @".afm"];

  // We just leave loading the metric to freetype:
  error = FT_Attach_File(fontFace, [afmPath UTF8String]);

  // Return NO if an error occurred:
  return (0 == error);
}


- (NSData*)loadTableForTag: (uint32_t)tag
{
  NSUInteger length = 0;
  NSInteger error = 0;
  void *buffer;
  NSData *table = nil;

  if (0 == tag)
  {
    // tag == 0 means "whole file", and the caller didn't really mean that.
    return nil;
  }

  // First, run with a NULL pointer for the buffer to obtain the length needed.
  error = FT_Load_Sfnt_Table(fontFace, tag, 0, NULL, &length);

  if (0 != error)
  {
    return nil;
  }

  // Allocate memory for the table:
  buffer = malloc(length);
  if (NULL == buffer)
  {
    return nil;
  }

  // Now load the table into the buffer:
  error = FT_Load_Sfnt_Table(fontFace, tag, 0, buffer, &length);

  if (0 != error)
  {
    // Oops, we could not fill the buffer, so we throw it away.
    free(buffer);
    return nil;
  }

  table = [NSData dataWithBytesNoCopy: buffer
                               length: length];
  /*
   * NOTE: the table object takes ownership of the allocated buffer and will
   * free it on deallocation.
   */
  return table;
}

- (NSData*)tableForTag: (uint32_t)tag
{
  // Unpack the tag into a table name:
  uint32_t first = tag;
  uint32_t second = tag >> 8;
  uint32_t third = tag >> 16;
  uint32_t fourth = tag >> 24;
  unichar tagUnichars[4] = {*(char*)&first, *(char*)&second, *(char*)&third, *(char*)&fourth};
  NSString *tagString = [[NSString alloc] initWithCharacters: tagUnichars
                                                      length: 4];
  NSData *table = [tableCache objectForKey: tagString];
  if (nil == table)
  {
    table = [self loadTableForTag: tag];
    if (table != nil)
    {
      [tableCache setObject: table
                     forKey: tagString
		       cost: [table length]];
    }
  }

  [tagString release];
  return table;
}

- (CGFloat)unitsPerEm
{
  return (CGFloat)fontFace->units_per_EM;
}

- (CGFloat)ascender
{
  return ((fontFace->ascender * [_descriptor pointSize]) / (CGFloat)fontFace->units_per_EM);
}

- (CGFloat)descender
{
  return ((fontFace->descender * [_descriptor pointSize]) / (CGFloat)fontFace->units_per_EM);
}

/* TODO: If this kind of method is too slow, we will have to cache the results
 * instead of the tables.
 */
- (CGFloat)capHeight
{
  FT_Short rawCapHeight = 0;
  TT_OS2* OS2Table = FT_Get_Sfnt_Table(fontFace, TTAG_OS2);
  if (NULL == OS2Table)
  {
    return 0;
  }
  rawCapHeight = OS2Table->sCapHeight;
  return REAL_SIZE(rawCapHeight);
}

- (CGFloat)xHeight
{
  FT_Short rawXHeight = 0;
  TT_OS2* OS2Table = FT_Get_Sfnt_Table(fontFace, TTAG_OS2);
  if (NULL == OS2Table)
  {
    return 0;
  }
  rawXHeight = OS2Table->sxHeight;
  return REAL_SIZE(rawXHeight);

}

- (BOOL)isFixedPitch
{
  BOOL isFixedPitch = NO;

  TT_Postscript *postTable = FT_Get_Sfnt_Table(fontFace, TTAG_post);
  if (NULL == postTable)
  {
    return NO;
  }
  isFixedPitch = postTable->isFixedPitch;
  return isFixedPitch;
}

- (CGFloat)italicAngle
{
  FT_Fixed rawItalicAngle = 0;
  TT_Postscript *postTable = FT_Get_Sfnt_Table(fontFace, TTAG_post);
  if (NULL == postTable)
  {
    return 0;
  }
  rawItalicAngle = postTable->italicAngle;
  return CGFloatFromFT_Fixed(rawItalicAngle);
}

- (CGFloat)leading
{
  /*
   * FIXME: We should make this conditional on horizontal/vertical orientation
   * but we probably don't need to because the hhea and vhea tables are supposed
   * to be identical.
   */
  FT_Short rawLineGap = 0;
  TT_HoriHeader *hheaTable = FT_Get_Sfnt_Table(fontFace, TTAG_hhea);
  if (NULL == hheaTable)
  {
    return 0;
  }
  rawLineGap = hheaTable->Line_Gap;
  return REAL_SIZE(rawLineGap);
}

- (NSSize)maximumAdvancement
{
  /*
   * FIXME: We should make this conditional on horizontal/vertical orientation.
   */
  FT_Short rawXAdvancement = 0;
  FT_Short rawYMaxExtent = (fontFace->bbox).yMax;
  TT_HoriHeader *hheaTable = FT_Get_Sfnt_Table(fontFace, TTAG_hhea);
  if (NULL == hheaTable)
  {
    return NSMakeSize(0,0);
  }
  rawXAdvancement = hheaTable->advance_Width_Max;
  return NSMakeSize(REAL_SIZE(rawXAdvancement), REAL_SIZE(rawYMaxExtent));
}

- (NSSize)minimumAdvancement
{
  /*
   * FIXME: We should make this conditional on horizontal/vertical orientation.
   */
  return NSMakeSize(REAL_SIZE((fontFace->bbox).xMin),
    REAL_SIZE((fontFace->bbox).yMin));
}

- (NSUInteger)numberOfGlyphs
{
  return fontFace->num_glyphs;
}

- (CGFloat)underlinePosition
{
  TT_Postscript *postTable = FT_Get_Sfnt_Table(fontFace, TTAG_post);
  if (NULL == postTable)
  {
    return 0;
  }
  return REAL_SIZE(postTable->underlinePosition);
}

- (CGFloat)underlineThickness
{
  TT_Postscript *postTable = FT_Get_Sfnt_Table(fontFace, TTAG_post);
  if (NULL == postTable)
  {
    return 0;
  }
  return REAL_SIZE(postTable->underlineThickness);
}

- (void)getAdvancements: (NSSizeArray)advancements
              forGlyphs: (const NSGlyph*)glyphs
	          count: (NSUInteger)glyphCount
{

  for (int i = 0; i < glyphCount; i++)
  {
    NSGlyph theGlyph = *(glphys++);
    //FIXME: Do stuff
  }


}
@end

