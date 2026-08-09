/* The dictionary representations of CGPoint/CGSize/CGRect use flat "X"/"Y"/
   "Width"/"Height" keys, round-trip through CG..MakeWithDictionaryRepresentation,
   and reject a dictionary that is missing keys.  The keys and behaviour match
   Apple CoreGraphics.  The dictionaries are Foundation dictionaries. */
#include "Testing.h"

#include <Foundation/NSDictionary.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSString.h>

#include <CoreGraphics/CGGeometry.h>

int main(void)
{
  START_SET("CGGeometry point dictionary")

  NSDictionary *pd = (NSDictionary *)
    CGPointCreateDictionaryRepresentation(CGPointMake(3, 4));
  PASS(pd != nil, "a point dictionary is created");
  PASS([[pd objectForKey: @"X"] doubleValue] == 3
       && [[pd objectForKey: @"Y"] doubleValue] == 4,
       "the point dictionary uses X and Y keys");

  CGPoint p;
  PASS(CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)pd, &p)
       && p.x == 3 && p.y == 4,
       "the point round-trips");

  END_SET("CGGeometry point dictionary")

  START_SET("CGGeometry size dictionary")

  NSDictionary *sd = (NSDictionary *)
    CGSizeCreateDictionaryRepresentation(CGSizeMake(5, 6));
  PASS([[sd objectForKey: @"Width"] doubleValue] == 5
       && [[sd objectForKey: @"Height"] doubleValue] == 6,
       "the size dictionary uses Width and Height keys");

  CGSize s;
  PASS(CGSizeMakeWithDictionaryRepresentation((CFDictionaryRef)sd, &s)
       && s.width == 5 && s.height == 6,
       "the size round-trips");

  END_SET("CGGeometry size dictionary")

  START_SET("CGGeometry rect dictionary")

  NSDictionary *rd = (NSDictionary *)
    CGRectCreateDictionaryRepresentation(CGRectMake(1, 2, 7, 8));
  PASS([[rd objectForKey: @"X"] doubleValue] == 1
       && [[rd objectForKey: @"Y"] doubleValue] == 2
       && [[rd objectForKey: @"Width"] doubleValue] == 7
       && [[rd objectForKey: @"Height"] doubleValue] == 8,
       "the rect dictionary uses X, Y, Width and Height keys");

  CGRect r;
  PASS(CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)rd, &r)
       && r.origin.x == 1 && r.origin.y == 2
       && r.size.width == 7 && r.size.height == 8,
       "the rect round-trips");

  END_SET("CGGeometry rect dictionary")

  START_SET("CGGeometry dictionary rejects bad input")

  CGPoint q;
  PASS(!CGPointMakeWithDictionaryRepresentation(
         (CFDictionaryRef)[NSDictionary dictionary], &q),
       "a dictionary missing the keys is rejected");

  END_SET("CGGeometry dictionary rejects bad input")

  return 0;
}
