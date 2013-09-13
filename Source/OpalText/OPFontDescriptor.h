/* 
   OPFontDescriptor.h

   Holds an image to use as a cursor

   Copyright (C) 2007 Free Software Foundation, Inc.

   Author:  Dr. H. Nikolaus Schaller <hns@computer.org>
   Date: 2006
   
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


#ifndef _GNUstep_H_OPFontDescriptor
#define _GNUstep_H_OPFontDescriptor

#import <Foundation/NSObject.h>

@class NSArray;
@class NSCoder;
@class NSDictionary;
@class NSSet;
@class NSString;
@class NSAffineTransform;


typedef uint32_t OPFontSymbolicTraits;

typedef enum _OPFontFamilyClass
{
  OPFontUnknownClass = 0 << 28,
  OPFontOldStyleSerifsClass = 1U << 28,
  OPFontTransitionalSerifsClass = 2U << 28,
  OPFontModernSerifsClass = 3U << 28,
  OPFontClarendonSerifsClass = 4U << 28,
  OPFontSlabSerifsClass = 5U << 28,
  OPFontFreeformSerifsClass = 7U << 28,
  OPFontSansSerifClass = 8U << 28,
  OPFontOrnamentalsClass = 9U << 28,
  OPFontScriptsClass = 10U << 28,
  OPFontSymbolicClass = 12U << 28
} OPFontFamilyClass;

enum _OPFontFamilyClassMask {
    OPFontFamilyClassMask = 0xF0000000
};

enum _OPFontTrait
{
  OPFontItalicTrait = 0x0001,
  OPFontBoldTrait = 0x0002,
  OPFontExpandedTrait = 0x0020,
  OPFontCondensedTrait = 0x0040,
  OPFontMonoSpaceTrait = 0x0400,
  OPFontVerticalTrait = 0x0800,
  OPFontUIOptimizedTrait = 0x1000
};

// FIXME: Document these with the value type

NSString *OPFontFamilyAttribute;
NSString *OPFontNameAttribute;
NSString *OPFontFaceAttribute;
NSString *OPFontSizeAttribute; 
NSString *OPFontVisibleNameAttribute; 
NSString *OPFontColorAttribute;
/**
 * NOTE: OPFontMatrixAttribute is a NSAffineTransform, unlike kCTFontMatrixAttribute which 
 * is an NSData containing a CGAffineTransform struct.
 */
NSString *OPFontMatrixAttribute;
NSString *OPFontVariationAttribute;
NSString *OPFontCharacterSetAttribute;
NSString *OPFontCascadeListAttribute;
NSString *OPFontTraitsAttribute;
NSString *OPFontFixedAdvanceAttribute;

NSString *OPFontSymbolicTrait;
NSString *OPFontWeightTrait;
NSString *OPFontWidthTrait;
NSString *OPFontSlantTrait;

NSString *OPFontVariationAxisIdentifierKey;
NSString *OPFontVariationAxisMinimumValueKey;
NSString *OPFontVariationAxisMaximumValueKey;
NSString *OPFontVariationAxisDefaultValueKey;
NSString *OPFontVariationAxisNameKey;

@interface OPFontDescriptor : NSObject <NSCopying>
{
  NSDictionary *_attributes;
}

+ (id) fontDescriptorWithFontAttributes: (NSDictionary *)attributes;
+ (id) fontDescriptorWithName: (NSString *)name
                         size: (CGFloat)size;
+ (id) fontDescriptorWithName: (NSString *)name
                       matrix: (NSAffineTransform *)matrix;
/**
 * Returns the attribute dictionary for this descriptor.
 * NOTE: This dictionary won't necessairly contain everything -objectForKey:
 * returns a value for (i.e. -objectForKey: may access a system font pattern)
 */
- (NSDictionary *) fontAttributes;
- (id) initWithFontAttributes: (NSDictionary *)attributes;

- (OPFontDescriptor *) fontDescriptorByAddingAttributes:
  (NSDictionary *)attributes;
- (OPFontDescriptor *) fontDescriptorWithFace: (NSString *)face;
- (OPFontDescriptor *) fontDescriptorWithFamily: (NSString *)family;
- (OPFontDescriptor *) fontDescriptorWithMatrix: (NSAffineTransform *)matrix;
- (OPFontDescriptor *) fontDescriptorWithSize: (CGFloat)size;
- (OPFontDescriptor *) fontDescriptorWithSymbolicTraits:
  (OPFontSymbolicTraits)traits;
- (NSArray *) matchingFontDescriptorsWithMandatoryKeys: (NSSet *)keys;

- (id) objectForKey: (NSString *)attribute;
- (NSAffineTransform *) matrix;
- (CGFloat) pointSize;
- (NSString *) postscriptName;
- (OPFontSymbolicTraits) symbolicTraits;
- (OPFontDescriptor *) matchingFontDescriptorWithMandatoryKeys: (NSSet *)keys;

//
// CTFontDescriptor private
//

- (id) localizedObjectForKey: (NSString*)key language: (NSString*)language;

//
// CTFontDescriptor private; to be overridden in subclasses
//

- (NSArray *) matchingFontDescriptorsWithMandatoryKeys: (NSSet *)keys;
- (id) objectFromPlatformFontPatternForKey: (NSString *)attribute;
- (id) localizedObjectFromPlatformFontPatternForKey: (NSString*)key language: (NSString*)language;

@end

#endif /* _GNUstep_H_OPFontDescriptor */
