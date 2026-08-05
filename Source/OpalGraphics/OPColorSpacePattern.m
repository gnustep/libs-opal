/** <title>OPColorSpacePattern</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2026 Free Software Foundation, Inc.</copy>

   Author: Todd White <todd.white@thalion.global>
   Date: July 2026

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

#import <Foundation/NSObject.h>
#include "OPColorSpacePattern.h"

@implementation OPColorSpacePattern

- (id) initWithBaseSpace: (CGColorSpaceRef)aBaseSpace
{
  self = [super init];
  if (self)
    {
      base = CGColorSpaceRetain(aBaseSpace);
    }
  return self;
}

- (void) dealloc
{
  CGColorSpaceRelease(base);
  [super dealloc];
}

- (CGColorSpaceRef) baseColorSpace
{
  return base;
}

- (CGColorSpaceModel) model
{
  return kCGColorSpaceModelPattern;
}

- (size_t) numberOfComponents
{
  return base ? CGColorSpaceGetNumberOfComponents(base) : 0;
}

- (NSData *) ICCProfile
{
  return nil;
}

- (NSString *) name
{
  return nil;
}

- (BOOL) isEqual: (id)other
{
  if (self == other)
    {
      return YES;
    }
  if (![other isKindOfClass: [OPColorSpacePattern class]])
    {
      return NO;
    }
  CGColorSpaceRef otherBase = ((OPColorSpacePattern *)other)->base;
  if (base == otherBase)
    {
      return YES;
    }
  return base != NULL && otherBase != NULL && [(id)base isEqual: (id)otherBase];
}

@end
