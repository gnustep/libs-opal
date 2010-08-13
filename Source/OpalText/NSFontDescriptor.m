/** <title>NSFontDescriptor</title>

   <abstract>The font descriptor class</abstract>

   Copyright (C) 2007 Free Software Foundation, Inc.

   Author: H. Nikolaus Schaller <hns@computer.org>
   Date: 2006
   Extracted from NSFont: Fred Kiefer <fredkiefer@gmx.de>
   Date August 2007

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

#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#include <CoreText/CTFontDescriptor.h>
#import "NSFontDescriptor.h"


@implementation NSFontDescriptor

+ (id) fontDescriptorWithFontAttributes: (NSDictionary *)attributes
{
  return AUTORELEASE([[self alloc] initWithFontAttributes: attributes]);
}

+ (id) fontDescriptorWithName: (NSString *)name
		       matrix: (NSAffineTransform *)matrix
{
  return [self fontDescriptorWithFontAttributes:
    [NSDictionary dictionaryWithObjectsAndKeys:
      name, NSFontNameAttribute,
      matrix, NSFontMatrixAttribute,
      nil]];
}

+ (id) fontDescriptorWithName: (NSString *)name size: (CGFloat)size
{
  return [self fontDescriptorWithFontAttributes:
    [NSDictionary dictionaryWithObjectsAndKeys:
      name, NSFontNameAttribute,
      [NSString stringWithFormat: @"%f", size], NSFontSizeAttribute,
      nil]];
}

- (NSDictionary *) fontAttributes
{
  return _attributes;
}

- (NSFontDescriptor *) fontDescriptorByAddingAttributes:
  (NSDictionary *)attributes
{
  NSMutableDictionary *m = [_attributes mutableCopy];
  NSFontDescriptor *new;

  [m addEntriesFromDictionary: attributes];

  new = [isa fontDescriptorWithFontAttributes: m];
  RELEASE(m);

  return new;
}

- (NSFontDescriptor *) fontDescriptorWithFace: (NSString *)face
{
  return [self fontDescriptorByAddingAttributes:
    [NSDictionary dictionaryWithObject: face forKey: NSFontFaceAttribute]];
}

- (NSFontDescriptor *) fontDescriptorWithFamily: (NSString *)family
{
  return [self fontDescriptorByAddingAttributes:
    [NSDictionary dictionaryWithObject: family forKey: NSFontFamilyAttribute]];
}

- (NSFontDescriptor *) fontDescriptorWithMatrix: (NSAffineTransform *)matrix
{
  return [self fontDescriptorByAddingAttributes:
    [NSDictionary dictionaryWithObject: matrix forKey: NSFontMatrixAttribute]];
}

- (NSFontDescriptor *) fontDescriptorWithSize: (CGFloat)size
{
  return [self fontDescriptorByAddingAttributes:
    [NSDictionary dictionaryWithObject: [NSString stringWithFormat:@"%f", size]
				forKey: NSFontSizeAttribute]];
}

- (NSFontDescriptor *) fontDescriptorWithSymbolicTraits:
  (NSFontSymbolicTraits)symbolicTraits
{
  NSDictionary *traits;

  traits = [_attributes objectForKey: NSFontTraitsAttribute];
  if (traits == nil)
    {
      traits = [NSDictionary dictionaryWithObject: 
			       [NSNumber numberWithUnsignedInt: symbolicTraits]
			     forKey: NSFontSymbolicTrait];
    }
  else
    {
      traits = AUTORELEASE([traits mutableCopy]);
      [(NSMutableDictionary*)traits setObject: 
			       [NSNumber numberWithUnsignedInt: symbolicTraits]
			     forKey: NSFontSymbolicTrait];
    }

  return [self fontDescriptorByAddingAttributes:
		 [NSDictionary dictionaryWithObject: traits
			       forKey: NSFontTraitsAttribute]];
}

- (id) initWithFontAttributes: (NSDictionary *)attributes
{
  if ((self = [super init]) != nil)
  {
    if (attributes)
      _attributes = [attributes copy];
    else
      _attributes = [NSDictionary new];
  }
  return self;
}

// Private
- (void)handleKey: (NSString*)key selector: (SEL)selector valueClass: (Class)valueClass
{
  id value = [[self attributes] objectForKey: key];
  if (value)
  {
    if ([[value class] isKindOfClass: valueClass])
    {
      if ([self respondsToSelector: selector])
      {
        [self performSelector: selector withObject: value];
      }
    }
    else
    {
      NSLog(@"NSFontDescriptor: Ignoring invalid value %@ for attribute %@", value, key);
    }
  }
}

/**
 * Call in subclasses -initWithFontAttributes method to have custom handlers invoked
 * for each attribute key
 */
- (void)handleAddValues
{
  [self handleKey: kCTFontURLAttribute selector: @selector(addURL:) valueClass: [NSURL class]];
  [self handleKey: kCTFontNameAttribute selector: @selector(addName:) valueClass: [NSString class]];
  [self handleKey: kCTFontDisplayNameAttribute selector: @selector(addDisplayName:) valueClass: [NSString class]];
  [self handleKey: kCTFontFamilyNameAttribute selector: @selector(addFamilyName:) valueClass: [NSString class]];
  [self handleKey: kCTFontStyleNameAttribute selector: @selector(addStyleName:) valueClass: [NSString class]];
  [self handleKey: kCTFontTraitsAttribute selector: @selector(addTraits:) valueClass: [NSDictionary class]];
  [self handleKey: kCTFontVariationAttribute selector: @selector(addVariation:) valueClass: [NSDictionary class]];
  [self handleKey: kCTFontSizeAttribute selector: @selector(addSize:) valueClass: [NSNumber class]];
  [self handleKey: kCTFontMatrixAttribute selector: @selector(addMatrix:) valueClass: [NSData class]];
  [self handleKey: kCTFontCascadeListAttribute selector: @selector(addCascadeList:) valueClass: [NSArray class]];
  [self handleKey: kCTFontCharacterSetAttribute selector: @selector(addCharacterSet:) valueClass: [NSCharacterSet class]];
  [self handleKey: kCTFontLanguagesAttribute selector: @selector(addLanguages:) valueClass: [NSArray class]];
  [self handleKey: kCTFontBaselineAdjustAttribute selector: @selector(addBaselineAdjust:) valueClass: [NSNumber class]];
  [self handleKey: kCTFontMacintoshEncodingsAttribute selector: @selector(addMacintoshEncodings:) valueClass: [NSNumber class]];
  [self handleKey: kCTFontFeaturesAttribute selector: @selector(addFeatures:) valueClass: [NSArray class]];
  [self handleKey: kCTFontFeatureSettingsAttribute selector: @selector(addFeatureSettings:) valueClass: [NSArray class]];
  [self handleKey: kCTFontFixedAdvanceAttribute selector: @selector(addFixedAdvance:) valueClass: [NSNumber class]];
  [self handleKey: kCTFontOrientationAttribute selector: @selector(addOrientation:) valueClass: [NSNumber class]];
  [self handleKey: kCTFontFormatAttribute selector: @selector(addFormat:) valueClass: [NSNumber class]];
  [self handleKey: kCTFontRegistrationScopeAttribute selector: @selector(addRegistrationScope:) valueClass: [NSNumber class]];
  [self handleKey: kCTFontPriorityAttribute selector: @selector(addPriority:) valueClass: [NSNumber class]];
  [self handleKey: kCTFontEnabledAttribute selector: @selector(addEnabled:) valueClass: [NSNumber class]];
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
	if ([aCoder allowsKeyedCoding])
  {
    [aCoder encodeObject: _attributes forKey: @"NSAttributes"];
  }
  else
  {
    [aCoder encodeObject: _attributes];
  }
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  if ([aDecoder allowsKeyedCoding])
  {
    _attributes = RETAIN([aDecoder decodeObjectForKey: @"NSAttributes"]);
  }
  else
  {
    [aDecoder decodeValueOfObjCType: @encode(id) at: &_attributes];
  }
  return self;
}
	
- (void) dealloc;
{
  RELEASE(_attributes);
  [super dealloc];
}

- (id) copyWithZone: (NSZone *)z
{
  NSFontDescriptor *f = [isa allocWithZone: z];

  if (f != nil)
  {
    f->_attributes = [_attributes copyWithZone: z];
  }
  return f;
}

/**
 * Override in subclass
 */
- (NSArray *) matchingFontDescriptorsWithMandatoryKeys: (NSSet *)keys
{
  return nil;
}

- (NSFontDescriptor *) matchingFontDescriptorWithMandatoryKeys: (NSSet *)keys;
{
  NSArray *found = [self matchingFontDescriptorsWithMandatoryKeys: keys];

  if (found && ([found count] > 0))
  {
    return [found objectAtIndex: 0];
  }
  else
  {
    return nil;
  }
}

- (NSAffineTransform *) matrix
{
  return [self objectForKey: NSFontMatrixAttribute];
}

/**
 * Override in subclass
 */
- (id) objectForKey: (NSString *)attribute
{
  return [_attributes objectForKey: attribute];
}

/**
 * Override in subclass
 */
- (id) localizedObjectForKey: (NSString*)key language: (NSString**)languageOut
{
  return [self objectForKey: key];
}

- (CGFloat) pointSize
{
  // NOTE: 0 is returned if point size is not defined
  return [[self objectForKey: NSFontSizeAttribute] doubleValue];
}

- (NSString *) postscriptName
{
  return [self objectForKey: NSFontNameAttribute];
}

- (NSFontSymbolicTraits) symbolicTraits
{
  NSDictionary *traits = [self objectForKey: NSFontTraitsAttribute];
  if (traits == nil)
  {
    return 0;
  }
  else
  {
    return [[traits objectForKey: NSFontSymbolicTrait] unsignedIntValue];
  }
}

@end
