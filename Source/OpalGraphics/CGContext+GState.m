#import "CGContext-private.h"

/**
 * This object attempts to copy all of the graphics state
 * from an opal context and save it in an object.
 *
 * Notably, nonrectangular clipping paths cannot be copied.
 */
@interface OpalGStateSnapshot : NSObject
{
  // cairo stuff
  cairo_matrix_t ctm;
  cairo_path_t *path;
  cairo_operator_t op;
  cairo_pattern_t *pattern;
  double tolerance;
  cairo_antialias_t antialias;
  cairo_fill_rule_t fillrule;
  double linewidth;
  cairo_line_cap_t linecap;
  cairo_line_join_t linejoin;
  double *dashes;
  int dashes_count;
  double dashes_offset;
  double miterlimit;
  cairo_rectangle_list_t *cliprects;
  cairo_scaled_font_t *scaledfont;

  // opal additions
  ct_additions add;
}

- (id) initWithContext: (CGContext *)ctx;
- (void) applyToContext: (CGContext *)ctx;

@end

@implementation OpalGStateSnapshot

- (id) initWithContext: (CGContext *)ctx;
{
  self = [super init];

  // cairo stuff

  cairo_t *aCairo = ctx->ct;

  cairo_status_t status;
  cairo_get_matrix(aCairo, &ctm);

  path = cairo_copy_path(aCairo);
  status = path->status;
  if (status != CAIRO_STATUS_SUCCESS)
    {
      /*
	Due to an interesting programming concept in cairo this does not
	mean that an error has occured. It may as well just be that the 
	old path had no elements. 
	At least in cairo 1.4.10 (See file cairo-path.c, line 379).
      */
      // NSLog(@"Cairo status '%s' in copy path", cairo_status_to_string(status));
    }

  op = cairo_get_operator(aCairo);
  pattern = cairo_pattern_reference(cairo_get_source(aCairo));
  tolerance = cairo_get_tolerance(aCairo);
  antialias = cairo_get_antialias(aCairo);
  fillrule = cairo_get_fill_rule(aCairo);
  linewidth = cairo_get_line_width(aCairo);
  linecap = cairo_get_line_cap(aCairo);
  linejoin = cairo_get_line_join(aCairo);

  miterlimit = cairo_get_miter_limit(aCairo);
  scaledfont = cairo_scaled_font_reference(cairo_get_scaled_font(aCairo));

  dashes_count = cairo_get_dash_count(aCairo);
  if (dashes_count > 0)
  {
    dashes = malloc(dashes_count);
    
    if (dashes != NULL)
  	{
  	  cairo_get_dash(aCairo, dashes, &dashes_offset);
  	}
  }
  cliprects = cairo_copy_clip_rectangle_list(aCairo);

  // opal additions

  add = *ctx->add;
  CGColorRetain(add.fill_color);
  cairo_pattern_reference(add.fill_cp);
  CGColorRetain(add.stroke_color);
  cairo_pattern_reference(add.stroke_cp);

  return self;
}

- (void) applyToContext: (CGContext *)ctx
{
  // cairo stuff

  cairo_t *aCairo = ctx->ct;

  // we must be careful with the order here. restore the ctm first.

  cairo_status_t status;
  cairo_set_matrix(aCairo, &ctm);

  status = cairo_status(aCairo);
  if (status != CAIRO_STATUS_SUCCESS)
  {
    NSLog(@"Cairo status '%s' in set matrix", cairo_status_to_string(status));
  }

  // next restore the clip rects, since setting the clip involves
  // setting the path.

  cairo_new_path(aCairo);

  if (cliprects != NULL && cliprects->status == CAIRO_STATUS_SUCCESS)
  {
    for (int i=0; i<cliprects->num_rectangles; i++)
    {
      cairo_rectangle_t rect = cliprects->rectangles[i];

      cairo_rectangle(aCairo, rect.x, rect.y, rect.width, rect.height);
    }
    cairo_clip(aCairo);

    status = cairo_status(aCairo);
    if (status != CAIRO_STATUS_SUCCESS)
    {
      NSLog(@"Cairo status '%s' in restore clip", cairo_status_to_string(status));
    }
  }

  cairo_new_path(aCairo);
  if (path->status == CAIRO_STATUS_SUCCESS)
  {
     cairo_append_path(aCairo, path);
  }

  cairo_set_operator(aCairo, op);
  cairo_set_source(aCairo, pattern);
  cairo_set_tolerance(aCairo, tolerance);
  cairo_set_antialias(aCairo, antialias);
  cairo_set_fill_rule(aCairo, fillrule);
  cairo_set_line_width(aCairo, linewidth);
  cairo_set_line_cap(aCairo, linecap);
  cairo_set_line_join(aCairo, linejoin);
  cairo_set_dash(aCairo, dashes, dashes_count, dashes_offset);
  cairo_set_miter_limit(aCairo, miterlimit);
  cairo_set_scaled_font(aCairo, scaledfont);

  // opal additions

  CGColorRetain(add.fill_color);
  cairo_pattern_reference(add.fill_cp);
  CGColorRetain(add.stroke_color);
  cairo_pattern_reference(add.stroke_cp);
  *(ctx->add) = add;
}

- (void) dealloc
{
  cairo_path_destroy(path);
  cairo_pattern_destroy(pattern);
  free(dashes);
  cairo_scaled_font_destroy(scaledfont);
  cairo_rectangle_list_destroy(cliprects);

  // Release ctx->add
  // FIXME: Copied from CGContext -dealloc
  {
    CGColorRelease(add.fill_color);
    cairo_pattern_destroy(add.fill_cp);
    CGColorRelease(add.stroke_color);
    cairo_pattern_destroy(add.stroke_cp);
    CGColorRelease(add.shadow_color);
    cairo_pattern_destroy(add.shadow_cp);
    //CGFontRelease(add.font);
  }

  [super dealloc];
}

@end

OPGStateRef OPContextCopyGState(CGContextRef ctx)
{
  return [[OpalGStateSnapshot alloc] initWithContext: (CGContext *)ctx];
}

void OPContextSetGState(CGContextRef ctx, OPGStateRef gstate)
{
  [(OpalGStateSnapshot *)gstate applyToContext: (CGContext *)ctx];
}
