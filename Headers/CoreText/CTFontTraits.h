/** <title>CTFontTraits</title>

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

#ifndef OPAL_CTFontTraits_h
#define OPAL_CTFontTraits_h

#include <CoreGraphics/CGBase.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Constants */

extern const CFStringRef kCTFontSymbolicTrait;
extern const CFStringRef kCTFontWeightTrait;
extern const CFStringRef kCTFontWidthTrait;
extern const CFStringRef kCTFontSlantTrait;

enum {
  kCTFontClassMaskShift = 28
};

enum {
  kCTFontTraitItalic = (1 << 0),
  kCTFontTraitBold = (1 << 1),
  kCTFontTraitExpanded = (1 << 5),
  kCTFontTraitCondensed = (1 << 6),
  kCTFontTraitMonoSpace = (1 << 10),
  kCTFontTraitVertical = (1 << 11),
  kCTFontTraitUIOptimized = (1 << 12),
  kCTFontTraitColorGlyphs = (1 << 13),
  kCTFontTraitComposite = (1 << 14),

  kCTFontTraitClassMask = (15U << kCTFontClassMaskShift),

  kCTFontItalicTrait = kCTFontTraitItalic,
  kCTFontBoldTrait = kCTFontTraitBold,
  kCTFontExpandedTrait = kCTFontTraitExpanded,
  kCTFontCondensedTrait = kCTFontTraitCondensed,
  kCTFontMonoSpaceTrait = kCTFontTraitMonoSpace,
  kCTFontVerticalTrait = kCTFontTraitVertical,
  kCTFontUIOptimizedTrait = kCTFontTraitUIOptimized,
  kCTFontColorGlyphsTrait = kCTFontTraitColorGlyphs,
  kCTFontCompositeTrait = kCTFontTraitComposite,
  kCTFontClassMaskTrait = kCTFontTraitClassMask
};
typedef int CTFontSymbolicTraits;

enum {
  kCTFontUnknownClass = (0 << 28),
  kCTFontOldStyleSerifsClass = (1 << 28),
  kCTFontTransitionalSerifsClass = (2 << 28),
  kCTFontModernSerifsClass = (3 << 28),
  kCTFontClarendonSerifsClass = (4 << 28),
  kCTFontSlabSerifsClass = (5 << 28),
  kCTFontFreeformSerifsClass = (7 << 28),
  kCTFontSansSerifClass = (8 << 28),
  kCTFontOrnamentalsClass = (9 << 28),
  kCTFontScriptsClass = (10 << 28),
  kCTFontSymbolicClass = (12 << 28)
};
typedef int CTFontStylisticClass;

#ifdef __cplusplus
}
#endif

#endif
