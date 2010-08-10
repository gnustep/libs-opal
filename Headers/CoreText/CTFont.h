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

#ifndef OPAL_CTFont_h
#define OPAL_CTFont_h

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGAffineTransform.h>
#include <CoreGraphics/CGPath.h>
#include <CoreGraphics/CGFont.h>
#include <CoreText/CTFontDescriptor.h>

/* Data Types */

#ifdef __OBJC__
@class CTFont;
typedef CTFont* CTFontRef;
#else
typedef struct CTFont* CTFontRef;
#endif

/* Constants */

extern const CFStringRef kCTFontCopyrightNameKey;
extern const CFStringRef kCTFontFamilyNameKey;
extern const CFStringRef kCTFontSubFamilyNameKey;
extern const CFStringRef kCTFontStyleNameKey;
extern const CFStringRef kCTFontUniqueNameKey;
extern const CFStringRef kCTFontFullNameKey;
extern const CFStringRef kCTFontVersionNameKey;
extern const CFStringRef kCTFontPostScriptNameKey;
extern const CFStringRef kCTFontTrademarkNameKey;
extern const CFStringRef kCTFontManufacturerNameKey;
extern const CFStringRef kCTFontDesignerNameKey;
extern const CFStringRef kCTFontDescriptionNameKey;
extern const CFStringRef kCTFontVendorURLNameKey;
extern const CFStringRef kCTFontDesignerURLNameKey;
extern const CFStringRef kCTFontLicenseNameKey;
extern const CFStringRef kCTFontLicenseURLNameKey;
extern const CFStringRef kCTFontSampleTextNameKey;
extern const CFStringRef kCTFontPostScriptCIDNameKey;

extern const CFStringRef kCTFontVariationAxisIdentifierKey;
extern const CFStringRef kCTFontVariationAxisMinimumValueKey;
extern const CFStringRef kCTFontVariationAxisMaximumValueKey;
extern const CFStringRef kCTFontVariationAxisDefaultValueKey;
extern const CFStringRef kCTFontVariationAxisNameKey;

extern const CFStringRef kCTFontFeatureTypeIdentifierKey;
extern const CFStringRef kCTFontFeatureTypeNameKey;
extern const CFStringRef kCTFontFeatureTypeExclusiveKey;
extern const CFStringRef kCTFontFeatureTypeSelectorsKey;
extern const CFStringRef kCTFontFeatureSelectorIdentifierKey;
extern const CFStringRef kCTFontFeatureSelectorNameKey;
extern const CFStringRef kCTFontFeatureSelectorDefaultKey;
extern const CFStringRef kCTFontFeatureSelectorSettingKey;

typedef enum {
  kCTFontOptionsDefault = 0,
  kCTFontOptionsPreventAutoActivation = 1 << 0,
  kCTFontOptionsPreferSystemFont = 1 << 2,
} CTFontOptions;

typedef enum {
  kCTFontTableOptionNoOptions = 0,
  kCTFontTableOptionExcludeSynthetic = 1 << 0
} CTFontTableOptions;

typedef enum {
  kCTFontTableBASE = 'BASE',
  kCTFontTableCFF = 'CFF ',   
  kCTFontTableDSIG = 'DSIG',   
  kCTFontTableEBDT = 'EBDT',   
  kCTFontTableEBLC = 'EBLC',   
  kCTFontTableEBSC = 'EBSC',   
  kCTFontTableGDEF = 'GDEF',   
  kCTFontTableGPOS = 'GPOS',   
  kCTFontTableGSUB = 'GSUB',   
  kCTFontTableJSTF = 'JSTF',   
  kCTFontTableLTSH = 'LTSH',   
  kCTFontTableOS2 = 'OS/2',   
  kCTFontTablePCLT = 'PCLT',   
  kCTFontTableVDMX = 'VDMX',   
  kCTFontTableVORG = 'VORG',   
  kCTFontTableZapf = 'Zapf',   
  kCTFontTableAcnt = 'acnt',   
  kCTFontTableAvar = 'avar',   
  kCTFontTableBdat = 'bdat',   
  kCTFontTableBhed = 'bhed',   
  kCTFontTableBloc = 'bloc',   
  kCTFontTableBsln = 'bsln',   
  kCTFontTableCmap = 'cmap',   
  kCTFontTableCvar = 'cvar',   
  kCTFontTableCvt = 'cvt ',   
  kCTFontTableFdsc = 'fdsc',   
  kCTFontTableFeat = 'feat',   
  kCTFontTableFmtx = 'fmtx',   
  kCTFontTableFpgm = 'fpgm',   
  kCTFontTableFvar = 'fvar',   
  kCTFontTableGasp = 'gasp',   
  kCTFontTableGlyf = 'glyf',   
  kCTFontTableGvar = 'gvar',   
  kCTFontTableHdmx = 'hdmx',   
  kCTFontTableHead = 'head',   
  kCTFontTableHhea = 'hhea',   
  kCTFontTableHmtx = 'hmtx',   
  kCTFontTableHsty = 'hsty',   
  kCTFontTableJust = 'just',   
  kCTFontTableKern = 'kern',   
  kCTFontTableLcar = 'lcar',   
  kCTFontTableLoca = 'loca',   
  kCTFontTableMaxp = 'maxp',   
  kCTFontTableMort = 'mort',   
  kCTFontTableMorx = 'morx',   
  kCTFontTableName = 'name',   
  kCTFontTableOpbd = 'opbd',   
  kCTFontTablePost = 'post',   
  kCTFontTablePrep = 'prep',   
  kCTFontTableProp = 'prop',   
  kCTFontTableTrak = 'trak',   
  kCTFontTableVhea = 'vhea',   
  kCTFontTableVmtx = 'vmtx'    
} CTFontTableTag;

typedef enum {
  kCTFontNoFontType = -1,
  kCTFontUserFontType = 0,
  kCTFontUserFixedPitchFontType = 1,
  kCTFontSystemFontType = 2,
  kCTFontEmphasizedSystemFontType = 3,
  kCTFontSmallSystemFontType = 4,
  kCTFontSmallEmphasizedSystemFontType = 5,
  kCTFontMiniSystemFontType = 6,
  kCTFontMiniEmphasizedSystemFontType = 7,
  kCTFontViewsFontType = 8,
  kCTFontApplicationFontType = 9,
  kCTFontLabelFontType = 10,
  kCTFontMenuTitleFontType = 11,
  kCTFontMenuItemFontType = 12,
  kCTFontMenuItemMarkFontType = 13,
  kCTFontMenuItemCmdKeyFontType = 14,
  kCTFontWindowTitleFontType = 15,
  kCTFontPushButtonFontType = 16,
  kCTFontUtilityWindowTitleFontType = 17,
  kCTFontAlertHeaderFontType = 18,
  kCTFontSystemDetailFontType = 19,
  kCTFontEmphasizedSystemDetailFontType = 20,
  kCTFontToolbarFontType = 21,
  kCTFontSmallToolbarFontType = 22,
  kCTFontMessageFontType = 23,
  kCTFontPaletteFontType = 24,
  kCTFontToolTipFontType = 25,
  kCTFontControlContentFontType = 26
} CTFontUIFontType;

/* Functions */

/* Creating */

CTFontRef CTFontCreateForString(
  CTFontRef base,
  CFStringRef str,
  CFRange range
);

CTFontRef CTFontCreateWithFontDescriptor(
  CTFontDescriptorRef attribs,
  CGFloat size,
  const CGAffineTransform *matrix
);

CTFontRef CTFontCreateWithFontDescriptorAndOptions(
  CTFontDescriptorRef attribs,
  CGFloat size,
  const CGAffineTransform *matrix,
  CTFontOptions opts
);

CTFontRef CTFontCreateWithGraphicsFont(
  CGFontRef cgFont,
  CGFloat size,
  const CGAffineTransform *matrix,
  CTFontDescriptorRef attribs
);

CTFontRef CTFontCreateWithName(
  CFStringRef name,
  CGFloat size,
  const CGAffineTransform *matrix
);

CTFontRef CTFontCreateWithNameAndOptions(
  CFStringRef name,
  CGFloat size,
  const CGAffineTransform *matrix,
  CTFontOptions opts
);

CTFontRef CTFontCreateWithPlatformFont(
  void *platformFont,
  CGFloat size,
  const CGAffineTransform *matrix,
  CTFontDescriptorRef attribs
);

CTFontRef CTFontCreateWithQuickdrawInstance(
  void *name,
  int16_t identifier,
  uint8_t style,
  CGFloat size
);

CTFontRef CTFontCreateUIFontForLanguage(
  CTFontUIFontType type,
  CGFloat size,
  CFStringRef language
);

/* Copying & Conversion */

CTFontRef CTFontCreateCopyWithAttributes(
  CTFontRef font,
  CGFloat size,
  const CGAffineTransform *matrix,
  CTFontDescriptorRef attribs
);

CTFontRef CTFontCreateCopyWithSymbolicTraits(
  CTFontRef font,
  CGFloat size,
  const CGAffineTransform *matrix,
  CTFontSymbolicTraits value,
  CTFontSymbolicTraits mask
);

CTFontRef CTFontCreateCopyWithFamily(
  CTFontRef font,
  CGFloat size,
  const CGAffineTransform *matrix,
  CFStringRef family
);

void *CTFontGetPlatformFont(
  CTFontRef font,
  CTFontDescriptorRef *attribs
);

CGFontRef CTFontCopyGraphicsFont(
  CTFontRef font,
  CTFontDescriptorRef *attribs
);

/* Glyphs */

CFIndex CTFontGetGlyphCount(CTFontRef font);

CGPathRef CTFontCreatePathForGlyph(
  CTFontRef font,
  CGGlyph glyph,
  const CGAffineTransform *transform
);

bool CTFontGetGlyphsForCharacters(
  CTFontRef font,
  const unichar characters[],
  CGGlyph glyphs[],
  CFIndex count
);

CGGlyph CTFontGetGlyphWithName(
  CTFontRef font,
  CFStringRef name
);

double CTFontGetAdvancesForGlyphs(
  CTFontRef font,
  CTFontOrientation orientation,
  const CGGlyph glyphs[],
  CGSize advances[],
  CFIndex count
);

CGRect CTFontGetBoundingRectsForGlyphs(
  CTFontRef font,
  CTFontOrientation orientation,
  const CGGlyph glyphs[],
  CGRect rects[],
  CFIndex count
);

void CTFontGetVerticalTranslationsForGlyphs(
  CTFontRef font,
  const CGGlyph glyphs[],
  CGSize translations[],
  CFIndex count
);

/* Metrics */

CGFloat CTFontGetAscent(CTFontRef font);

CGFloat CTFontGetDescent(CTFontRef font);

CGFloat CTFontGetCapHeight(CTFontRef font);

CGFloat CTFontGetSize(CTFontRef font);

CGFloat CTFontGetLeading(CTFontRef font);

unsigned CTFontGetUnitsPerEm(CTFontRef font);

CGRect CTFontGetBoundingBox(CTFontRef font);

CGFloat CTFontGetUnderlinePosition(CTFontRef font);

CGFloat CTFontGetUnderlineThickness(CTFontRef font);

CGFloat CTFontGetSlantAngle(CTFontRef font);

CGFloat CTFontGetXHeight(CTFontRef font);

/* Properties */

CGAffineTransform CTFontGetMatrix(CTFontRef font);

CTFontSymbolicTraits CTFontGetSymbolicTraits(CTFontRef font);

CFTypeRef CTFontCopyAttribute(
  CTFontRef font,
  CFStringRef attrib
);

CFArrayRef CTFontCopyAvailableTables(
  CTFontRef font,
  CTFontTableOptions opts
);

CFDictionaryRef CTFontCopyTraits(CTFontRef font);

CFArrayRef CTFontCopyFeatures(CTFontRef font);

CFArrayRef CTFontCopyFeatureSettings(CTFontRef font);

CTFontDescriptorRef CTFontCopyFontDescriptor(CTFontRef font);

CFDataRef CTFontCopyTable(
  CTFontRef font,
  CTFontTableTag table,
  CTFontTableOptions opts
);

CFArrayRef CTFontCopyVariationAxes(CTFontRef font);

CFDictionaryRef CTFontCopyVariation(CTFontRef font);

/* Encoding & Character Set */

/**
 * Note: Returns NSStringEncoding instead of CFStringEncoding
 */
NSStringEncoding CTFontGetStringEncoding(CTFontRef font);

CFCharacterSetRef CTFontCopyCharacterSet(CTFontRef font);

CFArrayRef CTFontCopySupportedLanguages(CTFontRef font);

/* Name */

CFStringRef CTFontCopyDisplayName(CTFontRef font);

CFStringRef CTFontCopyName(
  CTFontRef font,
  CFStringRef key
);

CFStringRef CTFontCopyLocalizedName(
  CTFontRef font,
  CFStringRef key,
  CFStringRef *language
);

CFStringRef CTFontCopyPostScriptName(CTFontRef font);

CFStringRef CTFontCopyFamilyName(CTFontRef font);

CFStringRef CTFontCopyFullName(CTFontRef font);

/* CFTypeID */

CFTypeID CTFontGetTypeID();

#endif
