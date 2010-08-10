/** <title>CTFontDescriptor</title>

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

#include <CoreText/CTFontDescriptor.h>
#include <CoreText/CTFont.h>

/* Constants */

// FIXME: Some of these have to have NS... values

const CFStringRef kCTFontURLAttribute = @"kCTFontURLAttribute";
const CFStringRef kCTFontNameAttribute = @"kCTFontNameAttribute";
const CFStringRef kCTFontDisplayNameAttribute = @"kCTFontDisplayNameAttribute";
const CFStringRef kCTFontFamilyNameAttribute = @"kCTFontFamilyNameAttribute";
const CFStringRef kCTFontStyleNameAttribute = @"kCTFontStyleNameAttribute";
const CFStringRef kCTFontTraitsAttribute = @"kCTFontTraitsAttribute";
const CFStringRef kCTFontVariationAttriute = @"kCTFontVariationAttriute";
const CFStringRef kCTFontSizeAttribute = @"kCTFontSizeAttribute";
const CFStringRef kCTFontMatrixAttribute = @"kCTFontMatrixAttribute";
const CFStringRef kCTFontCascadeListAttribute = @"kCTFontCascadeListAttribute";
const CFStringRef kCTFontCharacterSetAttribute = @"kCTFontCharacterSetAttribute";
const CFStringRef kCTFontLanguagesAttribute = @"kCTFontLanguagesAttribute";
const CFStringRef kCTFontBaselineAdjustAttribute = @"kCTFontBaselineAdjustAttribute";
const CFStringRef kCTFontMacintoshEncodingsAttribute = @"kCTFontMacintoshEncodingsAttribute";
const CFStringRef kCTFontFeaturesAttribute = @"kCTFontFeaturesAttribute";
const CFStringRef kCTFontFeatureSettingsAttribute = @"kCTFontFeatureSettingsAttribute";
const CFStringRef kCTFontFixedAdvanceAttribute = @"kCTFontFixedAdvanceAttribute";
const CFStringRef kCTFontOrientationAttribute = @"kCTFontOrientationAttribute";
const CFStringRef kCTFontEnabledAttribute = @"kCTFontEnabledAttribute";
const CFStringRef kCTFontFormatAttribute = @"kCTFontFormatAttribute";
const CFStringRef kCTFontRegistrationScopeAttribute = @"kCTFontRegistrationScopeAttribute";
const CFStringRef kCTFontPriorityAttribute = @"kCTFontPriorityAttribute";

@interface CTFontDescriptor : NSObject
{
  NSDictionary *_attributes;
}

- (id)initWithName: (NSString*)name andSize: (CGFloat)size;
- (id)initWithAttributes: (NSDictionary*)attributes;

- (id)copyWithAddedAttrbutes: (NSDictionary*)attributes;
- (id)copyWithVariationIdentifier: (NSNumber*)identifier value: (CGFloat)value;
- (id)copyWithFeatureType: (NSNumber *)type selector: (NSNumber*)selector;

- (NSArray *)matchingFontDescriptorsWithMandatoryAttributes: (NSSet*)attributes;
- (CTFontDescriptorRef)matchingFontDescriptorWithMandatoryAttributes: (NSSet*)attributes;

- (NSDictionary *)attributes;
- (id)valueForAttribute: (NSString*)attribute;
- (id)valueForLocalizedAttribute: (NSString*)attribute language: (NSString**)language;

@end

@implementation CTFontDescriptor

- (id)initWithName: (NSString*)name andSize: (CGFloat)size
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  [dict setObject: name forKey: kCTFontNameAttribute];
  if (size != 0.0)
  {
    [dict setObject: [NSNumber numberWithFloat: size] forKey: kCTFontNameAttribute];
  }
  return [self initWithAttributes: dict];
}
- (id)initWithAttributes: (NSDictionary*)attributes
{
  self = [super init];

  attributes = [[NSDictionary alloc] initWithDictionary: attributes];

  return self;
}

- (id)copyWithAddedAttrbutes: (NSDictionary*)attributes
{
  NSMutableDictionary *newAttributes = [_attributes mutableCopy];
  [newAttributes addEntriesFromDictionary: attributes];

  CTFontDescriptor *new = [[CTFontDescriptor alloc] initWithAttributes: newAttributes];
  [newAttributes release];

  return new;
}
- (id)copyWithVariationIdentifier: (NSNumber*)identifier value: (CGFloat)value
{
  NSMutableDictionary *newAttributes = [_attributes mutableCopy];
  NSMutableDictionary *newVariation = [[_attributes objectForKey: kCTFontVariationAttriute] mutableCopy];
  if (nil == newVariation)
  {
    newVariation = [[NSMutableDictionary alloc] init];
  }
  [newVariation setObject: [NSNumber numberWithFloat: value] forKey: identifier];
  [newAttributes setObject: newVariation forKey: kCTFontVariationAttriute];

  CTFontDescriptor *new = [[CTFontDescriptor alloc] initWithAttributes: newAttributes];
  [newAttributes release];
  [newVariation release];

  return new;
}
/**
 * Sets a given font feature
 */
- (id)copyWithFeatureType: (NSNumber *)type selector: (NSNumber*)selector
{
  NSMutableDictionary *newAttributes = [_attributes mutableCopy];
  NSMutableArray *newFeatures = [[_attributes objectForKey: kCTFontFeatureSettingsAttribute] mutableCopy];
  if (nil == newFeatures)
  {
    newFeatures = [[NSMutableArray alloc] init];
  }
  [newFeatures addObject:
    [NSDictionary dictionaryWithObjectsAndKeys:
      type, kCTFontFeatureTypeIdentifierKey,
      selector, kCTFontFeatureSelectorIdentifierKey,
      nil]];
  [newAttributes setObject: newFeatures forKey: kCTFontFeatureSettingsAttribute];

  CTFontDescriptor *new = [[CTFontDescriptor alloc] initWithAttributes: newAttributes];
  [newAttributes release];
  [newFeatures release];

  return new;
}

- (NSArray *)matchingFontDescriptorsWithMandatoryAttributes: (NSSet*)attributes
{
  return nil;
}

- (CTFontDescriptorRef)matchingFontDescriptorWithMandatoryAttributes: (NSSet*)attributes
{
  NSArray *found = [self matchingFontDescriptorsWithMandatoryAttributes: attributes];

  if (found && ([found count] > 0))
  {
    return [found objectAtIndex: 0];
  }
  else
  {
    return nil;
  }
}

- (NSDictionary *)attributes
{

}
- (id)valueForAttribute: (NSString*)attribute
{

}
- (id)valueForLocalizedAttribute: (NSString*)attribute language: (NSString**)language
{

}

@end




/* Functions */

CTFontDescriptorRef CTFontDescriptorCreateWithNameAndSize(
  CFStringRef name,
  CGFloat size);

CTFontDescriptorRef CTFontDescriptorCreateWithAttributes(CFDictionaryRef attributes);
  
CTFontDescriptorRef CTFontDescriptorCreateCopyWithAttributes(
  CTFontDescriptorRef original,
  CFDictionaryRef attributes)
{

}

CTFontDescriptorRef CTFontDescriptorCreateCopyWithVariation(
  CTFontDescriptorRef original,
  CFNumberRef variationIdentifier,
  CGFloat variationValue)
{

}

CTFontDescriptorRef CTFontDescriptorCreateCopyWithFeature(
  CTFontDescriptorRef original,
  CFNumberRef featureTypeIdentifier,
  CFNumberRef featureSelectorIdentifier)
{

}

CFArrayRef CTFontDescriptorCreateMatchingFontDescriptors(
  CTFontDescriptorRef descriptor,
  CFSetRef mandatoryAttributes)
{

}

CTFontDescriptorRef CTFontDescriptorCreateMatchingFontDescriptor(
  CTFontDescriptorRef descriptor,
  CFSetRef mandatoryAttributes)
{

}

CFDictionaryRef CTFontDescriptorCopyAttributes(CTFontDescriptorRef descriptor)
{

}

CFTypeRef CTFontDescriptorCopyAttribute(
  CTFontDescriptorRef descriptor,
  CFStringRef attribute)
{

}

CFTypeRef CTFontDescriptorCopyLocalizedAttribute(
  CTFontDescriptorRef descriptor,
  CFStringRef attribute,
  CFStringRef *language)
{

}

CFTypeID CTFontDescriptorGetTypeID()
{

}

