/** <title>CTFont</title>

   <abstract>C Interface to text layout library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Aug 2010

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

#include <CoreText/CTFont.h>

/* Constants */

const CFStringRef kCTFontCopyrightNameKey = @"kCTFontCopyrightNameKey";
const CFStringRef kCTFontFamilyNameKey = @"kCTFontFamilyNameKey";
const CFStringRef kCTFontSubFamilyNameKey = @"kCTFontSubFamilyNameKey";
const CFStringRef kCTFontStyleNameKey = @"kCTFontStyleNameKey";
const CFStringRef kCTFontUniqueNameKey = @"kCTFontUniqueNameKey";
const CFStringRef kCTFontFullNameKey = @"kCTFontFullNameKey";
const CFStringRef kCTFontVersionNameKey = @"kCTFontVersionNameKey";
const CFStringRef kCTFontPostScriptNameKey = @"kCTFontPostScriptNameKey";
const CFStringRef kCTFontTrademarkNameKey = @"kCTFontTrademarkNameKey";
const CFStringRef kCTFontManufacturerNameKey = @"kCTFontManufacturerNameKey";
const CFStringRef kCTFontDesignerNameKey = @"kCTFontDesignerNameKey";
const CFStringRef kCTFontDescriptionNameKey = @"kCTFontDescriptionNameKey";
const CFStringRef kCTFontVendorURLNameKey = @"kCTFontVendorURLNameKey";
const CFStringRef kCTFontDesignerURLNameKey = @"kCTFontDesignerURLNameKey";
const CFStringRef kCTFontLicenseNameKey = @"kCTFontLicenseNameKey";
const CFStringRef kCTFontLicenseURLNameKey = @"kCTFontLicenseURLNameKey";
const CFStringRef kCTFontSampleTextNameKey = @"kCTFontSampleTextNameKey";
const CFStringRef kCTFontPostScriptCIDNameKey = @"kCTFontPostScriptCIDNameKey";

const CFStringRef kCTFontVariationAxisIdentifierKey = @"kCTFontVariationAxisIdentifierKey";
const CFStringRef kCTFontVariationAxisMinimumValueKey = @"kCTFontVariationAxisMinimumValueKey";
const CFStringRef kCTFontVariationAxisMaximumValueKey = @"kCTFontVariationAxisMaximumValueKey";
const CFStringRef kCTFontVariationAxisDefaultValueKey = @"kCTFontVariationAxisDefaultValueKey";
const CFStringRef kCTFontVariationAxisNameKey = @"kCTFontVariationAxisNameKey";

const CFStringRef kCTFontFeatureTypeIdentifierKey = @"kCTFontFeatureTypeIdentifierKey";
const CFStringRef kCTFontFeatureTypeNameKey = @"kCTFontFeatureTypeNameKey";
const CFStringRef kCTFontFeatureTypeExclusiveKey = @"kCTFontFeatureTypeExclusiveKey";
const CFStringRef kCTFontFeatureTypeSelectorsKey = @"kCTFontFeatureTypeSelectorsKey";
const CFStringRef kCTFontFeatureSelectorIdentifierKey = @"kCTFontFeatureSelectorIdentifierKey";
const CFStringRef kCTFontFeatureSelectorNameKey = @"kCTFontFeatureSelectorNameKey";
const CFStringRef kCTFontFeatureSelectorDefaultKey = @"kCTFontFeatureSelectorDefaultKey";
const CFStringRef kCTFontFeatureSelectorSettingKey = @"kCTFontFeatureSelectorSettingKey";

/* Classes */


/* Functions */

/* Creating */

CTFontRef CTFontCreateForString(
  CTFontRef base,
  CFStringRef str,
  CFRange range)
{
}

CTFontRef CTFontCreateWithFontDescriptor(
  CTFontDescriptorRef attribs,
  CGFloat size,
  const CGAffineTransform *matrix)
{
}

CTFontRef CTFontCreateWithFontDescriptorAndOptions(
  CTFontDescriptorRef attribs,
  CGFloat size,
  const CGAffineTransform *matrix,
  CTFontOptions opts)
{
}

CTFontRef CTFontCreateWithGraphicsFont(
  CGFontRef cgFont,
  CGFloat size,
  const CGAffineTransform *matrix,
  CTFontDescriptorRef attribs)
{
}

CTFontRef CTFontCreateWithName(
  CFStringRef name,
  CGFloat size,
  const CGAffineTransform *matrix)
{
}

CTFontRef CTFontCreateWithNameAndOptions(
  CFStringRef name,
  CGFloat size,
  const CGAffineTransform *matrix,
  CTFontOptions opts)
{
}

CTFontRef CTFontCreateWithPlatformFont(
  void *platformFont,
  CGFloat size,
  const CGAffineTransform *matrix,
  CTFontDescriptorRef attribs)
{
}

CTFontRef CTFontCreateWithQuickdrawInstance(
  void *name,
  int16_t identifier,
  uint8_t style,
  CGFloat size)
{
}

CTFontRef CTFontCreateUIFontForLanguage(
  CTFontUIFontType type,
  CGFloat size,
  CFStringRef language)
{
}

/* Copying & Conversion */

CTFontRef CTFontCreateCopyWithAttributes(
  CTFontRef font,
  CGFloat size,
  const CGAffineTransform *matrix,
  CTFontDescriptorRef attribs)
{
}

CTFontRef CTFontCreateCopyWithSymbolicTraits(
  CTFontRef font,
  CGFloat size,
  const CGAffineTransform *matrix,
  CTFontSymbolicTraits value,
  CTFontSymbolicTraits mask)
{
}

CTFontRef CTFontCreateCopyWithFamily(
  CTFontRef font,
  CGFloat size,
  const CGAffineTransform *matrix,
  CFStringRef family)
{
}

void *CTFontGetPlatformFont(
  CTFontRef font,
  CTFontDescriptorRef *attribs)
{
}

CGFontRef CTFontCopyGraphicsFont(
  CTFontRef font,
  CTFontDescriptorRef *attribs)
{
}

/* Glyphs */

CFIndex CTFontGetGlyphCount(CTFontRef font)
{
}

CGPathRef CTFontCreatePathForGlyph(
  CTFontRef font,
  CGGlyph glyph,
  const CGAffineTransform *transform)
{
}

bool CTFontGetGlyphsForCharacters(
  CTFontRef font,
  const unichar characters[],
  CGGlyph glyphs[],
  CFIndex count)
{
}

CGGlyph CTFontGetGlyphWithName(
  CTFontRef font,
  CFStringRef name)
{
}

double CTFontGetAdvancesForGlyphs(
  CTFontRef font,
  CTFontOrientation orientation,
  const CGGlyph glyphs[],
  CGSize advances[],
  CFIndex count)
{
}

CGRect CTFontGetBoundingRectsForGlyphs(
  CTFontRef font,
  CTFontOrientation orientation,
  const CGGlyph glyphs[],
  CGRect rects[],
  CFIndex count)
{
}

void CTFontGetVerticalTranslationsForGlyphs(
  CTFontRef font,
  const CGGlyph glyphs[],
  CGSize translations[],
  CFIndex count)
{
}

/* Metrics */

CGFloat CTFontGetAscent(CTFontRef font)
{
}

CGFloat CTFontGetDescent(CTFontRef font)
{
}

CGFloat CTFontGetCapHeight(CTFontRef font)
{
}

CGFloat CTFontGetSize(CTFontRef font)
{
}

CGFloat CTFontGetLeading(CTFontRef font)
{
}

unsigned CTFontGetUnitsPerEm(CTFontRef font)
{
}

CGRect CTFontGetBoundingBox(CTFontRef font)
{
}

CGFloat CTFontGetUnderlinePosition(CTFontRef font)
{
}

CGFloat CTFontGetUnderlineThickness(CTFontRef font)
{
}

CGFloat CTFontGetSlantAngle(CTFontRef font)
{
}

CGFloat CTFontGetXHeight(CTFontRef font)
{
}

/* Properties */

CGAffineTransform CTFontGetMatrix(CTFontRef font)
{
}

CTFontSymbolicTraits CTFontGetSymbolicTraits(CTFontRef font)
{
}

CFTypeRef CTFontCopyAttribute(
  CTFontRef font,
  CFStringRef attrib)
{
}

CFArrayRef CTFontCopyAvailableTables(
  CTFontRef font,
  CTFontTableOptions opts)
{
}

CFDictionaryRef CTFontCopyTraits(CTFontRef font)
{
}

CFArrayRef CTFontCopyFeatures(CTFontRef font)
{
}

CFArrayRef CTFontCopyFeatureSettings(CTFontRef font)
{
}

CTFontDescriptorRef CTFontCopyFontDescriptor(CTFontRef font)
{
}

CFDataRef CTFontCopyTable(
  CTFontRef font,
  CTFontTableTag table,
  CTFontTableOptions opts)
{
}

CFArrayRef CTFontCopyVariationAxes(CTFontRef font)
{
}

CFDictionaryRef CTFontCopyVariation(CTFontRef font)
{
}

/* Encoding & Character Set */

NSStringEncoding CTFontGetStringEncoding(CTFontRef font)
{
}

CFCharacterSetRef CTFontCopyCharacterSet(CTFontRef font)
{
}

CFArrayRef CTFontCopySupportedLanguages(CTFontRef font)
{
}

/* Name */

CFStringRef CTFontCopyDisplayName(CTFontRef font)
{
}

CFStringRef CTFontCopyName(
  CTFontRef font,
  CFStringRef key)
{
}

CFStringRef CTFontCopyLocalizedName(
  CTFontRef font,
  CFStringRef key,
  CFStringRef *language)
{
}

CFStringRef CTFontCopyPostScriptName(CTFontRef font)
{
}

CFStringRef CTFontCopyFamilyName(CTFontRef font)
{
}

CFStringRef CTFontCopyFullName(CTFontRef font)
{
}

/* CFTypeID */

CFTypeID CTFontGetTypeID()
{
}

