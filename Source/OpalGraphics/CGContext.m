/** <title>CGContext</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

   Author: BALATON Zoltan <balaton@eik.bme.hu>
   Date: 2006

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


#include "CoreGraphics/CGGeometry.h"

#include <math.h>
#include <cairo.h>

#import "CGContext-private.h"
#import "CGGradient-private.h"
#import "CGColor-private.h"
#import "cairo/CairoFont.h"
#import "OPLogging.h"

/* The default (opaque black) color in a Cairo context,
 * used if no other color is set on the context yet */
static cairo_pattern_t *default_cp;

extern cairo_surface_t *opal_CGImageGetSurfaceForImage(CGImageRef img, cairo_surface_t *contextSurface);
extern CGRect opal_CGImageGetSourceRect(CGImageRef image);

static inline void set_color(cairo_pattern_t **cp, CGColorRef clr, double alpha);
static void start_shadow(CGContextRef ctx);
static void end_shadow(CGContextRef ctx, CGRect bounds);


@implementation CGContext

- (id) initWithSurface: (cairo_surface_t *)target size: (CGSize)size
{
  self = [super init];
  cairo_status_t cret;

  if (!self) return NULL;

  self->add = NULL;
  self->ct = cairo_create(target);
  cret = cairo_status(self->ct);
  if (cret) {
    NSLog(@"cairo_create status: %s",
           cairo_status_to_string(cret));
    [self release];
    return NULL;
  }

  self->add = calloc(1, sizeof(struct ct_additions));
  if (!self->add) {
    NSLog(@"calloc failed");
    [self release];
    return NULL;
  }
  self->add->alpha = 1;
  self->add->font_size = 0;
  
  if (!default_cp) {
    default_cp = cairo_get_source(self->ct);
    cairo_pattern_reference(default_cp);
  }

  /* Cairo defaults to line width 2.0 (see http://cairographics.org/FAQ) */
  cairo_set_line_width(self->ct, 1);

  /* Perform the flip transformation. Note that this is 'hidden' in 
     CGContextGetCTM() */
  cairo_scale(self->ct, 1, -1);
  cairo_translate(self->ct, 0, -size.height);

  self->txtmatrix = CGAffineTransformIdentity;
  self->scale_factor = 1;
  self->device_size = size;
  
  return self;
}

- (void) dealloc
{
  ct_additions *ctadd, *next;

  ctadd = self->add;
  while (ctadd) {
    CGColorRelease(ctadd->fill_color);
    cairo_pattern_destroy(ctadd->fill_cp);
    CGColorRelease(ctadd->stroke_color);
    cairo_pattern_destroy(ctadd->stroke_cp);
    CGColorRelease(ctadd->shadow_color);
    cairo_pattern_destroy(ctadd->shadow_cp);
    CGFontRelease(ctadd->font);
    next = ctadd->next;
    free(ctadd);
    ctadd = next;
  }

  cairo_destroy(self->ct);
  
  [super dealloc];
}

- (void) setSize: (CGSize) size
{
  cairo_matrix_t oldCTM;
  cairo_get_matrix(self->ct, &oldCTM);
  
  cairo_matrix_t oldFlipInverse;
  cairo_matrix_init_scale(&oldFlipInverse, 1, -1);
  cairo_matrix_translate(&oldFlipInverse, 0, -self->device_size.height);
  cairo_matrix_invert(&oldFlipInverse);

  cairo_matrix_t oldCTMWithoutFlip;
  cairo_matrix_multiply(&oldCTMWithoutFlip, &oldFlipInverse, &oldCTM);

  cairo_matrix_t newCTM;
  cairo_matrix_init_scale(&newCTM, 1, -1);
  cairo_matrix_translate(&newCTM, 0, -size.height);
  cairo_matrix_multiply(&newCTM, &newCTM, &oldCTMWithoutFlip);

  self->device_size = size;
  cairo_set_matrix(self->ct, &newCTM);
}

- (void) flushSurface
{
}

@end

CGContextRef opal_new_CGContext(cairo_surface_t *target, CGSize device_size)
{
  CGContext *ctx = [[CGContext alloc] initWithSurface: target size: device_size];
  return ctx;
}

void OPContextSetSize(CGContextRef ctx, CGSize size)
{
  OPLOGCALL("ctx /*%p*/, CGSizeMake(%g,%g)", ctx, size.width, size.height);
  [ctx setSize: size];
  OPRESTORELOGGING()
}

CFTypeID CGContextGetTypeID()
{
  return (CFTypeID)[CGContext class];
}

CGContextRef CGContextRetain(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  OPRESTORELOGGING()
  return [ctx retain];
}

void CGContextRelease(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  [ctx release];
  OPRESTORELOGGING()
}

void CGContextFlush(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  cairo_surface_t *target;

  target = cairo_get_target(ctx->ct);
  /* FIXME: This doesn't work for most Cairo backends (including Xlib) */
  /* cairo_surface_flush(target); */
  /* So now we have to do it directly instead */
  [ctx flushSurface];
  OPRESTORELOGGING()
}

void CGContextSynchronize(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  /* FIXME: Could do cairo_surface_mark_dirty here, but that does nothing */
  /* NOP */
  OPRESTORELOGGING()
}

void CGContextBeginPage(CGContextRef ctx, const CGRect *mediaBox)
{
  OPLOGCALL("ctx /*%p*/, CGRectMake(%g,%g,%g,%g)", ctx, mediaBox->origin.x, 
    mediaBox->origin.y, mediaBox->size.width, mediaBox->size.height)
  /* FIXME: should we reset gstate?, mediaBox is ignored */
  cairo_copy_page(ctx->ct);
  OPRESTORELOGGING()
}

void CGContextEndPage(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  cairo_show_page(ctx->ct);
  OPRESTORELOGGING()
}

void CGContextScaleCTM(CGContextRef ctx, CGFloat sx, CGFloat sy)
{
  OPLOGCALL("ctx /*%p*/, %g, %g", ctx, sx, sy)
  cairo_scale(ctx->ct, sx, sy);
  OPRESTORELOGGING()
}

void CGContextTranslateCTM(CGContextRef ctx, CGFloat tx, CGFloat ty)
{
  OPLOGCALL("ctx /*%p*/, %g, %g", ctx, tx, ty)
  cairo_translate(ctx->ct, tx, ty);
  OPRESTORELOGGING()
}

void CGContextRotateCTM(CGContextRef ctx, CGFloat angle)
{
  OPLOGCALL("ctx /*%p*/, %g", ctx, angle)
  cairo_rotate(ctx->ct, angle);
  OPRESTORELOGGING()
}

void CGContextConcatCTM(CGContextRef ctx, CGAffineTransform transform)
{
  OPLOGCALL("ctx /*%p*/, CGAffineTransformMake(%g, %g, %g, %g, %g, %g)", ctx, transform.a,
    transform.b, transform.c, transform.d, transform.tx, transform.ty)
  cairo_matrix_t cmat;

  cmat.xx = transform.a;
  cmat.xy = transform.b;
  cmat.yx = transform.c;
  cmat.yy = transform.d;
  cmat.x0 = transform.tx;
  cmat.y0 = transform.ty;

  cairo_transform(ctx->ct, &cmat);
  OPRESTORELOGGING()
}

/**
 * Resets the current transformation matrix to what applications consider
 * the identity transform. It, however, also includes the context flip.
 */

void OPContextSetIdentityCTM(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  cairo_identity_matrix(ctx->ct);

  cairo_scale(ctx->ct, 1, -1);
  cairo_translate(ctx->ct, 0, -ctx->device_size.height);
  OPRESTORELOGGING()
}

/**
 * Returns the current transformation matrix. Note: this include the scale
 * factor but not the flip transformation.
 */
CGAffineTransform CGContextGetCTM(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)

  cairo_matrix_t cairoMatrix;
  cairo_get_matrix(ctx->ct, &cairoMatrix);

  cairo_matrix_t undoFlip;  
  cairo_matrix_init_identity(&undoFlip);
  cairo_matrix_scale(&undoFlip, 1, -1);
  cairo_matrix_translate(&undoFlip, 0, -ctx->device_size.height);
  
  cairo_matrix_t result;
  cairo_matrix_multiply(&result, &cairoMatrix, &undoFlip);

  OPRESTORELOGGING()
  return CGAffineTransformMake(result.xx, result.yx, result.xy, result.yy, result.x0, result.y0);
}

void OPContextSetCairoDeviceOffset(CGContextRef ctx, CGFloat x, CGFloat y)
{
  OPLOGCALL("ctx /*%p*/, %g, %g", ctx, x, y)
  if(ctx && ctx->ct)
    cairo_surface_set_device_offset(cairo_get_target(ctx->ct), x, y);
  OPRESTORELOGGING()
}

void CGContextSaveGState(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  ct_additions *ctadd;
  cairo_status_t cret;

  if (!ctx)
    {
      NSLog(@"%s: ctx == NULL", __PRETTY_FUNCTION__);
      OPRESTORELOGGING();
      return;
    }

  ctadd = calloc(1, sizeof(struct ct_additions));
  if (!ctadd) {
    NSLog(@"%s(%p): calloc failed", __PRETTY_FUNCTION__, ctx);
    OPRESTORELOGGING()
    return;
  }

  cairo_save(ctx->ct);
  cret = cairo_status(ctx->ct);
  if (cret) {
    NSLog(@"cairo_save status: %s",
          cairo_status_to_string(cret));
    free(ctadd);
    OPRESTORELOGGING()
    return;
  }

  *ctadd = *ctx->add;
  CGColorRetain(ctadd->fill_color);
  cairo_pattern_reference(ctadd->fill_cp);
  CGColorRetain(ctadd->stroke_color);
  cairo_pattern_reference(ctadd->stroke_cp);
  ctadd->next = ctx->add;
  ctx->add = ctadd;
  OPRESTORELOGGING()
}

void CGContextRestoreGState(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  OPRESTORELOGGING()
  ct_additions *ctadd;
  
  if (!ctx)
    {
      NSLog(@"%s: ctx == NULL", __PRETTY_FUNCTION__);
      OPRESTORELOGGING();
      return;
    }

  if (!ctx->add) return;

  CGColorRelease(ctx->add->fill_color);
  cairo_pattern_destroy(ctx->add->fill_cp);
  CGColorRelease(ctx->add->stroke_color);
  cairo_pattern_destroy(ctx->add->stroke_cp);
  ctadd = ctx->add->next;
  free(ctx->add);
  ctx->add = ctadd;

  if(!ctx->add)
    {
      NSLog(@"%s(%p): restoring produced null 'ct_additions'", __FUNCTION__, ctx);
    }

  cairo_restore(ctx->ct);
}

void CGContextSetShouldAntialias(CGContextRef ctx, int shouldAntialias)
{
  OPLOGCALL("ctx /*%p*/, %d", ctx, shouldAntialias)
  cairo_set_antialias(ctx->ct,
    (shouldAntialias ? CAIRO_ANTIALIAS_DEFAULT : CAIRO_ANTIALIAS_NONE));
  OPRESTORELOGGING()
}

void CGContextSetLineWidth(CGContextRef ctx, CGFloat width)
{
  OPLOGCALL("ctx /*%p*/, %g", ctx, width)
  cairo_set_line_width(ctx->ct, width);
  OPRESTORELOGGING()
}

void CGContextSetLineJoin(CGContextRef ctx, CGLineJoin join)
{
  OPLOGCALL("ctx /*%p*/, %d", ctx, join)
  cairo_set_line_join(ctx->ct, join);
  OPRESTORELOGGING()
}

void CGContextSetMiterLimit(CGContextRef ctx, CGFloat limit)
{
  OPLOGCALL("ctx /*%p*/, %g", ctx, limit)
  cairo_set_miter_limit(ctx->ct, limit);
  OPRESTORELOGGING()
}

void CGContextSetLineCap(CGContextRef ctx, CGLineCap cap)
{
  OPLOGCALL("ctx /*%p*/, %d", ctx, cap)
  cairo_set_line_cap(ctx->ct, cap);
  OPRESTORELOGGING()
}

void CGContextSetLineDash(
  CGContextRef ctx,
  CGFloat phase,
  const CGFloat lengths[],
  size_t count)
{
  OPLOGCALL("ctx /*%p*/, %g, <lengths>, %d", ctx, phase, count)
  if (!lengths && count != 0)
    {
      NSLog(@"%s: null 'lengths' passed with count %d. Fixing by setting count to 0.", lengths, (int)count);
      count = 0;
    }

  double dashes[count]; /* C99 allows this */
  size_t i;

  for (i=0; i<count; i++)
    {
      dashes[i] = lengths[i];
    }

  cairo_set_dash(ctx->ct, dashes, count, phase);
  OPRESTORELOGGING()
}

void CGContextSetFlatness(CGContextRef ctx, CGFloat flatness)
{
  OPLOGCALL("ctx /*%p*/, %g", ctx, flatness)
  cairo_set_tolerance(ctx->ct, flatness / 2);
  OPRESTORELOGGING()
}

CGInterpolationQuality CGContextGetInterpolationQuality(CGContextRef ctx)
{
  return 0;
}

void CGContextSetInterpolationQuality(
  CGContextRef ctx,
  CGInterpolationQuality quality)
{
  OPLOGCALL("ctx /*%p*/, %d", ctx, quality)
  OPRESTORELOGGING()
}

void CGContextSetPatternPhase (CGContextRef ctx, CGSize phase)
{
  OPLOGCALL("ctx /*%p*/, CGSizeMake(%g, %g)", ctx, phase.width, phase.height)
  OPRESTORELOGGING()
}

void CGContextSetFillPattern(
  CGContextRef ctx,
  CGPatternRef pattern,
  const CGFloat components[])
{
  OPLOGCALL("ctx /*%p*/, <pattern>, <components>", ctx)
  OPRESTORELOGGING()
}

void CGContextSetStrokePattern(
  CGContextRef ctx,
  CGPatternRef pattern,
  const CGFloat components[])
{
  OPLOGCALL("ctx /*%p*/, <pattern>, <components>", ctx)
  OPRESTORELOGGING()
}

void CGContextSetShouldSmoothFonts(CGContextRef ctx, int shouldSmoothFonts)
{
  OPLOGCALL("ctx /*%p*/, %d", ctx, shouldSmoothFonts)
  OPRESTORELOGGING()
}

void CGContextSetAllowsFontSmoothing(CGContextRef ctx, bool allowsFontSmoothing)
{
  OPLOGCALL("ctx /*%p*/, %s", ctx, allowsFontSmoothing ? "true" : "false")
  OPRESTORELOGGING()
}

void CGContextSetBlendMode(CGContextRef ctx, CGBlendMode mode)
{
  OPLOGCALL("ctx /*%p*/, %d", ctx, mode)
  OPRESTORELOGGING()
}

void CGContextSetAllowsAntialiasing(CGContextRef ctx, int allowsAntialiasing)
{
  OPLOGCALL("ctx /*%p*/, %d", ctx, allowsAntialiasing)
  OPRESTORELOGGING()
}

void CGContextSetShouldSubpixelPositionFonts(
  CGContextRef ctx,
  bool shouldSubpixelPositionFonts)
{
  OPLOGCALL("ctx /*%p*/, %s", ctx, shouldSubpixelPositionFonts ? "true" : "false")
  OPRESTORELOGGING()
}

void CGContextSetAllowsFontSubpixelPositioning(
  CGContextRef ctx,
  bool allowsFontSubpixelPositioning)
{
  OPLOGCALL("ctx /*%p*/, %s", ctx, allowsFontSubpixelPositioning ? "true" : "false")
  OPRESTORELOGGING()
}

void CGContextSetShouldSubpixelQuantizeFonts(
  CGContextRef ctx,
  bool shouldSubpixelQuantizeFonts)
{
  OPLOGCALL("ctx /*%p*/, %s", ctx, shouldSubpixelQuantizeFonts ? "true" : "false")
  OPRESTORELOGGING()
}     
 
void CGContextSetAllowsFontSubpixelQuantization(
  CGContextRef ctx,
  bool allowsFontSubpixelQuantization)
{
  OPLOGCALL("ctx /*%p*/, %s", ctx, allowsFontSubpixelQuantization ? "true" : "false")
  OPRESTORELOGGING()
}

void CGContextSetShadow(
  CGContextRef ctx,
  CGSize offset,
  CGFloat radius)
{  
  OPLOGCALL("ctx /*%p*/, CGSizeMake(%g, %g), %g", ctx, offset.width, offset.height,
            radius)
  CGColorRef defaultShadowColor = CGColorCreateGenericGray(0, 0.3);
  CGContextSetShadowWithColor(ctx, offset, radius, defaultShadowColor);
  CGColorRelease(defaultShadowColor);
  OPRESTORELOGGING()
}

void CGContextSetShadowWithColor(
  CGContextRef ctx,
  CGSize offset,
  CGFloat radius,
  CGColorRef color)
{
  OPLOGCALL("ctx /*%p*/, CGSizeMake(%g, %g), %g, <color>", ctx, offset.width, offset.height,
            radius)
  CGColorRelease(ctx->add->shadow_color);
  ctx->add->shadow_color = color;
  CGColorRetain(color);
  
  ctx->add->shadow_offset = offset;
  ctx->add->shadow_radius = radius;
  set_color(&ctx->add->shadow_cp, color, 1.0);
  OPRESTORELOGGING()
}

void CGContextBeginPath(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  cairo_new_path(ctx->ct);
  OPRESTORELOGGING()
}

void CGContextClosePath(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  cairo_close_path(ctx->ct);
  OPRESTORELOGGING()
}

void CGContextMoveToPoint(CGContextRef ctx, CGFloat x, CGFloat y)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  cairo_move_to(ctx->ct, x, y);
  OPRESTORELOGGING()
}

void CGContextAddLineToPoint(CGContextRef ctx, CGFloat x, CGFloat y)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  cairo_line_to(ctx->ct, x, y);
  OPRESTORELOGGING()
}

void CGContextAddLines(CGContextRef ctx, const CGPoint points[], size_t count)
{
  OPLOGCALL("ctx /*%p*/, <points>, %d", ctx, count)
  size_t i;

  if (count <= 0) return;
  CGContextMoveToPoint(ctx, points[0].x, points[0].y);
  for (i=1; i<count; i++)
    CGContextAddLineToPoint(ctx, points[i].x, points[i].y);
  OPRESTORELOGGING()
}

void CGContextAddCurveToPoint(
  CGContextRef ctx,
  CGFloat cp1x,
  CGFloat cp1y,
  CGFloat cp2x,
  CGFloat cp2y,
  CGFloat x,
  CGFloat y)
{
  OPLOGCALL("ctx /*%p*/, %g, %g, %g, %g, %g, %g", ctx, cp1x, cp1y, cp2x, cp2y, x, y)
  cairo_curve_to(ctx->ct, cp1x, cp1y, cp2x, cp2y, x, y);
  OPRESTORELOGGING()
}

void CGContextAddQuadCurveToPoint(
  CGContextRef ctx,
  CGFloat cpx,
  CGFloat cpy,
  CGFloat x,
  CGFloat y)
{
  OPLOGCALL("ctx /*%p*/, %g, %g, %g, %g", ctx, cpx, cpy, x, y)
  CGPoint curr = CGContextGetPathCurrentPoint(ctx);
  CGContextAddCurveToPoint(ctx, (curr.x/3.0) + (2.0*cpx/3.0), (curr.y/3.0) + (2.0*cpy/3.0),
                                (2.0*cpx/3.0) + (x/3.0), (2.0*cpy/3.0) + (y/3.0),
                                x, y);
  OPRESTORELOGGING()
}

void CGContextAddRect(CGContextRef ctx, CGRect rect)
{
  OPLOGCALL("ctx /*%p*/, CGRectMake(%g, %g, %g, %g)", ctx, rect.origin.x, rect.origin.y,
            rect.size.width, rect.size.height)
  cairo_rectangle(ctx->ct, rect.origin.x, rect.origin.y,
                  rect.size.width, rect.size.height);
  OPRESTORELOGGING()
}

void CGContextAddRects(CGContextRef ctx, const CGRect rects[], size_t count)
{
  OPLOGCALL("ctx /*%p*/, <rects>, %d", ctx, count)
  size_t i;

  for (i=0; i<count; i++)
    CGContextAddRect(ctx, rects[i]);
  OPRESTORELOGGING()
}

void CGContextAddArc(
  CGContextRef ctx,
  CGFloat x,
  CGFloat y,
  CGFloat radius,
  CGFloat startAngle,
  CGFloat endAngle,
  int clockwise)
{
  OPLOGCALL("ctx /*%p*/, %g, %g, %g, %g, %g, %d", ctx, x, y, radius, startAngle, endAngle,
            clockwise)
  if (clockwise)
    cairo_arc_negative(ctx->ct, x, y, radius, startAngle, endAngle);
  else
    cairo_arc(ctx->ct, x, y, radius, startAngle, endAngle);
  OPRESTORELOGGING()
}

void CGContextAddArcToPoint(
  CGContextRef ctx,
  CGFloat x1,
  CGFloat y1,
  CGFloat x2,
  CGFloat y2,
  CGFloat radius)
{
  OPLOGCALL("ctx /*%p*/, %g, %g, %g, %g, %g", ctx, x1, y1, x2, y2, radius)
  double x0, y0;
  double dx0, dy0, dx2, dy2, xl0, xl2;
  double san, n0x, n0y, n2x, n2y, t;

  cairo_get_current_point(ctx->ct, &x0, &y0);
  dx0 = x0 - x1;
  dy0 = y0 - y1;
  xl0 = sqrt(dx0*dx0 + dy0*dy0);
  if (xl0 == 0)
    {
      OPRESTORELOGGING()
      return;
    }

  dx2 = x2 - x1;
  dy2 = y2 - y1;
  xl2 = sqrt(dx2*dx2 + dy2*dy2);

  san = dx2*dy0 - dx0*dy2;
  if (san == 0) {
    CGContextAddLineToPoint(ctx, x1, y1);
    OPRESTORELOGGING()
    return;
  }

  if (san < 0) {
    n0x = -dy0 / xl0;
    n0y = dx0 / xl0;
    n2x = dy2 / xl2;
    n2y = -dx2 / xl2;
  } else {
    n0x = dy0 / xl0;
    n0y = -dx0 / xl0;
    n2x = -dy2 / xl2;
    n2y = dx2 / xl2;
  }
  t = (dx2*n2y - dx2*n0y - dy2*n2x + dy2*n0x) / san;
  CGContextAddArc(ctx,
    x1 + radius * (t * dx0 + n0x), y1 + radius * (t * dy0 + n0y),
    radius, atan2(-n0y, -n0x), atan2(-n2y, -n2x), (san < 0));
  OPRESTORELOGGING()
}

bool CGContextPathContainsPoint(CGContextRef ctx,
  CGPoint point, CGPathDrawingMode mode)
{
  cairo_t *cr = ctx->ct;
  cairo_fill_rule_t cur = cairo_get_fill_rule(cr);
  
  bool evenOdd = mode == kCGPathEOFill || mode == kCGPathEOFillStroke;
  cairo_set_fill_rule(cr, evenOdd ? CAIRO_FILL_RULE_EVEN_ODD : CAIRO_FILL_RULE_WINDING);
  
  bool contains = cairo_in_fill(cr, point.x, point.y);
  cairo_set_fill_rule(cr, cur);

  return contains;
}

static void OPAddPathApplier(void *info, const CGPathElement *elem)
{
  CGContextRef ctx = (CGContextRef)info;
  switch (elem->type)
  {
    case kCGPathElementMoveToPoint:
      CGContextMoveToPoint(ctx, elem->points[0].x, elem->points[0].y);
      break;
    case kCGPathElementAddLineToPoint:
      CGContextAddLineToPoint(ctx, elem->points[0].x, elem->points[0].y);
      break;
    case kCGPathElementAddQuadCurveToPoint:
      CGContextAddQuadCurveToPoint(ctx, elem->points[0].x, elem->points[0].y,
                                        elem->points[1].x, elem->points[1].y);
      break;
    case kCGPathElementAddCurveToPoint:
      CGContextAddCurveToPoint(ctx, elem->points[0].x, elem->points[0].y,
                                    elem->points[1].x, elem->points[1].y,
                                    elem->points[2].x, elem->points[2].y);
      break;
    case kCGPathElementCloseSubpath:
      CGContextClosePath(ctx);
      break;
    default:
      break;
  }    
}

void CGContextAddPath(CGContextRef ctx, CGPathRef path)
{
  OPLOGCALL("ctx /*%p*/, <path>", ctx)
  CGPathApply(path, ctx, OPAddPathApplier);
  OPRESTORELOGGING()
}

void CGContextAddEllipseInRect(CGContextRef ctx, CGRect rect)
{
  OPLOGCALL("ctx /*%p*/, CGRectMake(%g, %g, %g, %g)", ctx, rect.origin.x, rect.origin.y,
            rect.size.width, rect.size.height)
  OPRESTORELOGGING()
}

void CGContextReplacePathWithStrokedPath(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  OPRESTORELOGGING()
}

void CGContextStrokePath(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  cairo_status_t cret;

  if (ctx->add->shadow_cp) {
    start_shadow(ctx);
  }

  if(ctx->add->stroke_cp)
    cairo_set_source(ctx->ct, ctx->add->stroke_cp);
  else
    cairo_set_source(ctx->ct, default_cp);

  cairo_stroke(ctx->ct);
  
  if (ctx->add->shadow_cp) {
    end_shadow(ctx, CGRectMake(0,0,500,500)); //FIXME
  }
  
  cret = cairo_status(ctx->ct);
  if (cret)
    NSLog(@"cairo_stroke status: %s",
          cairo_status_to_string(cret));
  OPRESTORELOGGING()
}

static void fill_path(CGContextRef ctx, int eorule, int preserve)
{
  cairo_status_t cret;
  
  if(!ctx || !ctx->add)
    {
      NSLog(@"null %s%s%s in %s",
            !ctx ? "ctx" : "",
            (!ctx && !ctx->add) ? " and " : "", 
            !ctx->add ? "ctx->add" : "",
            __PRETTY_FUNCTION__);
      return;
    }

  if (ctx->add->shadow_cp) {
    start_shadow(ctx);
  }
  if (ctx->add->fill_cp)
    cairo_set_source(ctx->ct, ctx->add->fill_cp);
  else
    cairo_set_source(ctx->ct, default_cp);
  if (eorule)
    cairo_set_fill_rule(ctx->ct, CAIRO_FILL_RULE_EVEN_ODD);
  else
    cairo_set_fill_rule(ctx->ct, CAIRO_FILL_RULE_WINDING);

  cairo_fill_preserve(ctx->ct);

  if (!preserve) cairo_new_path(ctx->ct);
  
  if (ctx->add->shadow_cp) {
    end_shadow(ctx, CGRectMake(0,0,500,500)); //FIXME
  }
  
  cret = cairo_status(ctx->ct);
  if (cret)
    NSLog(@"cairo_fill status: %s",
          cairo_status_to_string(cret));
}

void CGContextFillPath(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  fill_path(ctx, 0, 0);
  OPRESTORELOGGING()
}

void CGContextClearPath(CGContextRef ctx)
{ //FIXME
  OPLOGCALL("ctx /*%p*/", ctx)
  cairo_status_t cret;

  if (ctx->add->fill_cp)
    cairo_set_source(ctx->ct, ctx->add->fill_cp);
  else
    cairo_set_source(ctx->ct, default_cp);
  //cairo_set_fill_rule(ctx->ct, CAIRO_FILL_RULE_WINDING);
  cairo_clip(ctx->ct);
  cairo_clip_preserve(ctx->ct);

  cret = cairo_status(ctx->ct);
  if (cret)
    NSLog(@"cairo clear status: %s",
          cairo_status_to_string(cret));
  OPRESTORELOGGING()
}

void CGContextEOFillPath(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  fill_path(ctx, 1, 0);
  OPRESTORELOGGING()
}

void CGContextDrawPath(CGContextRef ctx, CGPathDrawingMode mode)
{
  OPLOGCALL("ctx /*%p*/, %d", ctx, mode)
  switch (mode) {
    case kCGPathFill:
    case kCGPathEOFill:
      fill_path(ctx, (mode == kCGPathEOFill), 0);
      break;
    case kCGPathFillStroke:
    case kCGPathEOFillStroke:
      fill_path(ctx, (mode == kCGPathEOFillStroke), 1);
      /* fall through */
    case kCGPathStroke:
      CGContextStrokePath(ctx);
      break;
    default:
      NSLog(@"CGContextDrawPath invalid CGPathDrawingMode: %d", mode);
  }
  OPRESTORELOGGING()
}

void CGContextStrokeRect(CGContextRef ctx, CGRect rect)
{
  OPLOGCALL("ctx /*%p*/, CGRectMake(%g, %g, %g, %g)", ctx, rect.origin.x, rect.origin.y,
            rect.size.width, rect.size.height)
  CGContextBeginPath(ctx);
  CGContextAddRect(ctx, rect);
  CGContextStrokePath(ctx);
  OPRESTORELOGGING()
}

void CGContextStrokeRectWithWidth(CGContextRef ctx, CGRect rect, CGFloat width)
{
  OPLOGCALL("ctx /*%p*/, CGRectMake(%g, %g, %g, %g), %g", ctx, rect.origin.x, rect.origin.y,
            rect.size.width, rect.size.height, width)
  CGContextSetLineWidth(ctx, width);
  CGContextStrokeRect(ctx, rect);
  /* Line width is not restored (see Technical QA1045) */
  OPRESTORELOGGING()
}

void CGContextFillRect(CGContextRef ctx, CGRect rect)
{
  OPLOGCALL("ctx /*%p*/, CGRectMake(%g, %g, %g, %g)", ctx, rect.origin.x, rect.origin.y,
            rect.size.width, rect.size.height)
  CGContextBeginPath(ctx);
  CGContextAddRect(ctx, rect);
  CGContextFillPath(ctx);
  OPRESTORELOGGING()
}

void CGContextFillRects(CGContextRef ctx, const CGRect rects[], size_t count)
{
  OPLOGCALL("ctx /*%p*/, <rects>, %d", ctx, count)
  CGContextBeginPath(ctx);
  CGContextAddRects(ctx, rects, count);
  CGContextFillPath(ctx);
  OPRESTORELOGGING()
}

void CGContextClearRect(CGContextRef ctx, CGRect rect)
{
  OPLOGCALL("ctx /*%p*/, CGRectMake(%g, %g, %g, %g)", ctx, rect.origin.x, rect.origin.y,
            rect.size.width, rect.size.height)
  CGContextBeginPath(ctx);
  CGContextAddRect(ctx, rect);
  CGContextClearPath(ctx);
  OPRESTORELOGGING()
}

void CGContextStrokeLineSegments(
  CGContextRef ctx,
  const CGPoint points[],
  size_t count)
{
  OPLOGCALL("ctx /*%p*/, <points>, %d", ctx, count)
  size_t i;

  CGContextBeginPath(ctx);
  for (i=1; i<count; i+=2) {
    CGContextMoveToPoint(ctx, points[i-1].x, points[i-1].y);
    CGContextAddLineToPoint(ctx, points[i].x, points[i].y);
  }
  CGContextStrokePath(ctx);
  OPRESTORELOGGING()
}

bool CGContextIsPathEmpty(CGContextRef ctx)
{
	return 0;
}

CGPoint CGContextGetPathCurrentPoint(CGContextRef ctx)
{
  double x, y;

  cairo_get_current_point(ctx->ct, &x, &y);
  return CGPointMake(x, y);
}

CGRect CGContextGetPathBoundingBox(CGContextRef ctx)
{
  double x1, y1, x2, y2;
  cairo_path_extents(ctx->ct, &x1, &y1, &x2, &y2);
  if (x1 == 0 && y1 == 0 && x2 == 0 && y2 == 0)
  {
    return CGRectNull;
  }
  else
  {
    // FIXME: check non-negative width/height
    return CGRectMake(x1, y1, (x2-x1), (y2-y1));
  }
}

CGPathRef CGContextCopyPath(CGContextRef ctx)
{
  CGMutablePathRef path = CGPathCreateMutable();
  cairo_path_t *cairopath = cairo_copy_path(ctx->ct);
  for (int i=0; i<cairopath->num_data; i+=cairopath->data[i].header.length)
  {
    cairo_path_data_t *data = &cairopath->data[i];
    switch (data[0].header.type)
    {
      case CAIRO_PATH_MOVE_TO:
        CGPathMoveToPoint(path, NULL, data[1].point.x, data[1].point.y);
        break;
      case CAIRO_PATH_LINE_TO:
        CGPathAddLineToPoint(path, NULL, data[1].point.x, data[1].point.y);
        break;
      case CAIRO_PATH_CURVE_TO:
        CGPathAddCurveToPoint(path, NULL, data[1].point.x, data[1].point.y,
                                          data[2].point.x, data[2].point.y,
                                          data[3].point.x, data[3].point.y);
        break;
      case CAIRO_PATH_CLOSE_PATH:
        CGPathCloseSubpath(path);
        break;
    }
  }
  cairo_path_destroy(cairopath);
  return (CGPathRef)path;
}

void CGContextClip(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  cairo_clip(ctx->ct);
  OPRESTORELOGGING()
}

void CGContextEOClip(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  cairo_set_fill_rule(ctx->ct, CAIRO_FILL_RULE_EVEN_ODD);
  CGContextClip(ctx);
  cairo_set_fill_rule(ctx->ct, CAIRO_FILL_RULE_WINDING);
  OPRESTORELOGGING()
}

void CGContextClipToRect(CGContextRef ctx, CGRect rect)
{
  OPLOGCALL("ctx /*%p*/, CGRectMake(%g, %g, %g, %g)", ctx, rect.origin.x, rect.origin.y,
            rect.size.width, rect.size.height)
  CGContextBeginPath(ctx);
  CGContextAddRect(ctx, rect);
  CGContextClip(ctx);
  OPRESTORELOGGING()
}

void CGContextClipToRects(CGContextRef ctx, const CGRect rects[], size_t count)
{
  OPLOGCALL("ctx /*%p*/, <rects>, %d", ctx, count)
  CGContextBeginPath(ctx);
  CGContextAddRects(ctx, rects, count);
  CGContextClip(ctx);
  OPRESTORELOGGING()
}

void CGContextClipToMask(CGContextRef ctx, CGRect rect, CGImageRef mask)
{
  OPLOGCALL("ctx /*%p*/, CGRectMake(%g, %g, %g, %g), <mask>", ctx, 
            rect.origin.x, rect.origin.y,
            rect.size.width, rect.size.height)
  /* Attach a temporay image mask to the surface.
     Then, all drawing needs a: 
       push_group()
       do the drawing
       pop_group_to_source();
       mask()
  */
  OPRESTORELOGGING()
}

CGFloat OPContextGetAlpha(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)

  if(!ctx || !ctx->add)
    {
      NSLog(@"null %s%s%s in %s",
            !ctx ? "ctx" : "",
            (!ctx && !ctx->add) ? " and " : "", 
            !ctx->add ? "ctx->add" : "",
            __PRETTY_FUNCTION__);
      return 0;
    }

  CGFloat result = ctx->add->alpha;

  OPRESTORELOGGING()
  return result;
}

void OPContextResetClip(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  if (ctx && ctx->ct)
  {
    cairo_reset_clip(ctx->ct);
  }
  OPRESTORELOGGING()
}

CGRect CGContextGetClipBoundingBox(CGContextRef ctx)
{
  return CGRectNull;
}

static inline void set_color(cairo_pattern_t **cp, CGColorRef clr, double alpha)
{
  // FIXME: check why this might be called with a NULL clr
  if (!clr) return;
  cairo_pattern_t *newcp;
  cairo_status_t cret;

  CGColorSpaceRef srgb = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
  CGColorRef srgbClr = OPColorGetTransformedToSpace(clr, srgb, kCGRenderingIntentRelativeColorimetric);
  CGColorSpaceRelease(srgb);

  const CGFloat *cc = CGColorGetComponents(srgbClr);
  NSDebugLLog(@"Opal", @"Set color with %f %f %f %f", (float)cc[0], (float)cc[1], (float)cc[2], (float)cc[3]*alpha);
  newcp = cairo_pattern_create_rgba(cc[0], cc[1], cc[2], cc[3]*alpha);
  cret = cairo_pattern_status(newcp);
  if (cret) {
    NSLog(@" cairo_pattern_create_rgba status: %s",
          cairo_status_to_string(cret));
    return;
  }

  if (*cp != NULL)
  {
    cairo_pattern_destroy(*cp);
  }
  *cp = newcp;
}

void CGContextSetFillColorWithColor(CGContextRef ctx, CGColorRef color)
{
  OPLOGCALL("ctx /*%p*/, <color>", ctx)
  if(!ctx || !ctx->add)
    {
      NSLog(@"null %s%s%s in %s",
            !ctx ? "ctx" : "",
            (!ctx && !ctx->add) ? " and " : "", 
            !ctx->add ? "ctx->add" : "",
            __PRETTY_FUNCTION__);
      OPRESTORELOGGING()
      return;
    }
  CGColorRef old_color = ctx->add->fill_color;
  ctx->add->fill_color = color;
  CGColorRetain(color);
  CGColorRelease(old_color);
  set_color(&ctx->add->fill_cp, color, ctx->add->alpha);
  OPRESTORELOGGING()
}

void CGContextSetStrokeColorWithColor(CGContextRef ctx, CGColorRef color)
{
  OPLOGCALL("ctx /*%p*/, <color>", ctx)
  if(!ctx || !ctx->add)
    {
      NSLog(@"null %s%s%s in %s",
            !ctx ? "ctx" : "",
            (!ctx && !ctx->add) ? " and " : "", 
            !ctx->add ? "ctx->add" : "",
            __PRETTY_FUNCTION__);
      OPRESTORELOGGING()
      return;
    }
  CGColorRef old_color = ctx->add->stroke_color;
  ctx->add->stroke_color = color;
  CGColorRetain(color);
  CGColorRelease(old_color);
  set_color(&ctx->add->stroke_cp, color, ctx->add->alpha);
  OPRESTORELOGGING()
}

void CGContextSetAlpha(CGContextRef ctx, CGFloat alpha)
{
  OPLOGCALL("ctx /*%p*/, %g", ctx, alpha)
  if(!ctx || !ctx->add)
    {
      NSLog(@"null %s%s%s in %s", 
            !ctx ? "ctx" : "",
            (!ctx && !ctx->add) ? " and " : "", 
            !ctx->add ? "ctx->add" : "",
            __PRETTY_FUNCTION__);
      OPRESTORELOGGING()
      return;
    }
  if (alpha < 0)
    alpha = 0;
  else if (alpha > 1)
    alpha = 1;
  ctx->add->alpha = alpha;
  // FIXME: Should we really check that these are non-null?
  if (ctx->add->stroke_color)
    set_color(&ctx->add->stroke_cp, ctx->add->stroke_color, ctx->add->alpha);
  if (ctx->add->fill_color)  
    set_color(&ctx->add->fill_cp, ctx->add->fill_color, ctx->add->alpha);
  OPRESTORELOGGING()
}

void CGContextSetFillColorSpace(CGContextRef ctx, CGColorSpaceRef colorspace)
{
  OPLOGCALL("ctx /*%p*/, <colorspace>", ctx)
  CGFloat *components;
  CGColorRef color;
  size_t nc;

  nc = CGColorSpaceGetNumberOfComponents(colorspace);
  components = calloc(nc+1, sizeof(CGFloat));
  if (components) {
    NSLog(@"%s: calloc failed", __PRETTY_FUNCTION__);
    return;
  }
  /* Default is an opaque, zero intensity color (usually black) */
  components[nc] = 1;
  color = CGColorCreate(colorspace, components);
  free(components);
  CGContextSetFillColorWithColor(ctx, color);
  CGColorRelease(color);
  OPRESTORELOGGING()
}

void CGContextSetStrokeColorSpace(CGContextRef ctx, CGColorSpaceRef colorspace)
{
  OPLOGCALL("ctx /*%p*/, <colorspace>", ctx)
  CGFloat *components;
  CGColorRef color;
  size_t nc;

  nc = CGColorSpaceGetNumberOfComponents(colorspace);
  components = calloc(nc+1, sizeof(CGFloat));
  if (components) {
    NSLog(@"%s: calloc failed", __PRETTY_FUNCTION__);
    return;
  }
  /* Default is an opaque, zero intensity color (usually black) */
  components[nc] = 1;
  color = CGColorCreate(colorspace, components);
  free(components);
  CGContextSetStrokeColorWithColor(ctx, color);
  CGColorRelease(color);
  OPRESTORELOGGING()
}

void CGContextSetFillColor(CGContextRef ctx, const CGFloat components[])
{
  OPLOGCALL("ctx /*%p*/, <components>", ctx)
  CGColorSpaceRef cs;
  CGColorRef color;

  cs = CGColorGetColorSpace(ctx->add->fill_color);
  color = CGColorCreate(cs, components);
  CGContextSetFillColorWithColor(ctx, color);
  CGColorRelease(color);
  OPRESTORELOGGING()
}

void CGContextSetStrokeColor(CGContextRef ctx, const CGFloat components[])
{
  OPLOGCALL("ctx /*%p*/, <components>", ctx)
  CGColorSpaceRef cs;
  CGColorRef color;

  cs = CGColorGetColorSpace(ctx->add->stroke_color);
  color = CGColorCreate(cs, components);
  CGContextSetStrokeColorWithColor(ctx, color);
  CGColorRelease(color);
  OPRESTORELOGGING()
}

void CGContextSetGrayFillColor(CGContextRef ctx, CGFloat gray, CGFloat alpha)
{
  OPLOGCALL("ctx /*%p*/, %g, %g", ctx, gray, alpha)
  CGFloat comps[2];
  CGColorSpaceRef cs;
  CGColorRef color;

  comps[0] = gray;
  comps[1] = alpha;
  cs = CGColorSpaceCreateDeviceGray();
  color = CGColorCreate(cs, comps);
  CGColorSpaceRelease(cs);
  CGContextSetFillColorWithColor(ctx, color);
  CGColorRelease(color);
  OPRESTORELOGGING()
}

void CGContextSetGrayStrokeColor(CGContextRef ctx, CGFloat gray, CGFloat alpha)
{
  OPLOGCALL("ctx /*%p*/, %g, %g", ctx, gray, alpha)
  CGFloat comps[2];
  CGColorSpaceRef cs;
  CGColorRef color;

  comps[0] = gray;
  comps[1] = alpha;
  cs = CGColorSpaceCreateDeviceGray();
  color = CGColorCreate(cs, comps);
  CGColorSpaceRelease(cs);
  CGContextSetStrokeColorWithColor(ctx, color);
  CGColorRelease(color);
  OPRESTORELOGGING()
}

void CGContextSetRGBFillColor(CGContextRef ctx,
       CGFloat r, CGFloat g, CGFloat b, CGFloat alpha)
{
  OPLOGCALL("ctx /*%p*/, %g, %g, %g, %g", ctx, r, g, b, alpha)
  CGFloat comps[4];
  CGColorSpaceRef cs;
  CGColorRef color;

  comps[0] = r;
  comps[1] = g;
  comps[2] = b;
  comps[3] = alpha;
  cs = CGColorSpaceCreateDeviceRGB();
  color = CGColorCreate(cs, comps);
  CGColorSpaceRelease(cs);
  CGContextSetFillColorWithColor(ctx, color);
  CGColorRelease(color);
  OPRESTORELOGGING()
}

void CGContextSetRGBStrokeColor(CGContextRef ctx,
       CGFloat r, CGFloat g, CGFloat b, CGFloat alpha)
{
  OPLOGCALL("ctx /*%p*/, %g, %g, %g, %g", ctx, r, g, b, alpha)
  CGFloat comps[4];
  CGColorSpaceRef cs;
  CGColorRef color;

  comps[0] = r;
  comps[1] = g;
  comps[2] = b;
  comps[3] = alpha;
  cs = CGColorSpaceCreateDeviceRGB();
  color = CGColorCreate(cs, comps);
  CGColorSpaceRelease(cs);
  CGContextSetStrokeColorWithColor(ctx, color);
  CGColorRelease(color);
  OPRESTORELOGGING()
}

void CGContextSetCMYKFillColor(CGContextRef ctx,
       CGFloat cyan, CGFloat magenta, CGFloat yellow, CGFloat black, CGFloat alpha)
{
  OPLOGCALL("ctx /*%p*/, %g, %g, %g, %g, %g", ctx, cyan, magenta, yellow, black, alpha)
  CGColorRef color;

  color = CGColorCreateGenericCMYK(cyan, magenta, yellow, black, alpha);
  CGContextSetFillColorWithColor(ctx, color);
  CGColorRelease(color);
  OPRESTORELOGGING()
}

void CGContextSetCMYKStrokeColor(CGContextRef ctx,
       CGFloat cyan, CGFloat magenta, CGFloat yellow, CGFloat black, CGFloat alpha)
{
  OPLOGCALL("ctx /*%p*/, %g, %g, %g, %g, %g", ctx, cyan, magenta, yellow, black, alpha)
  CGColorRef color;

  color = CGColorCreateGenericCMYK(cyan, magenta, yellow, black, alpha);
  CGContextSetStrokeColorWithColor(ctx, color);
  CGColorRelease(color);
  OPRESTORELOGGING()
}

void opal_draw_surface_in_rect(CGContextRef ctxt, CGRect rect, cairo_surface_t *src, CGRect srcRect)
{  
  cairo_pattern_t *pattern = cairo_pattern_create_for_surface(src);
    
  cairo_matrix_t patternMatrix;
  cairo_matrix_init_identity(&patternMatrix);
  
  // Move to the place where the layer should be drawn
  cairo_matrix_translate(&patternMatrix, srcRect.origin.x, srcRect.origin.y);

  // Scale the pattern to the correct size
  cairo_matrix_scale(&patternMatrix,
    srcRect.size.width / rect.size.width,
    srcRect.size.height / rect.size.height);

  // Flip the layer up-side-down
  cairo_matrix_scale(&patternMatrix, 1, -1);
  cairo_matrix_translate(&patternMatrix, 0, -rect.size.height);

  cairo_pattern_set_matrix(pattern, &patternMatrix);
  
  // FIXME: do we always want this?
  cairo_pattern_set_extend(pattern, CAIRO_EXTEND_PAD);

  // Do the drawing

  cairo_t *destCairo = ctxt->ct;
  cairo_save(destCairo);

  cairo_set_operator(destCairo, CAIRO_OPERATOR_OVER);
  cairo_translate(destCairo, rect.origin.x, rect.origin.y);

  cairo_set_source(destCairo, pattern);
  cairo_pattern_destroy(pattern);
  
  // FIXME: What is the fastest way to draw? cairo_paint? clip? fill a rect?
  cairo_rectangle(destCairo, 0, 0,
    rect.size.width, rect.size.height);
  cairo_clip(destCairo);
  cairo_paint_with_alpha(destCairo, ctxt->add->alpha);

  cairo_restore(destCairo);
}

void CGContextDrawImage(CGContextRef ctx, CGRect rect, CGImageRef image)
{
  CGRect srcrect = opal_CGImageGetSourceRect(image);
  OPLOGCALL("ctx /*%p*/, CGRectMake(%g, %g, %g, %g), <image>(%p, subrect %g %g %g %g)", ctx, rect.origin.x,
            rect.origin.y, rect.size.width, rect.size.height, image, srcrect.origin.x, srcrect.origin.y, srcrect.size.width, srcrect.size.height)

  opal_draw_surface_in_rect(ctx, rect,
    opal_CGImageGetSurfaceForImage(image, cairo_get_target(ctx->ct)),
    opal_CGImageGetSourceRect(image));

  OPRESTORELOGGING()
}

void CGContextDrawTiledImage(CGContextRef ctx, CGRect rect, CGImageRef image)
{
  OPLOGCALL("ctx /*%p*/, CGRectMake(%g, %g, %g, %g), <image>", ctx, rect.origin.x,
            rect.origin.y, rect.size.width, rect.size.height)
  OPRESTORELOGGING()
}

void CGContextDrawPDFDocument(
  CGContextRef ctx,
  CGRect rect,
  CGPDFDocumentRef document,
  int page)
{
  OPLOGCALL("ctx /*%p*/, CGRectMake(%g, %g, %g, %g), <image>, %d", ctx, rect.origin.x,
            rect.origin.y, rect.size.width, rect.size.height, page)
  OPRESTORELOGGING()
}

void CGContextDrawPDFPage(CGContextRef ctx, CGPDFPageRef page)
{
  OPLOGCALL("ctx /*%p*/, <page>", ctx)
  OPRESTORELOGGING()
}

static void opal_AddStops(cairo_pattern_t *pat, CGGradientRef grad)
{
  // FIXME: support other colorspaces by converting to deviceRGB
  if (![CGColorSpaceCreateDeviceRGB() isEqual: OPGradientGetColorSpace(grad)])
  {
    NSLog(@"%s: Only DeviceRGB supported for gradients", __PRETTY_FUNCTION__);
    return;
  }
    
  size_t cs_numcomps = 4; // == (CGColorSpaceGetNumberOfComponents(OPGradientGetColorSpace(grad)) + 1);
  
  size_t numcomps = OPGradientGetCount(grad);
  
  const CGFloat *components = OPGradientGetComponents(grad);
  const CGFloat *locations = OPGradientGetLocations(grad);
  
  for (int i=0; i<numcomps; i++)
  {
    cairo_pattern_add_color_stop_rgba(pat, locations[i], components[i*cs_numcomps], components[i*cs_numcomps + 1],
      components[i*cs_numcomps + 2], components[i*cs_numcomps + 3]);
  }
}

void CGContextDrawLinearGradient(
  CGContextRef ctx,
  CGGradientRef gradient,
  CGPoint startPoint,
  CGPoint endPoint,
  CGGradientDrawingOptions options)
{
  OPLOGCALL("ctx /*%p*/, <gradient>, CGPointMake(%g, %g), CGPointMake(%g, %g), %d", ctx,
            startPoint.x, startPoint.y, endPoint.x, endPoint.y, options)
  cairo_pattern_t *pat = cairo_pattern_create_linear(startPoint.x, startPoint.y, endPoint.x, endPoint.y);
  opal_AddStops(pat, gradient);
  
  cairo_set_source(ctx->ct, pat);
  // FIXME: respect CGGradientDrawingOptions
  cairo_paint(ctx->ct);
  
  cairo_pattern_destroy(pat);
  OPRESTORELOGGING()
}

void CGContextDrawRadialGradient(
  CGContextRef ctx,
  CGGradientRef gradient,
  CGPoint startCenter,
  CGFloat startRadius,
  CGPoint endCenter,
  CGFloat endRadius,
  CGGradientDrawingOptions options)
{
  OPLOGCALL("ctx, <gradient>, CGPointMake(%g, %g),%g, CGPointMake(%g, %g),%g, "
            "%d", startCenter.x, startCenter.y, startRadius, endCenter.x,
            endCenter.y, endRadius, options)
  cairo_pattern_t *pat = cairo_pattern_create_radial(startCenter.x, startCenter.y, startRadius,
    endCenter.x, endCenter.y, endRadius);
  opal_AddStops(pat, gradient);
  
  cairo_set_source(ctx->ct, pat);
  // FIXME: respect CGGradientDrawingOptions
  cairo_paint(ctx->ct);
  
  cairo_pattern_destroy(pat);
  OPRESTORELOGGING()
}

void CGContextDrawShading(
  CGContextRef ctx,
  CGShadingRef shading
);

void CGContextSetFont(CGContextRef ctx, CGFontRef font)
{
  OPLOGCALL("ctx /*%p*/, <font>", ctx)
  if (!font) {
    NSLog(@" CGContextSetFont got NULL");
    return;
  }
  cairo_set_font_face(ctx->ct, cairo_scaled_font_get_font_face(((CairoFont*)font)->cairofont));
  ctx->add->font = CGFontRetain(font);
  OPRESTORELOGGING()
}

void CGContextSetFontSize(CGContextRef ctx, CGFloat size)
{
  OPLOGCALL("ctx /*%p*/, %g", ctx, size)
  ctx->add->font_size = size;
  OPRESTORELOGGING()
}

void CGContextSelectFont(
  CGContextRef ctx,
  const char *name,
  CGFloat size,
  CGTextEncoding textEncoding)
{
  OPLOGCALL("ctx /*%p*/, \"%s\", %g, %d", ctx, name, size, textEncoding)
  NSString *n = [[NSString alloc] initWithUTF8String: name];
  CGContextSetFont(ctx, CGFontCreateWithFontName(n));
  CGContextSetFontSize(ctx, size);
  [n release];
  OPRESTORELOGGING()
}

void CGContextSetCharacterSpacing(CGContextRef ctx, CGFloat spacing)
{
  OPLOGCALL("ctx /*%p*/, %g", ctx, spacing)
  ctx->add->char_spacing = spacing;
  OPRESTORELOGGING()
}

void CGContextSetTextDrawingMode(CGContextRef ctx, CGTextDrawingMode mode)
{
  OPLOGCALL("ctx /*%p*/, %d", ctx, mode)
  ctx->add->text_mode = mode;
  OPRESTORELOGGING()
}

void CGContextSetTextPosition(CGContextRef ctx, CGFloat x, CGFloat y)
{
  OPLOGCALL("ctx /*%p*/, %g, %g", ctx, x, y)
  ctx->txtmatrix.tx = x;
  ctx->txtmatrix.ty = y;
  OPRESTORELOGGING()
}

CGPoint CGContextGetTextPosition(CGContextRef ctx)
{
  return CGPointMake(ctx->txtmatrix.tx, ctx->txtmatrix.ty);
}

void CGContextSetTextMatrix(CGContextRef ctx, CGAffineTransform transform)
{
  OPLOGCALL("ctx /*%p*/, CGAffineTransformMake(%g, %g, %g, %g, %g, %g)", ctx, transform.a,
    transform.b, transform.c, transform.d, transform.tx, transform.ty)
  ctx->txtmatrix = transform;
  OPRESTORELOGGING()
}

CGAffineTransform CGContextGetTextMatrix(CGContextRef ctx)
{
  return ctx->txtmatrix;
}

void CGContextShowText(CGContextRef ctx, const char *string, size_t length)
{
  OPLOGCALL("ctx /*%p*/, \"%s\", %d", ctx, string, length)
  // Add a null character to the string

  char *cString;
  if (length + 1 > 0)
  {
    cString = (char *)malloc(length+1);
    memcpy(cString, string, length);
    cString[length] = '\0';
  }
  else
  {
    OPRESTORELOGGING()
    return;
  }

  // Save the cairo current point and move to the origin

  bool hadPoint;
  double oldX, oldY;
  if (cairo_has_current_point(ctx->ct))
  {
    cairo_get_current_point(ctx->ct, &oldX, &oldY);
    hadPoint = true;
  }
  else
  {
    hadPoint = false;
  }
  cairo_move_to(ctx->ct, 0, 0);

  // Compute the cairo text matrix

  cairo_matrix_t cairotextmatrix, opaltextmatrix;

  cairo_matrix_init_identity(&cairotextmatrix);

  // << Compensate for the flip

  cairo_matrix_scale(&cairotextmatrix, 1, -1);
  cairo_matrix_translate(&cairotextmatrix, 0, -1);

  // >> // FIXME: this seems to work, but is it correct?

  cairo_matrix_scale(&cairotextmatrix, ctx->add->font_size, ctx->add->font_size);

  cairo_matrix_init(&opaltextmatrix, ctx->txtmatrix.a, ctx->txtmatrix.b, ctx->txtmatrix.c,
    ctx->txtmatrix.d, ctx->txtmatrix.tx, ctx->txtmatrix.ty);  

  cairo_matrix_multiply(&cairotextmatrix, &cairotextmatrix, &opaltextmatrix);

  cairo_set_font_matrix(ctx->ct, &cairotextmatrix);

  if(ctx->add->fill_cp)
    cairo_set_source(ctx->ct, ctx->add->fill_cp);
  else
    cairo_set_source(ctx->ct, default_cp);

  cairo_show_text(ctx->ct, cString);


  // Update the opal text matrix with the distance the current point moved

  double dx, dy;
  cairo_get_current_point(ctx->ct, &dx, &dy);
  
  CGPoint textPos = CGContextGetTextPosition(ctx);
  CGContextSetTextPosition(ctx, textPos.x + dx, textPos.y + dy);
  // FXIME: scaled?

  // Restore the cairo path to the way it was before we did any text

  if (hadPoint)
  {
    cairo_move_to(ctx->ct, oldX, oldY);
  }
  else
  {
    cairo_new_path(ctx->ct);
  }
  OPRESTORELOGGING()
}

/**
 * Displays text at the given point (in user-space)
 */
void CGContextShowTextAtPoint(
  CGContextRef ctx,
  CGFloat x,
  CGFloat y,
  const char *cstring,
  size_t length)
{
  OPLOGCALL("ctx /*%p*/, %g, %g, \"%s\", %d", ctx, x, y, cstring, length)
  CGContextSetTextPosition(ctx, x, y);
  CGContextShowText(ctx, cstring, length);
  OPRESTORELOGGING()
}

void CGContextShowGlyphs(CGContextRef ctx, const CGGlyph *glyphs, size_t count)
{
  OPLOGCALL("ctx /*%p*/, <glyphs>, %d", ctx, count)
  // FIXME: Okay to stack allocate?
  int advances[count];
  if (CGFontGetGlyphAdvances(ctx->add->font, glyphs, count, advances))
  {
    CGSize fAdvances[count];

    CGFloat glyphSpaceToTextSpace = ctx->add->font_size / CGFontGetUnitsPerEm(ctx->add->font);
    for (int i=0; i<count; i++)
    {
      // FIXME: Assumes the glyphs are to be layed out horizontally.. check that
      // Quartz makes the same assumption.
      fAdvances[i].width = (advances[i] * glyphSpaceToTextSpace) + ctx->add->char_spacing;
      fAdvances[i].height = 0;

      // Convert the width from text space to user space
      fAdvances[i] = CGSizeApplyAffineTransform(fAdvances[i], CGContextGetTextMatrix(ctx));
    }
    CGContextShowGlyphsWithAdvances(ctx, glyphs, fAdvances, count);
  } 
  OPRESTORELOGGING()
}

void CGContextShowGlyphsAtPoint(
  CGContextRef ctx,
  CGFloat x,
  CGFloat y,
  const CGGlyph *glyphs,
  size_t count)
{
  OPLOGCALL("ctx /*%p*/, %g, %g, <glyphs>, %d", ctx, x, y, count)
  CGContextSetTextPosition(ctx, x, y);
  CGContextShowGlyphs(ctx, glyphs, count);
  OPRESTORELOGGING()
}

/**
 * Displays glyphs at the specified positions, specified in text-space.
 * The current text position is not updated modified.
 *
 * Note that because the positions are given in text space, they are
 * transformed by the text matrix (i.e. the current text position
 * affects the final glyph positions)
 */
void CGContextShowGlyphsAtPositions(
  CGContextRef ctx,
  const CGGlyph glyphs[],
  const CGPoint positions[],
  size_t count)
{
  OPLOGCALL("ctx /*%p*/, <glyphs>, <positions>, %d", ctx, count)

  // This matches CG; nothing is drawn unless a font size is explicitly set. 
  if (ctx->add->font_size == 0)
  {
    NSLog(@"%s: context's font size is set to zero.", __PRETTY_FUNCTION__);
    OPRESTORELOGGING()
    return;
  }

  // FIXME: Okay to stack allocate?
  cairo_glyph_t cairoGlyphs[count];
  for (int i=0; i<count; i++) {
    cairoGlyphs[i].index = glyphs[i];
    CGPoint userSpacePoint = CGPointApplyAffineTransform(positions[i], CGContextGetTextMatrix(ctx));
    cairoGlyphs[i].x = userSpacePoint.x;
    cairoGlyphs[i].y = userSpacePoint.y;
  }


  // Compute the cairo text matrix

  cairo_matrix_t cairotextmatrix, opaltextmatrix;

  cairo_matrix_init_identity(&cairotextmatrix);

  // << Compensate for the flip

  cairo_matrix_scale(&cairotextmatrix, 1, -1);
  cairo_matrix_translate(&cairotextmatrix, 0, -1);

  // >> // FIXME: this seems to work, but is it correct?

  cairo_matrix_scale(&cairotextmatrix, ctx->add->font_size, ctx->add->font_size);

  cairo_matrix_init(&opaltextmatrix, ctx->txtmatrix.a, ctx->txtmatrix.b, ctx->txtmatrix.c,
    ctx->txtmatrix.d, 0, 0); 

  cairo_matrix_multiply(&cairotextmatrix, &cairotextmatrix, &opaltextmatrix);

  cairo_set_font_matrix(ctx->ct, &cairotextmatrix);

  // Show the glpyhs

  if(ctx->add->fill_cp)
    cairo_set_source(ctx->ct, ctx->add->fill_cp);
  else
    cairo_set_source(ctx->ct, default_cp);
  
  // FIXME: Report this as a cairo bug.. the following places the glyphs after the first one incorrectly
  //cairo_show_glyphs(ctx->ct, cairoGlyphs, count);
  // WORKAROUND:
  for (int i=0; i<count; i++) {
    cairo_show_glyphs(ctx->ct, &(cairoGlyphs[i]), 1);
  }
  OPRESTORELOGGING()
}

/**
 * Draws the given glyphs starting at the current text position, with the
 * given advances. Advances are in user-space.
 */
void CGContextShowGlyphsWithAdvances (
  CGContextRef ctx,
  const CGGlyph glyphs[],
  const CGSize advances[],
  size_t count)
{
  OPLOGCALL("ctx /*%p*/, <glyphs>, <advances>, %d", ctx, count)
  if (count <= 0) {
    OPRESTORELOGGING()
    return;
  }
  // FIXME: Okay to stack allocate?
  CGPoint positions[count];
  positions[0] = CGPointMake(0,0);
  for (size_t i=1; i<count; i++) {
    CGSize textSpaceAdvance = CGSizeApplyAffineTransform(advances[i-1], CGAffineTransformInvert(CGContextGetTextMatrix(ctx)));
    positions[i] = CGPointMake(positions[i - 1].x + textSpaceAdvance.width,
      positions[i - 1].y + textSpaceAdvance.height);
    
  }
  CGContextShowGlyphsAtPositions(ctx, glyphs, positions, count);

  // Update the text position
  CGPoint pos = CGContextGetTextPosition(ctx);
  for (size_t i=0; i<count; i++) {
    pos.x += advances[i].width;
    pos.y += advances[i].height;
  }
  CGContextSetTextPosition(ctx, pos.x, pos.y);
  OPRESTORELOGGING()
}

void CGContextBeginTransparencyLayer(
  CGContextRef ctx,
  CFDictionaryRef auxiliaryInfo)
{
  OPLOGCALL("ctx /*%p*/, <auxiliaryInfo>", ctx)
  // Save cairo state, to match CGContextBeginTransparencyLayerWithRect
  cairo_save(ctx->ct); 
  
  // Save Opal state, and set alpha to 1 and shadows off (within the
  // transparency layer)
  CGContextSaveGState(ctx);
  CGContextSetAlpha(ctx, 1.0);
  CGContextSetShadowWithColor(ctx, CGSizeMake(0,0), 0, NULL);

  cairo_push_group(ctx->ct);
  OPRESTORELOGGING()
}

void CGContextBeginTransparencyLayerWithRect(
   CGContextRef ctx,
   CGRect rect,
   CFDictionaryRef auxiliaryInfo)
{
  OPLOGCALL("ctx /*%p*/, CGRectMake(%g, %g, %g, %g), <auxiliaryInfo>", ctx,
            rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)
  // Save cairo state because we are goint to clip to the given rect
  cairo_save(ctx->ct);
  cairo_new_path(ctx->ct);
  CGContextAddRect(ctx, rect);
  cairo_clip(ctx->ct);

  // Save Opal state, and set alpha to 1 and shadows off (within the
  // transparency layer)
  CGContextSaveGState(ctx);
  CGContextSetAlpha(ctx, 1.0);
  CGContextSetShadowWithColor(ctx, CGSizeMake(0,0), 0, NULL);

  cairo_push_group(ctx->ct);
  OPRESTORELOGGING()
}

void CGContextEndTransparencyLayer(CGContextRef ctx)
{
  OPLOGCALL("ctx /*%p*/", ctx)
  cairo_pattern_t *group = cairo_pop_group(ctx->ct);
  
  // Now undo the change to alpha and shadow state
  CGContextRestoreGState(ctx);
  
  // Paint the contents of the transparency layer.
  cairo_set_source(ctx->ct, group);
  cairo_pattern_destroy(group);
  cairo_paint_with_alpha(ctx->ct, ctx->add->alpha);
  
  // Undo the clipping (if any)
  cairo_restore(ctx->ct);
  OPRESTORELOGGING()
}

/**
 * Returns the affine transformation mapping user space to device space.
 * Note this includes the flip transformation, along with the scale factor.
 */
CGAffineTransform CGContextGetUserSpaceToDeviceSpaceTransform(CGContextRef ctx)
{
  cairo_matrix_t cmat;
  cairo_get_matrix(ctx->ct, &cmat);
  cairo_matrix_invert(&cmat);
  return CGAffineTransformMake(cmat.xx, cmat.yx, cmat.xy, cmat.yy, cmat.x0, cmat.y0);
}

CGPoint CGContextConvertPointToDeviceSpace(CGContextRef ctx, CGPoint point)
{
  return CGPointApplyAffineTransform(point, 
    CGContextGetUserSpaceToDeviceSpaceTransform(ctx));
}

CGPoint CGContextConvertPointToUserSpace(CGContextRef ctx, CGPoint point)
{
  return CGPointApplyAffineTransform(point,
    CGAffineTransformInvert(CGContextGetUserSpaceToDeviceSpaceTransform(ctx)));
}

CGSize CGContextConvertSizeToDeviceSpace(CGContextRef ctx, CGSize size)
{
  return CGSizeApplyAffineTransform(size, 
    CGContextGetUserSpaceToDeviceSpaceTransform(ctx));
}

CGSize CGContextConvertSizeToUserSpace(CGContextRef ctx, CGSize size)
{
  return CGSizeApplyAffineTransform(size, 
    CGAffineTransformInvert(CGContextGetUserSpaceToDeviceSpaceTransform(ctx)));
}

CGRect CGContextConvertRectToDeviceSpace(CGContextRef ctx, CGRect rect)
{
  return CGRectApplyAffineTransform(rect, 
    CGContextGetUserSpaceToDeviceSpaceTransform(ctx));
}

CGRect CGContextConvertRectToUserSpace(CGContextRef ctx, CGRect rect)
{
  return CGRectApplyAffineTransform(rect, 
    CGAffineTransformInvert(CGContextGetUserSpaceToDeviceSpaceTransform(ctx)));
}

void OpalContextSetScaleFactor(CGContextRef ctx, CGFloat scale)
{
  if (scale == 0)
    return;
  CGFloat old = ctx->scale_factor;
  ctx->scale_factor = scale;
  CGContextScaleCTM(ctx, scale/old, scale/old);
}


// Shadow support

/**
 * Perform a box blur on a one dimensional strip of an 8-bit alpha image 
 */
static inline void blur_1D(unsigned char *input, unsigned char *output,
                    int stride, int width, int radius)
{
  int i, sum = 0;
  for (i = -radius; i <= radius; i++) {
    sum += input[stride * MAX(0,MIN(width-1,i))];
  }
  for (i = 0; i < width; i++) {
    output[stride * i] = (sum / ((2*radius) + 1));
    sum += input[stride * MAX(0,MIN(width-1, i+1+radius))];
    sum -= input[stride * MAX(0,MIN(width-1, i-radius))];
  }
}

static void blur_alpha_image_surface(cairo_surface_t *surface, float radius)
{
  int iteration, x, y;
  int imageWidth = cairo_image_surface_get_width(surface);
  int imageHeight = cairo_image_surface_get_height(surface);
  int stride = cairo_image_surface_get_stride(surface);
  int intRadius = (int)radius;
  unsigned char *data = cairo_image_surface_get_data(surface);
  unsigned char *buf = malloc(stride * imageHeight);

  if (intRadius < 1)
    return;

  if (cairo_image_surface_get_format(surface) != CAIRO_FORMAT_A8)
    return;
 
  for (iteration = 0; iteration < 3; iteration++)
    {
      // Horizontal blur
      for (y = 0; y < imageHeight; y++)
        blur_1D(data + (y*stride), buf + (y*stride), 1, imageWidth, intRadius);
      memcpy(data, buf, stride*imageHeight);

      // Vertical blur
      for (x = 0; x < imageWidth; x++)
        blur_1D(data + x, buf + x, stride, imageHeight, intRadius);
      memcpy(data, buf, stride*imageHeight);
    }
  free(buf);
}

static void start_shadow(CGContextRef ctx)
{
  cairo_push_group(ctx->ct);
}

/**
 * Draws everything between the last start_shadow call and this function
 * with a shadow.
 */
static void end_shadow(CGContextRef ctx, CGRect bounds)
{
  cairo_pattern_t *pattern = cairo_pop_group(ctx->ct);
  
 // writeOut(pattern);
  
  cairo_save(ctx->ct);
  
  //#if 0
  // Create the shadow mask
  cairo_surface_t *alphaSurface = 
    cairo_image_surface_create(CAIRO_FORMAT_A8, 500, 250);
                                 //ceil(bounds.size.width + 2*radius),
                                 //ceil(bounds.size.height + 2*radius)); 
  cairo_t *alphaCt = cairo_create(alphaSurface);
  //cairo_surface_set_device_offset(alphaSurface, 0, 250); 
  //cairo_scale(alphaCt, 1.0, -1.0);
  
  cairo_set_source(alphaCt, pattern);
  cairo_paint(alphaCt);
  cairo_surface_flush(alphaSurface);
  blur_alpha_image_surface(alphaSurface, ctx->add->shadow_radius);
  
  // Draw the shadow
  // cairo_set_source(ctx->ct, ctx->add->shadow_cp);
  cairo_set_source_rgba(ctx->ct, 0, 0, 0, 0.3); // FIXME hardcoded
  
  // FIXME: the offset is not supposed to be affected by the CTM
  cairo_mask_surface(ctx->ct, alphaSurface, ctx->add->shadow_offset.width, 
                                            ctx->add->shadow_offset.height);
  
  // Draw the actual content
  cairo_set_source(ctx->ct, pattern);
  cairo_paint(ctx->ct);
  
  cairo_restore(ctx->ct);
}
