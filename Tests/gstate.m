#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#else
#include <CoreGraphics/CoreGraphics.h>
#endif

#include <Foundation/Foundation.h>

// This test is intended to verify the consistency of gstate after various
// operations, as well as results of matrix operations, etc.

// It could slowly grow over time.

NSString * affineTransformRepr(CGAffineTransform at)
{
  return [NSString stringWithFormat: @"((%g %g), (%g %g), (%g %g))",
                                     at.a, at.b,
                                     at.c, at.d,
                                     at.tx, at.ty];
}

void draw(CGContextRef ctx, CGRect rect)
{
  // Test 1:
  // Setting and restoring CTM. Uses Opal-specific methods.

  NSLog(@" Test 1");
#if GNUSTEP
  {
    CGAffineTransform ctm;
    CGAffineTransform oldctm = CGContextGetCTM(ctx);

    CGContextSaveGState(ctx);
    OPContextSetIdentityCTM(ctx);
    ctm = CGContextGetCTM(ctx);
    if (ctm.a == 1.0 && ctm.b == 0.0 &&
        ctm.c == 0.0 && ctm.d == 1.0 &&
        ctm.tx  == 0.0 && ctm.ty  == 0.0)
      {
        NSLog(@"+ Setting identity CTM ok");
      }
    else
      {
        NSLog(@"- Setting identity CTM failed - is %@", affineTransformRepr(ctm));
      }

    if (CGAffineTransformEqualToTransform(ctm, CGAffineTransformIdentity))
      {
        NSLog(@"+ CTM is CGAffineTransformIdentity");
      }
    else
      {
        NSLog(@"- CTM differs from CGAffineTransformIdentity - is %@", affineTransformRepr(ctm));
      }

    CGAffineTransform matrix1 = {
      .a = 1.0, .b = 0.0,
      .c = 0.0, .d = 1.0,
      .tx  = 2.0, .ty  = 3.0
    };
    CGContextConcatCTM(ctx, matrix1);
    ctm = CGContextGetCTM(ctx);
    if (CGAffineTransformEqualToTransform(ctm, matrix1))
      {
        NSLog(@"+ Concatenating matrix1 ok");
      }
    else
      {
        NSLog(@"- Concatenating matrix1 failed - expected %@, got %@", affineTransformRepr(matrix1), affineTransformRepr(ctm));
      }
    
    CGAffineTransform matrix2 = {
      .a = 2.0, .b = 0.0,
      .c = 0.0, .d = 2.0,
      .tx  = 2.0, .ty  = 3.0
    };
    OPContextSetIdentityCTM(ctx);
    CGContextConcatCTM(ctx, matrix2);
    ctm = CGContextGetCTM(ctx);
    if (CGAffineTransformEqualToTransform(ctm, matrix2))
      {
        NSLog(@"+ Concatenating matrix2 ok");
      }
    else
      {
        NSLog(@"- Concatenating matrix2 failed - expected %@, got %@", affineTransformRepr(matrix2), affineTransformRepr(ctm));
      }

    CGContextRestoreGState(ctx);

    ctm = CGContextGetCTM(ctx);
    if (CGAffineTransformEqualToTransform(ctm, oldctm))
      {
        NSLog(@"+ CTM correctly restored");
      }
    else
      {
        NSLog(@"- CTM not the same as before - expected %@, got %@", affineTransformRepr(oldctm), affineTransformRepr(ctm));
      }
  }
#else
  NSLog(@"Skipped under OS X");
#endif

}
