/*
   OPFont.h

   The font class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Author:  Ovidiu Predescu <ovidiu@net-community.com>
   Date: 1996, 1997

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_OPFont
#define _GNUstep_H_OPFont

#include <CoreText/CTFont.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

#import "OPFontDescriptor.h"

@class NSAffineTransform;
@class NSCharacterSet;
@class NSDictionary;
@class OPFontDescriptor;
@class NSGraphicsContext;

typedef unsigned int NSGlyph;

enum {
  NSControlGlyph = 0x00ffffff,
  GSAttachmentGlyph = 0x00fffffe,
  NSNullGlyph = 0x0
};

typedef enum _NSGlyphRelation {
  NSGlyphBelow,
  NSGlyphAbove,
} NSGlyphRelation;

typedef enum _NSMultibyteGlyphPacking {
  NSOneByteGlyphPacking,
  NSJapaneseEUCGlyphPacking,
  NSAsciiWithDoubleByteEUCGlyphPacking,
  NSTwoByteGlyphPacking,
  NSFourByteGlyphPacking
} NSMultibyteGlyphPacking;

typedef enum _OPFontRenderingMode
{
  OPFontDefaultRenderingMode = 0,
  OPFontAntialiasedRenderingMode,
  OPFontIntegerAdvancementsRenderingMode,
  OPFontAntialiasedIntegerAdvancementsRenderingMode
} OPFontRenderingMode;

const CGFloat *OPFontIdentityMatrix;


/**
 * The OPAffineTransform union encapsulates three equivalent representations of
 * transformation matrices so we can avoid translating between them later on.
 */
typedef union _OPAffineTransform
{
  NSAffineTransformStruct NSTransform;
  CGAffineTransform CGTransform;
  CGFloat PSMatrix[6];
} OPAffineTransform;

/**
 * The font class.
 *
 * Note all font/glyph metrics are in user space; that means font design units
 * (often 2048 units per EM square) are divided by unitsPerEM, then transformed by
 * the PostScript matrix (textTransform scaled by pointSize).
 */
@interface OPFont : NSObject
{
  OPFontDescriptor *_descriptor;
  OPAffineTransform _matrix;
}

//
// Querying the Font
//
- (NSRect) boundingRectForFont;
- (NSString*) displayName;
- (NSString*) familyName;
- (NSString*) fontName;
- (BOOL) isFixedPitch;
/**
 * Returns the PostScript matrix; that is -textTransform scaled by -pointSize
 */
- (const CGFloat*) matrix;
/**
 * Returns the font matrix, normally the identity matrix. This is the same as the font
 * descriptor's font matrix.
 */
- (NSAffineTransform*) textTransform;
- (CGFloat) pointSize;
- (OPFont*) printerFont;
- (OPFont*) screenFont;
- (CGFloat) ascender;
- (CGFloat) descender;
- (CGFloat) capHeight;
- (CGFloat) italicAngle;
- (CGFloat) leading;
- (NSSize) maximumAdvancement;
- (CGFloat) underlinePosition;
- (CGFloat) underlineThickness;
- (CGFloat) xHeight;
- (NSUInteger) numberOfGlyphs;
- (NSCharacterSet*) coveredCharacterSet;
- (OPFontDescriptor*) fontDescriptor;
- (OPFontRenderingMode) renderingMode;
- (OPFont*) screenFontWithRenderingMode: (OPFontRenderingMode)mode;

//
// Manipulating Glyphs
//
- (NSSize) advancementForGlyph: (NSGlyph)aGlyph;
- (NSRect) boundingRectForGlyph: (NSGlyph)aGlyph;
- (void) getAdvancements: (NSSizeArray)advancements
               forGlyphs: (const NSGlyph*)glyphs
                   count: (NSUInteger)count;
- (void) getAdvancements: (NSSizeArray)advancements
         forPackedGlyphs: (const void*)packedGlyphs
                  length: (NSUInteger)count;
- (void) getBoundingRects: (NSRectArray)advancements
                forGlyphs: (const NSGlyph*)glyphs
                    count: (NSUInteger)count;
- (NSGlyph) glyphWithName: (NSString*)glyphName;
- (NSStringEncoding) mostCompatibleStringEncoding;

//
// CTFont private
//
+ (OPFont*) fontWithDescriptor: (OPFontDescriptor*)descriptor
                       options: (CTFontOptions)options;
+ (OPFont*) UIFontWithType: (CTFontUIFontType)type
                      size: (CGFloat)size
               forLanguage: (NSString*)languageCode;
+ (OPFont*) fontWithGraphicsFont: (CGFontRef)graphics
            additionalDescriptor: (OPFontDescriptor*)descriptor;
- (CGFloat) unitsPerEm;
- (NSString*) nameForKey: (NSString*)nameKey;
- (NSString*) localizedNameForKey: (NSString*)nameKey
                         language: (NSString**)languageOut;
- (bool) getGraphicsGlyphsForCharacters: (const unichar *)characters
                         graphicsGlyphs: (const CGGlyph *)glyphs
                                  count: (CFIndex)count;
- (double) getAdvancesForGraphicsGlyphs: (const CGGlyph *)glyphs
                               advances: (CGSize*)advances
                            orientation: (CTFontOrientation)orientation
                                  count: (CFIndex)count;
- (CGRect) getBoundingRectsForGraphicsGlyphs: (const CGGlyph *)glyphs
                                       rects: (CGRect*)rects
                                 orientation: (CTFontOrientation)orientation
                                       count: (CFIndex)count;
- (void) getVerticalTranslationForGraphicsGlyphs: (const CGGlyph*)glyphs
                                     translation: (CGSize*)translation
                                           count: (CFIndex)count;
- (CGPathRef) graphicsPathForGlyph: (CGGlyph)glyph
                         transform: (const CGAffineTransform *)xform;
- (NSArray*) variationAxes;
- (NSDictionary*) variation;
- (CGFontRef) graphicsFontWithDescriptor: (OPFontDescriptor**)descriptorOut;
- (NSArray*) availableTablesWithOptions: (CTFontTableOptions)options;
- (NSData*) tableForTag: (CTFontTableTag)tag
            withOptions: (CTFontTableOptions)options;
//
// CGFont private
//
- (NSString*) nameForGlyph: (CGGlyph)graphicsGlyph;
+ (CTFontRef) fontWithData: (NSData*)fontData
                      size: (CGFloat)size
       		          matrix: (const CGFloat*)fontMatrix
      additionalDescriptor: (OPFontDescriptor*)descriptor;

- (id)_initWithDescriptor: (OPFontDescriptor*)descriptor
                  options: (CTFontOptions)options;

// Put in -gui:
#if 0
//
// Creating a Font Object
//

+ (OPFont*) fontWithName: (NSString*)aFontName
                  matrix: (const CGFloat*)fontMatrix;
+ (OPFont*) fontWithName: (NSString*)aFontName
                    size: (CGFloat)fontSize;
+ (OPFont*) fontWithDescriptor: (OPFontDescriptor*)descriptor size: (CGFloat)size;
+ (OPFont*) fontWithDescriptor: (OPFontDescriptor*)descriptor
                 textTransform: (NSAffineTransform*)transform;
// This method was a mistake in the 10.4 documentation
+ (OPFont*) fontWithDescriptor: (OPFontDescriptor*)descriptor
                          size: (CGFloat)size
                 textTransform: (NSAffineTransform*)transform;

//
// UI fonts
//

+ (OPFont*) boldSystemFontOfSize: (CGFloat)fontSize;
+ (OPFont*) systemFontOfSize: (CGFloat)fontSize;
+ (OPFont*) titleBarFontOfSize: (CGFloat)fontSize;
+ (OPFont*) menuFontOfSize: (CGFloat)fontSize;
+ (OPFont*) messageFontOfSize: (CGFloat)fontSize;
+ (OPFont*) paletteFontOfSize: (CGFloat)fontSize;
+ (OPFont*) toolTipsFontOfSize: (CGFloat)fontSize;
+ (OPFont*) controlContentFontOfSize: (CGFloat)fontSize;
+ (OPFont*) labelFontOfSize: (CGFloat)fontSize;
+ (OPFont*) menuBarFontOfSize: (CGFloat)fontSize;

//
// User fonts
//

+ (OPFont*) userFixedPitchFontOfSize: (CGFloat)fontSize;
+ (OPFont*) userFontOfSize: (CGFloat)fontSize;
+ (void) setUserFixedPitchFont: (OPFont*)userFont;
+ (void) setUserFont: (OPFont*)userFont;


//
// Font Sizes
//
+ (CGFloat) labelFontSize;
+ (CGFloat) smallSystemFontSize;
+ (CGFloat) systemFontSize;
+ (CGFloat) systemFontSizeForControlSize: (NSControlSize)controlSize;

//
// Setting the Font (put in -gui)
//
- (void) set;
- (void) setInContext: (NSGraphicsContext*)context;

//
// CoreText private
//
+ (OPFont*) UIFontWithType: (CTFontUIFontType)type
                      size: (CGFloat)size
               forLanguage: (NSString*)languageCode;

//
// Deprecated (Put in -gui)
//

+ (NSArray*) preferredFontNames;
+ (void) setPreferredFontNames: (NSArray*)fontNames;
- (NSString*) encodingScheme;
- (BOOL) isBaseFont;
- (CGFloat) defaultLineHeightForFont;
- (BOOL) glyphIsEncoded: (NSGlyph)aGlyph;
- (NSMultibyteGlyphPacking) glyphPacking;
- (NSPoint) positionOfGlyph: (NSGlyph)curGlyph
	    precededByGlyph: (NSGlyph)prevGlyph
		  isNominal: (BOOL*)nominal;
- (NSPoint) positionOfGlyph: (NSGlyph)aGlyph
	       forCharacter: (unichar)aChar
	     struckOverRect: (NSRect)aRect;
- (NSPoint) positionOfGlyph: (NSGlyph)aGlyph
	    struckOverGlyph: (NSGlyph)baseGlyph
	metricsExist: (BOOL*)flag;
- (NSPoint) positionOfGlyph: (NSGlyph)aGlyph
             struckOverRect: (NSRect)aRect
               metricsExist: (BOOL*)flag;
- (NSPoint) positionOfGlyph: (NSGlyph)aGlyph
               withRelation: (NSGlyphRelation)relation
                toBaseGlyph: (NSGlyph)baseGlyph
           totalAdvancement: (NSSize*)offset
               metricsExist: (BOOL*)flag;
- (int) positionsForCompositeSequence: (NSGlyph*)glyphs
                       numberOfGlyphs: (int)numGlyphs
                           pointArray: (NSPoint*)points;
#endif


@end

#endif // _GNUstep_H_OPFont
