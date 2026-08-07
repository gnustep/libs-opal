/* CGGeometry rect algebra: accessors, standardize, intersection, union,
   inset, offset, integral, divide, the predicates, and the null/empty/
   infinite rects.  Expected values checked against Apple CoreGraphics. */
#include "Testing.h"

#include <CoreGraphics/CGGeometry.h>
#include <math.h>

static BOOL eq(CGFloat a, CGFloat b)
{
  CGFloat d = a - b;
  if (d < 0) d = -d;
  return d < 1e-4;
}

static BOOL req(CGRect r, CGFloat x, CGFloat y, CGFloat w, CGFloat h)
{
  return eq(r.origin.x, x) && eq(r.origin.y, y)
      && eq(r.size.width, w) && eq(r.size.height, h);
}

int main(void)
{
  CGRect a = CGRectMake(0, 0, 10, 10);
  CGRect b = CGRectMake(5, 5, 10, 10);
  CGRect disjoint = CGRectMake(100, 100, 5, 5);
  CGRect neg = CGRectMake(10, 10, -4, -6);
  CGRect slice, rem;

  START_SET("CGGeometry")

  PASS(eq(CGRectGetMinX(a), 0) && eq(CGRectGetMidX(a), 5)
       && eq(CGRectGetMaxX(a), 10) && eq(CGRectGetWidth(a), 10)
       && eq(CGRectGetHeight(a), 10),
       "the edge accessors report the rect bounds");
  testHopeful = YES;
  PASS(eq(CGRectGetMinX(neg), 6) && eq(CGRectGetMaxX(neg), 10)
       && eq(CGRectGetWidth(neg), 4),
       "the accessors standardize a rect with negative size");
  testHopeful = NO;
  PASS(req(CGRectStandardize(neg), 6, 4, 4, 6),
       "standardizing moves the origin and makes the size positive");

  PASS(req(CGRectIntersection(a, b), 5, 5, 5, 5),
       "intersection returns the overlapping rect");
  PASS(CGRectIsNull(CGRectIntersection(a, disjoint)),
       "intersection of disjoint rects is the null rect");
  PASS(req(CGRectUnion(a, b), 0, 0, 15, 15),
       "union returns the enclosing rect");
  PASS(req(CGRectUnion(a, CGRectNull), 0, 0, 10, 10),
       "union with the null rect returns the other rect");

  PASS(req(CGRectInset(a, 2, 3), 2, 3, 6, 4),
       "a positive inset shrinks the rect");
  PASS(req(CGRectInset(a, -2, -3), -2, -3, 14, 16),
       "a negative inset grows the rect");
  testHopeful = YES;
  PASS(CGRectIsNull(CGRectInset(a, 6, 6)),
       "an inset larger than half the rect is the null rect");
  testHopeful = NO;
  PASS(req(CGRectOffset(a, 3, 4), 3, 4, 10, 10),
       "offset translates the origin and keeps the size");
  PASS(req(CGRectIntegral(CGRectMake(1.2, 2.7, 3.3, 4.6)), 1, 2, 4, 6),
       "integral expands to the enclosing integral rect");

  CGRectDivide(a, &slice, &rem, 3, CGRectMinXEdge);
  PASS(req(slice, 0, 0, 3, 10) && req(rem, 3, 0, 7, 10),
       "divide splits the rect at the given edge distance");

  testHopeful = YES;
  PASS(CGRectContainsPoint(a, CGPointMake(5, 5))
       && CGRectContainsPoint(a, CGPointMake(0, 0))
       && !CGRectContainsPoint(a, CGPointMake(10, 10)),
       "a rect contains its min edge but not its max edge");
  testHopeful = NO;
  PASS(CGRectContainsRect(a, CGRectMake(2, 2, 3, 3))
       && !CGRectContainsRect(a, b),
       "containsRect is true only for a fully enclosed rect");
  PASS(CGRectIntersectsRect(a, b) && !CGRectIntersectsRect(a, disjoint),
       "intersectsRect reports whether two rects overlap");
  PASS(CGRectEqualToRect(a, a) && !CGRectEqualToRect(a, b),
       "equalToRect compares the rects");

  PASS(CGRectIsNull(CGRectNull) && CGRectIsEmpty(CGRectNull)
       && !CGRectIsInfinite(CGRectNull),
       "the null rect is null and empty but not infinite");
  PASS(!CGRectIsNull(CGRectZero) && CGRectIsEmpty(CGRectZero),
       "the zero rect is empty but not null");
  PASS(CGRectIsInfinite(CGRectInfinite) && !CGRectIsEmpty(CGRectInfinite)
       && !CGRectIsNull(CGRectInfinite),
       "the infinite rect is infinite and neither empty nor null");
  PASS(CGRectIsEmpty(CGRectMake(0, 0, 0, 5)),
       "a rect with zero width is empty");

  END_SET("CGGeometry")
  return 0;
}
