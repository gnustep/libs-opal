/** <title>CGLayer</title>
 
 <abstract>C Interface to graphics drawing library</abstract>
 
 Copyright (C) 2009 Eric Wasylishen <ewasylishen@gmail.com>
 
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

#include <stdlib.h>
#include <math.h>
#include <CGLayer.h>
#include "CGContext-private.h"
#include "opal.h"

typedef struct CGLayer
{
  struct objbase base;
  CGContextRef ctxt;
  CGSize size;
} CGLayer;

void opal_dealloc_CGLayer(void *l)
{
  CGLayerRef layer = l;
  CGContextRelease(layer->ctxt);
  free(layer);
}

CGLayerRef CGLayerCreateWithContext(
  CGContextRef referenceCtxt,
  CGSize size,
  CFDictionaryRef auxInfo)
{
  CGLayerRef layer = opal_obj_alloc("CGLayer", sizeof(CGLayer));
  if (!layer) return NULL;
  
  // size is in user-space units of referenceCtxt, so transform it to device
  // space.
  double w = size.width, h = size.height;
  cairo_user_to_device_distance(referenceCtxt->ct, &w, &h);
  
  cairo_surface_t *layerSurface = 
    cairo_surface_create_similar(cairo_get_target(referenceCtxt->ct),
                                 CAIRO_CONTENT_COLOR_ALPHA,
                                 ceil(fabs(w)),
                                 ceil(fabs(h)));
  cairo_surface_set_device_offset(layerSurface, 0, ceil(fabs(h)));                                   
  layer->ctxt = opal_new_CGContext(layerSurface);
  CGContextScaleCTM(layer->ctxt, 1.0, -1.0);
  layer->size = size;
  
  return layer;
}

CGLayerRef CGLayerRetain(CGLayerRef layer)
{
  return (layer ? opal_obj_retain(layer) : NULL);
}

void CGLayerRelease(CGLayerRef layer)
{
  if (layer) opal_obj_release(layer);
}

CGSize CGLayerGetSize(CGLayerRef layer)
{
  return layer->size;
}

CGContextRef CGLayerGetContext(CGLayerRef layer)
{
  return layer->ctxt;
}

void CGContextDrawLayerInRect(
  CGContextRef destCtxt,
  CGRect rect,
  CGLayerRef layer)
{
  cairo_t *destCairo = destCtxt->ct;
  cairo_save(destCairo);
  
  cairo_pattern_t *pattern = 
    cairo_pattern_create_for_surface(cairo_get_target(layer->ctxt->ct));
    
  // Horrible code.. but sort-of works. Fix this up ASAP.
    
  cairo_matrix_t patternMatrix;
  cairo_matrix_init_identity(&patternMatrix);

  cairo_matrix_translate(&patternMatrix, 0, layer->size.height);

  cairo_matrix_translate(&patternMatrix, rect.origin.x, rect.origin.y);
  cairo_matrix_scale(&patternMatrix, 1, -1);
      cairo_matrix_scale(&patternMatrix,
    rect.size.width / layer->size.width,
    rect.size.height / layer->size.height);
 cairo_matrix_translate(&patternMatrix, 0, -layer->size.height);
  

  
  cairo_matrix_invert(&patternMatrix);
  
  
  cairo_pattern_set_matrix(pattern, &patternMatrix);
  
 // cairo_pattern_set_extend(pattern, CAIRO_EXTEND_PAD);
  
  cairo_set_source(destCairo, pattern);
  
  //cairo_set_source_surface(destCairo, cairo_get_target(layer->ctxt->ct), 20, 20);
  
  cairo_pattern_destroy(pattern);

  cairo_set_operator(destCairo, CAIRO_OPERATOR_OVER);
  //cairo_rectangle(destCairo, rect.origin.x, rect.origin.y,
  //  rect.size.width, rect.size.height);
  //cairo_fill(destCairo);
  
  cairo_paint(destCairo);
  
  cairo_restore(destCairo);
}

void CGContextDrawLayerAtPoint(
  CGContextRef destCtxt,
  CGPoint point,
  CGLayerRef layer)
{
  CGContextDrawLayerInRect(destCtxt,
    CGRectMake(point.x, point.y, layer->size.width, layer->size.height),
    layer);
}

#if 0 
CFTypeID CGLayerGetTypeID()
{

}
#endif
