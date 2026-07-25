/* CGAffineTransform construction, composition, inversion and application.
   Expected values checked against Apple CoreGraphics on a macOS runner. */
#include "Testing.h"

#include <CoreGraphics/CGAffineTransform.h>
#include <CoreGraphics/CGGeometry.h>
#include <math.h>

static BOOL eq(CGFloat a, CGFloat b)
{
  CGFloat d = a - b;
  if (d < 0) d = -d;
  return d < 1e-4;
}

static BOOL teq(CGAffineTransform t, CGFloat a, CGFloat b, CGFloat c,
                CGFloat d, CGFloat tx, CGFloat ty)
{
  return eq(t.a, a) && eq(t.b, b) && eq(t.c, c) && eq(t.d, d)
      && eq(t.tx, tx) && eq(t.ty, ty);
}

int main(void)
{
  START_SET("CGAffineTransform")

  CGFloat cs = cos(M_PI / 6);
  CGFloat sn = sin(M_PI / 6);

  PASS(teq(CGAffineTransformIdentity, 1, 0, 0, 1, 0, 0),
       "the identity transform is [1 0 0 1 0 0]");
  PASS(teq(CGAffineTransformMakeTranslation(5, 7), 1, 0, 0, 1, 5, 7),
       "translation puts the offset in tx/ty");
  PASS(teq(CGAffineTransformMakeScale(2, 3), 2, 0, 0, 3, 0, 0),
       "scale puts the factors on the diagonal");
  PASS(teq(CGAffineTransformMakeRotation(M_PI / 6), cs, sn, -sn, cs, 0, 0),
       "rotation is [cos sin -sin cos] counter-clockwise");

  /* Concat(t1, t2) applies t1 first, then t2. */
  CGAffineTransform t1 = CGAffineTransformMakeTranslation(10, 0);
  CGAffineTransform t2 = CGAffineTransformMakeScale(2, 2);
  PASS(teq(CGAffineTransformConcat(t1, t2), 2, 0, 0, 2, 20, 0),
       "Concat(translate,scale) scales the earlier translation");
  PASS(teq(CGAffineTransformConcat(t2, t1), 2, 0, 0, 2, 10, 0),
       "Concat(scale,translate) leaves the later translation unscaled");

  /* Builder helpers prepend their operation to the given transform. */
  CGAffineTransform tr = CGAffineTransformMakeTranslation(5, 7);
  CGAffineTransform sc = CGAffineTransformMakeScale(2, 3);
  PASS(teq(CGAffineTransformScale(tr, 2, 3), 2, 0, 0, 3, 5, 7),
       "Scale(translate,2,3) keeps the translation");
  PASS(teq(CGAffineTransformTranslate(sc, 5, 7), 2, 0, 0, 3, 10, 21),
       "Translate(scale,5,7) scales the added translation");
  PASS(teq(CGAffineTransformRotate(tr, M_PI / 6), cs, sn, -sn, cs, 5, 7),
       "Rotate(translate,pi/6) keeps the translation");

  PASS(teq(CGAffineTransformInvert(CGAffineTransformMakeScale(2, 4)),
           0.5, 0, 0, 0.25, 0, 0),
       "inverting a scale reciprocates the factors");
  PASS(teq(CGAffineTransformInvert(tr), 1, 0, 0, 1, -5, -7),
       "inverting a translation negates the offset");

  /* Application to point, size and rect. */
  CGPoint p = CGPointApplyAffineTransform(CGPointMake(1, 1),
    CGAffineTransformConcat(t1, t2));
  PASS(eq(p.x, 22) && eq(p.y, 2),
       "applying Concat(translate,scale) to a point translates then scales");

  CGSize s = CGSizeApplyAffineTransform(CGSizeMake(4, 5), sc);
  PASS(eq(s.width, 8) && eq(s.height, 15),
       "applying a scale to a size ignores translation");

  CGRect r = CGRectApplyAffineTransform(CGRectMake(1, 2, 3, 4),
    CGAffineTransformMakeRotation(M_PI / 6));
  PASS(eq(r.origin.x, -2.13397) && eq(r.origin.y, 2.23205)
       && eq(r.size.width, 4.59808) && eq(r.size.height, 4.9641),
       "applying a rotation to a rect returns the bounding box");

  PASS(CGAffineTransformIsIdentity(CGAffineTransformIdentity),
       "the identity transform reports itself as the identity");
  testHopeful = YES;
  PASS(!CGAffineTransformIsIdentity(sc),
       "a scale is not the identity");
  testHopeful = NO;
  PASS(CGAffineTransformEqualToTransform(sc, CGAffineTransformMakeScale(2, 3)),
       "equal transforms compare equal");
  PASS(!CGAffineTransformEqualToTransform(sc, tr),
       "different transforms compare unequal");

  END_SET("CGAffineTransform")
  return 0;
}
