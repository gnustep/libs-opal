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
#include "CGContext-private.h"

#include <CoreFoundation/CoreFoundation.h>
#include <stdlib.h>
#include <math.h>
#include <cairo.h>
#include "opal.h"

/* The default (opaque black) color in a Cairo context,
 * used if no other color is set on the context yet */
static cairo_pattern_t *default_cp;

extern void opal_surface_flush(cairo_surface_t *target);
extern void opal_cspace_todev(CGColorSpaceRef cs, CGFloat *dest, const CGFloat comps[]);
extern cairo_font_face_t *opal_font_get_cairo_font(CGFontRef font);

extern cairo_surface_t *opal_CGImageGetSurfaceForImage(CGImageRef img);

static inline void set_color(cairo_pattern_t **cp, CGColorRef clr, double alpha);
static void start_shadow(CGContextRef ctx);
static void end_shadow(CGContextRef ctx, CGRect bounds);

#ifndef MAX
#define MAX(a,b) \
       ({typeof(a) _MAX_a = (a); typeof(b) _MAX_b = (b);  \
         _MAX_a > _MAX_b ? _MAX_a : _MAX_b; })
#define	GS_DEFINED_MAX
#endif

#ifndef MIN
#define MIN(a,b) \
       ({typeof(a) _MIN_a = (a); typeof(b) _MIN_b = (b);  \
         _MIN_a < _MIN_b ? _MIN_a : _MIN_b; })
#define	GS_DEFINED_MIN
#endif

void opal_dealloc_CGContext(void *c)
{
  CGContextRef ctx = c;
  ct_additions *ctadd, *next;

  ctadd = ctx->add;
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

  cairo_destroy(ctx->ct);
  free(ctx);
}

CGContextRef opal_new_CGContext(cairo_surface_t *target, CGSize device_size)
{
  CGContextRef ctx;
  cairo_status_t cret;

  ctx = opal_obj_alloc("CGContext", sizeof(CGContext));
  if (!ctx) return NULL;

  ctx->add = NULL;
  ctx->ct = cairo_create(target);
  cret = cairo_status(ctx->ct);
  if (cret) {
    errlog("%s:%d: cairo_create status: %s\n",
           __FILE__, __LINE__, cairo_status_to_string(cret));
    opal_dealloc_CGContext(ctx);
    return NULL;
  }

  ctx->add = calloc(1, sizeof(struct ct_additions));
  if (!ctx->add) {
    errlog("%s:%d: calloc failed\n", __FILE__, __LINE__);
    opal_dealloc_CGContext(ctx);
    return NULL;
  }
  ctx->add->alpha = 1;
  ctx->add->font_size = 0;
  
  if (!default_cp) {
    default_cp = cairo_get_source(ctx->ct);
    cairo_pattern_reference(default_cp);
  }

  /* Cairo defaults to line width 2.0 (see http://cairographics.org/FAQ) */
  cairo_set_line_width(ctx->ct, 1);

  /* Perform the flip transformation. Note that this is 'hidden' in 
     CGContextGetCTM() */
  cairo_scale(ctx->ct, 1, -1);
  cairo_translate(ctx->ct, 0, -device_size.height);

  ctx->txtmatrix = CGAffineTransformIdentity;
  ctx->scale_factor = 1;
  ctx->device_size = device_size;
  
  return ctx;
}

CGContextRef CGContextRetain(CGContextRef ctx)
{
  return (ctx ? opal_obj_retain(ctx) : NULL);
}

void CGContextRelease(CGContextRef ctx)
{
  if(ctx) opal_obj_release(ctx);
}

void CGContextFlush(CGContextRef ctx)
{
  cairo_surface_t *target;

  target = cairo_get_target(ctx->ct);
  /* FIXME: This doesn't work for most Cairo backends (including Xlib) */
  /* cairo_surface_flush(target); */
  /* So now we have to do it directly instead */
  opal_surface_flush(target);
}

void CGContextSynchronize(CGContextRef ctx)
{
  /* FIXME: Could do cairo_surface_mark_dirty here, but that does nothing */
  /* NOP */
}

void CGContextBeginPage(CGContextRef ctx, const CGRect *mediaBox)
{
  /* FIXME: should we reset gstate?, mediaBox is ignored */
  cairo_copy_page(ctx->ct);
}

void CGContextEndPage(CGContextRef ctx)
{
  cairo_show_page(ctx->ct);
}

void CGContextScaleCTM(CGContextRef ctx, CGFloat sx, CGFloat sy)
{
  cairo_scale(ctx->ct, sx, sy);
}

void CGContextTranslateCTM(CGContextRef ctx, CGFloat tx, CGFloat ty)
{
  cairo_translate(ctx->ct, tx, ty);
}

void CGContextRotateCTM(CGContextRef ctx, CGFloat angle)
{
  cairo_rotate(ctx->ct, angle);
}

void CGContextConcatCTM(CGContextRef ctx, CGAffineTransform transform)
{
  cairo_matrix_t cmat;

  cmat.xx = transform.a;
  cmat.xy = transform.b;
  cmat.yx = transform.c;
  cmat.yy = transform.d;
  cmat.x0 = transform.tx;
  cmat.y0 = transform.ty;

  cairo_transform(ctx->ct, &cmat);
}

/**
 * Returns the current transformation matrix. Note: this include the scale
 * factor but not the flip transformation.
 */
CGAffineTransform CGContextGetCTM(CGContextRef ctx)
{
  cairo_matrix_t cmat;

  cairo_get_matrix(ctx->ct, &cmat);
  
  // "Undo" the flip transformation
  cairo_matrix_translate(&cmat, 0, ctx->device_size.height);
  cairo_matrix_scale(&cmat, 1, -1);
  
  return CGAffineTransformMake(cmat.xx, cmat.yx, cmat.xy, cmat.yy, cmat.x0, cmat.y0);
}

void CGContextSaveGState(CGContextRef ctx)
{
  ct_additions *ctadd;
  cairo_status_t cret;

  ctadd = calloc(1, sizeof(struct ct_additions));
  if (!ctadd) {
    errlog("%s:%d: calloc failed\n", __FILE__, __LINE__);
    return;
  }

  cairo_save(ctx->ct);
  cret = cairo_status(ctx->ct);
  if (cret) {
    errlog("%s:%d: cairo_save status: %s\n",
           __FILE__, __LINE__, cairo_status_to_string(cret));
    free(ctadd);
    return;
  }

  *ctadd = *ctx->add;
  CGColorRetain(ctadd->fill_color);
  cairo_pattern_reference(ctadd->fill_cp);
  CGColorRetain(ctadd->stroke_color);
  cairo_pattern_reference(ctadd->stroke_cp);
  ctadd->next = ctx->add;
  ctx->add = ctadd;
}

void CGContextRestoreGState(CGContextRef ctx)
{
  ct_additions *ctadd;

  if (!ctx->add) return;

  CGColorRelease(ctx->add->fill_color);
  cairo_pattern_destroy(ctx->add->fill_cp);
  CGColorRelease(ctx->add->stroke_color);
  cairo_pattern_destroy(ctx->add->stroke_cp);
  ctadd = ctx->add->next;
  free(ctx->add);
  ctx->add = ctadd;

  cairo_restore(ctx->ct);
}

void CGContextSetShouldAntialias(CGContextRef ctx, int shouldAntialias)
{
  cairo_set_antialias(ctx->ct,
    (shouldAntialias ? CAIRO_ANTIALIAS_DEFAULT : CAIRO_ANTIALIAS_NONE));
}

void CGContextSetLineWidth(CGContextRef ctx, CGFloat width)
{
  cairo_set_line_width(ctx->ct, width);
}

void CGContextSetLineJoin(CGContextRef ctx, CGLineJoin join)
{
  cairo_set_line_join(ctx->ct, join);
}

void CGContextSetMiterLimit(CGContextRef ctx, CGFloat limit)
{
  cairo_set_miter_limit(ctx->ct, limit);
}

void CGContextSetLineCap(CGContextRef ctx, CGLineCap cap)
{
  cairo_set_line_cap(ctx->ct, cap);
}

void CGContextSetLineDash(
  CGContextRef ctx,
  CGFloat phase,
  const CGFloat lengths[],
  size_t count)
{
  double dashes[count]; /* C99 allows this */
  size_t i;

  for (i=0; i<count; i++)
    dashes[i] = lengths[i];

  cairo_set_dash(ctx->ct, dashes, count, phase);
}

void CGContextSetFlatness(CGContextRef ctx, CGFloat flatness)
{
  cairo_set_tolerance(ctx->ct, flatness);
}

void CGContextSetShadow(
  CGContextRef ctx,
  CGSize offset,
  CGFloat radius)
{  
  CGColorRef defaultShadowColor = CGColorCreateGenericGray(0, 0.3);
  CGContextSetShadowWithColor(ctx, offset, radius, defaultShadowColor);
  CGColorRelease(defaultShadowColor);
}

void CGContextSetShadowWithColor(
  CGContextRef ctx,
  CGSize offset,
  CGFloat radius,
  CGColorRef color)
{
  CGColorRelease(ctx->add->shadow_color);
  ctx->add->shadow_color = color;
  CGColorRetain(color);
  
  ctx->add->shadow_offset = offset;
  ctx->add->shadow_radius = radius;
  set_color(&ctx->add->shadow_cp, color, 1.0);
}

void CGContextBeginPath(CGContextRef ctx)
{
  cairo_new_path(ctx->ct);
}

void CGContextClosePath(CGContextRef ctx)
{
  cairo_close_path(ctx->ct);
}

void CGContextMoveToPoint(CGContextRef ctx, CGFloat x, CGFloat y)
{
  cairo_move_to(ctx->ct, x, y);
}

void CGContextAddLineToPoint(CGContextRef ctx, CGFloat x, CGFloat y)
{
  cairo_line_to(ctx->ct, x, y);
}

void CGContextAddLines(CGContextRef ctx, const CGPoint points[], size_t count)
{
  size_t i;

  if (count <= 0) return;
  CGContextMoveToPoint(ctx, points[0].x, points[0].y);
  for (i=1; i<count; i++)
    CGContextAddLineToPoint(ctx, points[i].x, points[i].y);
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
  cairo_curve_to(ctx->ct, cp1x, cp1y, cp2x, cp2y, x, y);
}

void CGContextAddRect(CGContextRef ctx, CGRect rect)
{
  cairo_rectangle(ctx->ct, rect.origin.x, rect.origin.y,
                  rect.size.width, rect.size.height);
}

void CGContextAddRects(CGContextRef ctx, const CGRect rects[], size_t count)
{
  size_t i;

  for (i=0; i<count; i++)
    CGContextAddRect(ctx, rects[i]);
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
  if (clockwise)
    cairo_arc_negative(ctx->ct, x, y, radius, startAngle, endAngle);
  else
    cairo_arc(ctx->ct, x, y, radius, startAngle, endAngle);
}

void CGContextAddArcToPoint(
  CGContextRef ctx,
  CGFloat x1,
  CGFloat y1,
  CGFloat x2,
  CGFloat y2,
  CGFloat radius)
{
  double x0, y0;
  double dx0, dy0, dx2, dy2, xl0, xl2;
  double san, n0x, n0y, n2x, n2y, t;

  cairo_get_current_point(ctx->ct, &x0, &y0);
  dx0 = x0 - x1;
  dy0 = y0 - y1;
  xl0 = sqrt(dx0*dx0 + dy0*dy0);
  if (xl0 == 0) return;

  dx2 = x2 - x1;
  dy2 = y2 - y1;
  xl2 = sqrt(dx2*dx2 + dy2*dy2);

  san = dx2*dy0 - dx0*dy2;
  if (san == 0) {
    CGContextAddLineToPoint(ctx, x1, y1);
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
}

void CGContextStrokePath(CGContextRef ctx)
{
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
    errlog("%s:%d: cairo_stroke status: %s\n",
           __FILE__, __LINE__, cairo_status_to_string(cret));
}

static void fill_path(CGContextRef ctx, int eorule, int preserve)
{
  cairo_status_t cret;

  if (ctx->add->shadow_cp) {
    start_shadow(ctx);
  }

  if(ctx->add->fill_cp)
    cairo_set_source(ctx->ct, ctx->add->fill_cp);
  else
    cairo_set_source(ctx->ct, default_cp);

  if (eorule) cairo_set_fill_rule(ctx->ct, CAIRO_FILL_RULE_EVEN_ODD);
  cairo_fill_preserve(ctx->ct);
  if (eorule) cairo_set_fill_rule(ctx->ct, CAIRO_FILL_RULE_WINDING);
  if (!preserve) cairo_new_path(ctx->ct);
  
  if (ctx->add->shadow_cp) {
    end_shadow(ctx, CGRectMake(0,0,500,500)); //FIXME
  }
  
  cret = cairo_status(ctx->ct);
  if (cret)
    errlog("%s:%d: cairo_fill status: %s\n",
           __FILE__, __LINE__, cairo_status_to_string(cret));
}

void CGContextFillPath(CGContextRef ctx)
{
  fill_path(ctx, 0, 0);
}

void CGContextEOFillPath(CGContextRef ctx)
{
  fill_path(ctx, 1, 0);
}

void CGContextDrawPath(CGContextRef ctx, CGPathDrawingMode mode)
{
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
      errlog("%s:%d: CGContextDrawPath invalid CGPathDrawingMode: %d\n",
             __FILE__, __LINE__, mode);
  }
}

void CGContextStrokeRect(CGContextRef ctx, CGRect rect)
{
  CGContextBeginPath(ctx);
  CGContextAddRect(ctx, rect);
  CGContextStrokePath(ctx);
}

void CGContextStrokeRectWithWidth(CGContextRef ctx, CGRect rect, CGFloat width)
{
  CGContextSetLineWidth(ctx, width);
  CGContextStrokeRect(ctx, rect);
  /* Line width is not restored (see Technical QA1045) */
}

void CGContextFillRect(CGContextRef ctx, CGRect rect)
{
  CGContextBeginPath(ctx);
  CGContextAddRect(ctx, rect);
  CGContextFillPath(ctx);
}

void CGContextFillRects(CGContextRef ctx, const CGRect rects[], size_t count)
{
  CGContextBeginPath(ctx);
  CGContextAddRects(ctx, rects, count);
  CGContextFillPath(ctx);
}

void CGContextStrokeLineSegments(
  CGContextRef ctx,
  const CGPoint points[],
  size_t count)
{
  size_t i;

  CGContextBeginPath(ctx);
  for (i=1; i<count; i+=2) {
    CGContextMoveToPoint(ctx, points[i-1].x, points[i-1].y);
    CGContextAddLineToPoint(ctx, points[i].x, points[i].y);
  }
  CGContextStrokePath(ctx);
}

CGPoint CGContextGetPathCurrentPoint(CGContextRef ctx)
{
  double x, y;

  cairo_get_current_point(ctx->ct, &x, &y);
  return CGPointMake(x, y);
}

void CGContextClip(CGContextRef ctx)
{
  cairo_clip(ctx->ct);
}

void CGContextEOClip(CGContextRef ctx)
{
  cairo_set_fill_rule(ctx->ct, CAIRO_FILL_RULE_EVEN_ODD);
  CGContextClip(ctx);
  cairo_set_fill_rule(ctx->ct, CAIRO_FILL_RULE_WINDING);
}

void CGContextClipToRect(CGContextRef ctx, CGRect rect)
{
  CGContextBeginPath(ctx);
  CGContextAddRect(ctx, rect);
  CGContextClip(ctx);
}

void CGContextClipToRects(CGContextRef ctx, const CGRect rects[], size_t count)
{
  CGContextBeginPath(ctx);
  CGContextAddRects(ctx, rects, count);
  CGContextClip(ctx);
}

static inline void set_color(cairo_pattern_t **cp, CGColorRef clr, double alpha)
{
  CGFloat cc[4];
  // FIXME: check why this might be called with a NULL clr
  if (!clr) return;
  cairo_pattern_t *newcp;
  cairo_status_t cret;
  
  opal_cspace_todev(CGColorGetColorSpace(clr), cc, CGColorGetComponents(clr));
    
  newcp = cairo_pattern_create_rgba(cc[0], cc[1], cc[2], cc[3]*alpha);
  cret = cairo_pattern_status(newcp);
  if (cret) {
    errlog("%s:%d: cairo_pattern_create_rgba status: %s\n",
           __FILE__, __LINE__, cairo_status_to_string(cret));
    return;
  }
  cairo_pattern_destroy(*cp);
  *cp = newcp;
}

void CGContextSetFillColorWithColor(CGContextRef ctx, CGColorRef color)
{
  CGColorRelease(ctx->add->fill_color);
  ctx->add->fill_color = color;
  CGColorRetain(color);
  set_color(&ctx->add->fill_cp, color, ctx->add->alpha);
}

void CGContextSetStrokeColorWithColor(CGContextRef ctx, CGColorRef color)
{
  CGColorRelease(ctx->add->stroke_color);
  ctx->add->stroke_color = color;
  CGColorRetain(color);
  set_color(&ctx->add->stroke_cp, color, ctx->add->alpha);
}

void CGContextSetAlpha(CGContextRef ctx, CGFloat alpha)
{
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
}

void CGContextSetFillColorSpace(CGContextRef ctx, CGColorSpaceRef colorspace)
{
  CGFloat *components;
  CGColorRef color;
  size_t nc;

  nc = CGColorSpaceGetNumberOfComponents(colorspace);
  components = calloc(nc+1, sizeof(CGFloat));
  if (components) {
    errlog("%s:%d: calloc failed\n", __FILE__, __LINE__);
    return;
  }
  /* Default is an opaque, zero intensity color (usually black) */
  components[nc] = 1;
  color = CGColorCreate(colorspace, components);
  free(components);
  CGContextSetFillColorWithColor(ctx, color);
  CGColorRelease(color);
}

void CGContextSetStrokeColorSpace(CGContextRef ctx, CGColorSpaceRef colorspace)
{
  CGFloat *components;
  CGColorRef color;
  size_t nc;

  nc = CGColorSpaceGetNumberOfComponents(colorspace);
  components = calloc(nc+1, sizeof(CGFloat));
  if (components) {
    errlog("%s:%d: calloc failed\n", __FILE__, __LINE__);
    return;
  }
  /* Default is an opaque, zero intensity color (usually black) */
  components[nc] = 1;
  color = CGColorCreate(colorspace, components);
  free(components);
  CGContextSetStrokeColorWithColor(ctx, color);
  CGColorRelease(color);
}

void CGContextSetFillColor(CGContextRef ctx, const CGFloat components[])
{
  CGColorSpaceRef cs;
  CGColorRef color;

  cs = CGColorGetColorSpace(ctx->add->fill_color);
  color = CGColorCreate(cs, components);
  CGContextSetFillColorWithColor(ctx, color);
  CGColorRelease(color);
}

void CGContextSetStrokeColor(CGContextRef ctx, const CGFloat components[])
{
  CGColorSpaceRef cs;
  CGColorRef color;

  cs = CGColorGetColorSpace(ctx->add->stroke_color);
  color = CGColorCreate(cs, components);
  CGContextSetStrokeColorWithColor(ctx, color);
  CGColorRelease(color);
}

void CGContextSetGrayFillColor(CGContextRef ctx, CGFloat gray, CGFloat alpha)
{
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
}

void CGContextSetGrayStrokeColor(CGContextRef ctx, CGFloat gray, CGFloat alpha)
{
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
}

void CGContextSetRGBFillColor(CGContextRef ctx,
       CGFloat r, CGFloat g, CGFloat b, CGFloat alpha)
{
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
}

void CGContextSetRGBStrokeColor(CGContextRef ctx,
       CGFloat r, CGFloat g, CGFloat b, CGFloat alpha)
{
  CGFloat comps[4];
  CGColorSpaceRef cs;
  CGColorRef color;

  comps[0] = r;
  comps[1] = g;
  comps[2] = b;
  comps[3] = alpha;
  cs = CGColorSpaceCreateDeviceRGB();
  color = CGColorCreate(CGColorSpaceCreateDeviceRGB(), comps);
  CGColorSpaceRelease(cs);
  CGContextSetStrokeColorWithColor(ctx, color);
  CGColorRelease(color);
}

void opal_draw_surface_in_rect(CGContextRef ctxt, CGRect rect, cairo_surface_t *src, CGRect srcRect)
{
  cairo_t *destCairo = ctxt->ct;
  cairo_save(destCairo);
  
  cairo_pattern_t *pattern = cairo_pattern_create_for_surface(src);
    
  cairo_matrix_t patternMatrix;
  cairo_matrix_init_identity(&patternMatrix);
  
  // Move to the place where the layer should be drawn
  cairo_matrix_translate(&patternMatrix, rect.origin.x, rect.origin.y);
  // Scale the pattern to the correct size
  cairo_matrix_scale(&patternMatrix,
    rect.size.width / srcRect.size.width,
    rect.size.height / srcRect.size.height);
  // Flip the layer up-side-down
  cairo_matrix_scale(&patternMatrix, 1, -1);
  cairo_matrix_translate(&patternMatrix, 0, -srcRect.size.height);

  cairo_matrix_invert(&patternMatrix);
  
  cairo_pattern_set_matrix(pattern, &patternMatrix);
  
  // FIXME: do we always want this?
  cairo_pattern_set_extend(pattern, CAIRO_EXTEND_PAD);
  
  cairo_set_operator(destCairo, CAIRO_OPERATOR_OVER);
  cairo_set_source(destCairo, pattern);
  cairo_pattern_destroy(pattern);
  
  // FIXME: What is the fastest way to draw? cairo_paint? clip? fill a rect?
  cairo_rectangle(destCairo, rect.origin.x, rect.origin.y,
    rect.size.width, rect.size.height);
  cairo_fill(destCairo);

  cairo_restore(destCairo);
}

void CGContextDrawImage(CGContextRef ctx, CGRect rect, CGImageRef image)
{
  opal_draw_surface_in_rect(ctx, rect, opal_CGImageGetSurfaceForImage(image),
    CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)));
}

void CGContextSetFont(CGContextRef ctx, CGFontRef font)
{
  if (!font) {
    errlog("%s:%d: CGContextSetFont got NULL\n", __FILE__, __LINE__);
    return;
  }
  cairo_set_font_face(ctx->ct, opal_font_get_cairo_font(font));
  ctx->add->font = CGFontRetain(font);
}

void CGContextSetFontSize(CGContextRef ctx, CGFloat size)
{
  ctx->add->font_size = size;
}

void CGContextSelectFont(
  CGContextRef ctx,
  const char *name,
  CGFloat size,
  CGTextEncoding textEncoding)
{
  /* FIXME: textEncoding is ignored */
  CGContextSetFont(ctx, CGFontCreateWithFontName(CFStringCreateWithCString(NULL, name, kCFStringEncodingASCII)));
  CGContextSetFontSize(ctx, size);
}

void CGContextSetCharacterSpacing(CGContextRef ctx, CGFloat spacing)
{
  ctx->add->char_spacing = spacing;
}

void CGContextSetTextDrawingMode(CGContextRef ctx, CGTextDrawingMode mode)
{
  ctx->add->text_mode = mode;
}

void CGContextSetTextPosition(CGContextRef ctx, CGFloat x, CGFloat y)
{
  ctx->txtmatrix.tx = x;
  ctx->txtmatrix.ty = y;
}

CGPoint CGContextGetTextPosition(CGContextRef ctx)
{
  return CGPointMake(ctx->txtmatrix.tx, ctx->txtmatrix.ty);
}

void CGContextSetTextMatrix(CGContextRef ctx, CGAffineTransform transform)
{
  ctx->txtmatrix = transform;
}

CGAffineTransform CGContextGetTextMatrix(CGContextRef ctx)
{
  return ctx->txtmatrix;
}

void CGContextShowText(CGContextRef ctx, const char *cstring, size_t length)
{
  cairo_matrix_t matrix, opaltextmatrix, cairotextmatrix;

  cairo_matrix_init(&opaltextmatrix, ctx->txtmatrix.a, ctx->txtmatrix.b, ctx->txtmatrix.c,
    ctx->txtmatrix.d, ctx->txtmatrix.tx, ctx->txtmatrix.ty);  
  cairo_get_font_matrix(ctx->ct, &cairotextmatrix);
  cairo_matrix_multiply(&matrix, &cairotextmatrix, &opaltextmatrix); 
  cairo_set_font_matrix(ctx->ct, &matrix);

  if(ctx->add->fill_cp)
    cairo_set_source(ctx->ct, ctx->add->fill_cp);
  else
    cairo_set_source(ctx->ct, default_cp);

  /* FIXME: length is ignored, \0 terminated string is assumed */
  cairo_show_text(ctx->ct, cstring);

  double x, y;
  cairo_get_current_point(ctx->ct, &x, &y);
  ctx->txtmatrix.tx = x - cairotextmatrix.x0;
  ctx->txtmatrix.ty = y - cairotextmatrix.y0;
  
  cairo_set_font_matrix(ctx->ct, &cairotextmatrix);
}

void CGContextShowTextAtPoint(
  CGContextRef ctx,
  CGFloat x,
  CGFloat y,
  const char *cstring,
  size_t length)
{
  CGContextSetTextPosition(ctx, x, y);
  CGContextShowText(ctx, cstring, length);
}

void CGContextShowGlyphs(CGContextRef ctx, const CGGlyph *glyphs, size_t count)
{
  // FIXME: Okay to stack allocate?
  int advances[count];
  if (CGFontGetGlyphAdvances(ctx->add->font, glyphs, count, advances))
  {
    CGSize fAdvances[count];
    CGFloat mult = ctx->add->font_size / CGFontGetUnitsPerEm(ctx->add->font);
    for (int i=0; i<count; i++)
    {
      // FIXME: Assumes the glyphs are to be layed out horizontally.. check that
      // Quartz makes the same assumption.
      fAdvances[i].width = (advances[i] * mult) + ctx->add->char_spacing;
      fAdvances[i].height = 0;
    }
    CGContextShowGlyphsWithAdvances(ctx, glyphs, fAdvances, count);
  }
}

void CGContextShowGlyphsAtPoint(
  CGContextRef ctx,
  CGFloat x,
  CGFloat y,
  const CGGlyph *glyphs,
  size_t count)
{
  CGContextSetTextPosition(ctx, x, y);
  CGContextShowGlyphs(ctx, glyphs, count);
}

void CGContextShowGlyphsAtPositions(
  CGContextRef ctx,
  const CGGlyph glyphs[],
  const CGPoint positions[],
  size_t count)
{
  // FIXME: Okay to stack allocate?
  cairo_glyph_t cairoGlyphs[count];
  for (int i=0; i<count; i++) {
    cairoGlyphs[i].index = glyphs[i];
    cairoGlyphs[i].x = positions[i].x;
    cairoGlyphs[i].y = positions[i].y;
  }

  cairo_matrix_t matrix, opaltextmatrix, cairotextmatrix;

  cairo_matrix_init(&opaltextmatrix, ctx->txtmatrix.a, ctx->txtmatrix.b, ctx->txtmatrix.c,
    ctx->txtmatrix.d, ctx->txtmatrix.tx, ctx->txtmatrix.ty);  
  cairo_get_font_matrix(ctx->ct, &cairotextmatrix);
  cairo_matrix_multiply(&matrix, &cairotextmatrix, &opaltextmatrix); 
  cairo_set_font_matrix(ctx->ct, &matrix);

  if(ctx->add->fill_cp)
    cairo_set_source(ctx->ct, ctx->add->fill_cp);
  else
    cairo_set_source(ctx->ct, default_cp);
    
  cairo_show_glyphs(ctx->ct, cairoGlyphs, count);
  
  double x, y;
  cairo_get_current_point(ctx->ct, &x, &y);
  ctx->txtmatrix.tx = x - cairotextmatrix.x0;
  ctx->txtmatrix.ty = y - cairotextmatrix.y0;
  
  cairo_set_font_matrix(ctx->ct, &cairotextmatrix);
}

/**
 * Draws the given glyphs starting at the current text position.
 */
void CGContextShowGlyphsWithAdvances (
  CGContextRef ctx,
  const CGGlyph glyphs[],
  const CGSize advances[],
  size_t count)
{
  if (count <= 0) {
    return;
  }
  // FIXME: Okay to stack allocate?
  CGPoint positions[count];
  positions[0] = CGPointMake(ctx->txtmatrix.tx, ctx->txtmatrix.ty);
  for (size_t i=1; i<count; i++) {
    positions[i] = CGPointMake(positions[i - 1].x + advances[i].width,
      positions[i - 1].y + advances[i].height);
  }
  CGContextShowGlyphsAtPositions(ctx, glyphs, positions, count);
}

void CGContextBeginTransparencyLayer(
  CGContextRef ctx,
  CFDictionaryRef auxiliaryInfo)
{
  // Save cairo state, to match CGContextBeginTransparencyLayerWithRect
  cairo_save(ctx->ct); 
  
  // Save Opal state, and set alpha to 1 and shadows off (within the
  // transparency layer)
  CGContextSaveGState(ctx);
  CGContextSetAlpha(ctx, 1.0);
  CGContextSetShadowWithColor(ctx, CGSizeMake(0,0), 0, NULL);

  cairo_push_group(ctx->ct);
}

void CGContextBeginTransparencyLayerWithRect(
   CGContextRef ctx,
   CGRect rect,
   CFDictionaryRef auxiliaryInfo)
{
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
}

void CGContextEndTransparencyLayer(CGContextRef ctx)
{
  cairo_pattern_t *group = cairo_pop_group(ctx->ct);
  
  // Now undo the change to alpha and shadow state
  CGContextRestoreGState(ctx);
  
  // Paint the contents of the transparency layer.
  cairo_set_source(ctx->ct, group);
  cairo_pattern_destroy(group);
  cairo_paint_with_alpha(ctx->ct, ctx->add->alpha);
  
  // Undo the clipping (if any)
  cairo_restore(ctx->ct);
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
  cairo_matrix_t cmat;
  double x = point.x, y = point.y;
  
  cairo_get_matrix(ctx->ct, &cmat);
  cairo_matrix_transform_point(&cmat, &x, &y);
  return CGPointMake(x,y);
}

CGSize CGContextConvertSizeToDeviceSpace(CGContextRef ctx, CGSize size)
{
  return CGSizeApplyAffineTransform(size, 
    CGContextGetUserSpaceToDeviceSpaceTransform(ctx));
}

CGSize CGContextConvertSizeToUserSpace(CGContextRef ctx, CGSize size)
{
  cairo_matrix_t cmat;
  double w = size.width, h = size.height;
  
  cairo_get_matrix(ctx->ct, &cmat);
  cairo_matrix_transform_distance(&cmat, &w, &h);
  return CGSizeMake(w, h);
}

static CGRect make_bounding_rect(CGPoint p1, CGPoint p2, CGPoint p3, CGPoint p4)
{
  CGFloat minX = MIN(p1.x, MIN(p2.x, MIN(p3.x, p4.x)));
  CGFloat minY = MIN(p1.y, MIN(p2.y, MIN(p3.y, p4.y)));
  CGFloat maxX = MAX(p1.x, MAX(p2.x, MAX(p3.x, p4.x)));
  CGFloat maxY = MAX(p1.y, MAX(p2.y, MAX(p3.y, p4.y)));
  
  return CGRectMake(minX, minY, (maxX - minX), (maxY - minY));
}

CGRect CGContextConvertRectToDeviceSpace(CGContextRef ctx, CGRect rect)
{
  CGPoint p1 = CGContextConvertPointToDeviceSpace(ctx, 
    CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect)));
  CGPoint p2 = CGContextConvertPointToDeviceSpace(ctx,
	CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect)));
  CGPoint p3 = CGContextConvertPointToDeviceSpace(ctx,
    CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect)));  
  CGPoint p4 = CGContextConvertPointToDeviceSpace(ctx,
	CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect)));
  
  return make_bounding_rect(p1, p2, p3, p4);
}

CGRect CGContextConvertRectToUserSpace(CGContextRef ctx, CGRect rect)
{
  CGPoint p1 = CGContextConvertPointToUserSpace(ctx, 
    CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect)));
  CGPoint p2 = CGContextConvertPointToUserSpace(ctx,
	CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect)));
  CGPoint p3 = CGContextConvertPointToUserSpace(ctx,
    CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect)));  
  CGPoint p4 = CGContextConvertPointToUserSpace(ctx,
	CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect)));
  
  return make_bounding_rect(p1, p2, p3, p4);
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
  float radius = ctx->add->shadow_radius;
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
