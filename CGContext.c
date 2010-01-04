/** <title>CGContext</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright (C) 2006 BALATON Zoltan <balaton@eik.bme.hu>

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

#include "CGContext-private.h"
#include <stdlib.h>
#include <math.h>
#include <cairo.h>
#include "opal.h"

/* The default (opaque black) color in a Cairo context,
 * used if no other color is set on the context yet */
static cairo_pattern_t *default_cp;

extern void opal_surface_flush(cairo_surface_t *target);
extern void opal_cspace_todev(CGColorSpaceRef cs, double *dest, const float comps[]);
extern CGFontRef opal_FontCreateWithName(const char *name);

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

    next = ctadd->next;
    free(ctadd);
    ctadd = next;
  }

  cairo_destroy(ctx->ct);
  free(ctx);
}

CGContextRef opal_new_CGContext(cairo_surface_t *target)
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

  if (!default_cp) {
    default_cp = cairo_get_source(ctx->ct);
    cairo_pattern_reference(default_cp);
  }

  /* Cairo defaults to line width 2.0 (see http://cairographics.org/FAQ) */
  cairo_set_line_width(ctx->ct, 1);

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

void CGContextScaleCTM(CGContextRef ctx, float sx, float sy)
{
  cairo_scale(ctx->ct, sx, sy);
}

void CGContextTranslateCTM(CGContextRef ctx, float tx, float ty)
{
  cairo_translate(ctx->ct, tx, ty);
}

void CGContextRotateCTM(CGContextRef ctx, float angle)
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

CGAffineTransform CGContextGetCTM(CGContextRef ctx)
{
  cairo_matrix_t cmat;

  cairo_get_matrix(ctx->ct, &cmat);
  return CGAffineTransformMake(cmat.xx, -cmat.yx, cmat.xy, -cmat.yy, cmat.x0, -cmat.y0);
/*  return CGAffineTransformMake(cmat.xx, cmat.xy, cmat.yx, cmat.yy, cmat.x0, cmat.y0); */
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

void CGContextSetLineWidth(CGContextRef ctx, float width)
{
  cairo_set_line_width(ctx->ct, width);
}

void CGContextSetLineJoin(CGContextRef ctx, CGLineJoin join)
{
  cairo_set_line_join(ctx->ct, join);
}

void CGContextSetMiterLimit(CGContextRef ctx, float limit)
{
  cairo_set_miter_limit(ctx->ct, limit);
}

void CGContextSetLineCap(CGContextRef ctx, CGLineCap cap)
{
  cairo_set_line_cap(ctx->ct, cap);
}

void CGContextSetLineDash(
  CGContextRef ctx,
  float phase,
  const float lengths[],
  size_t count)
{
  double dashes[count]; /* C99 allows this */
  size_t i;

  for (i=0; i<count; i++)
    dashes[i] = lengths[i];

  cairo_set_dash(ctx->ct, dashes, count, phase);
}

void CGContextSetFlatness(CGContextRef ctx, float flatness)
{
  cairo_set_tolerance(ctx->ct, flatness);
}

void CGContextSetShadow(
  CGContextRef ctx,
  CGSize offset,
  CGFloat radius)
{
  // FIXME: Implement
}

void CGContextSetShadowWithColor(
  CGContextRef ctx,
  CGSize offset,
  CGFloat radius,
  CGColorRef color)
{
  // FIXME: Implement
}

void CGContextBeginPath(CGContextRef ctx)
{
  cairo_new_path(ctx->ct);
}

void CGContextClosePath(CGContextRef ctx)
{
  cairo_close_path(ctx->ct);
}

void CGContextMoveToPoint(CGContextRef ctx, float x, float y)
{
  cairo_move_to(ctx->ct, x, y);
}

void CGContextAddLineToPoint(CGContextRef ctx, float x, float y)
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
  float cp1x,
  float cp1y,
  float cp2x,
  float cp2y,
  float x,
  float y)
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
  float x,
  float y,
  float radius,
  float startAngle,
  float endAngle,
  int clockwise)
{
  if (clockwise)
    cairo_arc_negative(ctx->ct, x, y, radius, startAngle, endAngle);
  else
    cairo_arc(ctx->ct, x, y, radius, startAngle, endAngle);
}

void CGContextAddArcToPoint(
  CGContextRef ctx,
  float x1,
  float y1,
  float x2,
  float y2,
  float radius)
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

  if(ctx->add->stroke_cp)
    cairo_set_source(ctx->ct, ctx->add->stroke_cp);
  else
    cairo_set_source(ctx->ct, default_cp);

  cairo_stroke(ctx->ct);
  cret = cairo_status(ctx->ct);
  if (cret)
    errlog("%s:%d: cairo_stroke status: %s\n",
           __FILE__, __LINE__, cairo_status_to_string(cret));
}

static void fill_path(CGContextRef ctx, int eorule, int preserve)
{
  cairo_status_t cret;

  if(ctx->add->fill_cp)
    cairo_set_source(ctx->ct, ctx->add->fill_cp);
  else
    cairo_set_source(ctx->ct, default_cp);

  if (eorule) cairo_set_fill_rule(ctx->ct, CAIRO_FILL_RULE_EVEN_ODD);
  cairo_fill_preserve(ctx->ct);
  if (eorule) cairo_set_fill_rule(ctx->ct, CAIRO_FILL_RULE_WINDING);
  if (!preserve) cairo_new_path(ctx->ct);
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

void CGContextStrokeRectWithWidth(CGContextRef ctx, CGRect rect, float width)
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
  double cc[4];
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

void CGContextSetAlpha(CGContextRef ctx, float alpha)
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
  float *components;
  CGColorRef color;
  size_t nc;

  nc = CGColorSpaceGetNumberOfComponents(colorspace);
  components = calloc(nc+1, sizeof(float));
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
  float *components;
  CGColorRef color;
  size_t nc;

  nc = CGColorSpaceGetNumberOfComponents(colorspace);
  components = calloc(nc+1, sizeof(float));
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

void CGContextSetFillColor(CGContextRef ctx, const float components[])
{
  CGColorSpaceRef cs;
  CGColorRef color;

  cs = CGColorGetColorSpace(ctx->add->fill_color);
  color = CGColorCreate(cs, components);
  CGContextSetFillColorWithColor(ctx, color);
  CGColorRelease(color);
}

void CGContextSetStrokeColor(CGContextRef ctx, const float components[])
{
  CGColorSpaceRef cs;
  CGColorRef color;

  cs = CGColorGetColorSpace(ctx->add->stroke_color);
  color = CGColorCreate(cs, components);
  CGContextSetStrokeColorWithColor(ctx, color);
  CGColorRelease(color);
}

void CGContextSetGrayFillColor(CGContextRef ctx, float gray, float alpha)
{
  float comps[2];
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

void CGContextSetGrayStrokeColor(CGContextRef ctx, float gray, float alpha)
{
  float comps[2];
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
       float r, float g, float b, float alpha)
{
  float comps[4];
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
       float r, float g, float b, float alpha)
{
  float comps[4];
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

void CGContextSetFont(CGContextRef ctx, CGFontRef font)
{
  if (!font) {
    errlog("%s:%d: CGContextSetFont got NULL\n", __FILE__, __LINE__);
    return;
  }
  cairo_set_font_face(ctx->ct, (cairo_font_face_t *)font);
}

void CGContextSetFontSize(CGContextRef ctx, float size)
{
  cairo_matrix_t fm;

  /* The 10 * 96/72 factor is a heuristic. 1/96 is the cairo default unit,
   * 1/72 is the default in Postscript and PDF but why is *10 needed?
   * Nevertheless, it seems to produce about the right results. */
  cairo_matrix_init_scale(&fm, size * 10 * 96.0/72.0, -size * 10 * 96.0/72.0);
  cairo_set_font_matrix(ctx->ct, &fm);
}

void CGContextSelectFont(
  CGContextRef ctx,
  const char *name,
  float size,
  CGTextEncoding textEncoding)
{
  /* FIXME: textEncoding is ignored */
  CGContextSetFont(ctx, opal_FontCreateWithName(name));
  CGContextSetFontSize(ctx, size);
}

void CGContextSetTextPosition(CGContextRef ctx, float x, float y)
{
  ctx->txtpos.x = x;
  ctx->txtpos.y = y;
}

CGPoint CGContextGetTextPosition(CGContextRef ctx)
{
  return CGPointMake(ctx->txtpos.x, ctx->txtpos.y);
}

void CGContextShowText(CGContextRef ctx, const char *cstring, size_t length)
{
  double x, y;

  cairo_get_current_point(ctx->ct, &x, &y);
  cairo_move_to(ctx->ct, ctx->txtpos.x, ctx->txtpos.y);

  /* FIXME: All text is currently drawn with fill color.
   * Should support other text drawing modes. */
  if(ctx->add->fill_cp)
    cairo_set_source(ctx->ct, ctx->add->fill_cp);
  else
    cairo_set_source(ctx->ct, default_cp);

  /* FIXME: length is ignored, \0 terminated string is assumed */
  cairo_show_text(ctx->ct, cstring);

  cairo_get_current_point(ctx->ct, &ctx->txtpos.x, &ctx->txtpos.y);
  cairo_move_to(ctx->ct, x, y);
}

void CGContextShowTextAtPoint(
  CGContextRef ctx,
  float x,
  float y,
  const char *cstring,
  size_t length)
{
  CGContextSetTextPosition(ctx, x, y);
  CGContextShowText(ctx, cstring, length);
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
  cairo_pop_group_to_source(ctx->ct);
  
  // Paint the contents of the transparency layer. Note that we look at the
  // Opal state beneath the current one for the alpha value because
  // we want the alpha value before CGContextSaveGState was called 
  // in CGContextBeginTransparencyLayer
  cairo_paint_with_alpha(ctx->ct, ctx->add->next->alpha);
  
  // Now undo the change to alpha and shadow state
  CGContextRestoreGState(ctx);
  
  // Undo the clipping (if any)
  cairo_restore(ctx->ct);
}
