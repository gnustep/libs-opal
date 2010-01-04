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

#ifndef OPAL_CGContext_h
#define OPAL_CGContext_h

/* Data Types */

typedef struct CGContext * CGContextRef;

#include <CGAffineTransform.h>
#include <CGColor.h>
#include <CGFont.h>
#include <CGImage.h>
#include <CGPath.h>
#include <CGBase.h>
#include <CoreFoundation.h>

/* Constants */

typedef enum CGBlendMode {
  kCGBlendModeNormal = 0,
  kCGBlendModeMultiply = 1,
  kCGBlendModeScreen = 2,
  kCGBlendModeOverlay = 3,
  kCGBlendModeDarken = 4,
  kCGBlendModeLighten = 5,
  kCGBlendModeColorDodge = 6,
  kCGBlendModeColorBurn = 7,
  kCGBlendModeSoftLight = 8,
  kCGBlendModeHardLight = 9,
  kCGBlendModeDifference = 10,
  kCGBlendModeExclusion = 11,
  kCGBlendModeHue = 12,
  kCGBlendModeSaturation = 13,
  kCGBlendModeColor = 14,
  kCGBlendModeLuminosity = 15
} CGBlendMode;

typedef enum CGInterpolationQuality {
  kCGInterpolationDefault = 0,
  kCGInterpolationNone = 1,
  kCGInterpolationLow = 2,
  kCGInterpolationHigh = 3
} CGInterpolationQuality;

typedef enum CGLineCap {
  kCGLineCapButt = 0,
  kCGLineCapRound = 1,
  kCGLineCapSquare = 2
} CGLineCap;

typedef enum CGLineJoin {
  kCGLineJoinMiter = 0,
  kCGLineJoinRound = 1,
  kCGLineJoinBevel = 2
} CGLineJoin;

typedef enum CGTextDrawingMode {
  kCGTextFill = 0,
  kCGTextStroke = 1,
  kCGTextFillStroke = 2,
  kCGTextInvisible = 3,
  kCGTextFillClip = 4,
  kCGTextStrokeClip = 5,
  kCGTextFillStrokeClip = 6,
  kCGTextClip = 7
} CGTextDrawingMode;

typedef enum CGTextEncoding {
  kCGEncodingFontSpecific = 0,
  kCGEncodingMacRoman = 1
} CGTextEncoding;

/* Functions */

/* Managing Graphics Contexts */

CGContextRef CGContextRetain(CGContextRef ctx);

void CGContextRelease(CGContextRef ctx);

void CGContextFlush(CGContextRef ctx);

void CGContextSynchronize(CGContextRef ctx);

/* Defining Pages */

void CGContextBeginPage(CGContextRef ctx, const CGRect *mediaBox);

void CGContextEndPage(CGContextRef ctx);

/* Transforming the Coordinate Space of the Page */

void CGContextScaleCTM(CGContextRef ctx, float sx, float sy);

void CGContextTranslateCTM(CGContextRef ctx, float tx, float ty);

void CGContextRotateCTM(CGContextRef ctx, float angle);

void CGContextConcatCTM(CGContextRef ctx, CGAffineTransform transform);

CGAffineTransform CGContextGetCTM(CGContextRef ctx);

/* Saving and Restoring the Graphics State */

void CGContextSaveGState(CGContextRef ctx);

void CGContextRestoreGState(CGContextRef ctx);

/* Setting Graphics State Attributes */

void CGContextSetShouldAntialias(CGContextRef ctx, int shouldAntialias);

void CGContextSetLineWidth(CGContextRef ctx, float width);

void CGContextSetLineJoin(CGContextRef ctx, CGLineJoin join);

void CGContextSetMiterLimit(CGContextRef ctx, float limit);

void CGContextSetLineCap(CGContextRef ctx, CGLineCap cap);

void CGContextSetLineDash(
  CGContextRef ctx,
  float phase,
  const float lengths[],
  size_t count
);

void CGContextSetFlatness(CGContextRef ctx, float flatness);

CGInterpolationQuality CGContextGetInterpolationQuality(CGContextRef ctx);

void CGContextSetInterpolationQuality(
  CGContextRef ctx,
  CGInterpolationQuality quality
);

void CGContextSetPatternPhase (CGContextRef ctx, CGSize phase);

void CGContextSetFillPattern(
  CGContextRef ctx,
  CGPatternRef pattern,
  const float components[]
);

void CGContextSetStrokePattern(
  CGContextRef ctx,
  CGPatternRef pattern,
  const float components[]
);

void CGContextSetShouldSmoothFonts(CGContextRef ctx, int shouldSmoothFonts);

void CGContextSetBlendMode(CGContextRef ctx, CGBlendMode mode);

void CGContextSetAllowsAntialiasing(CGContextRef ctx, int allowsAntialiasing);

void CGContextSetShadow(
  CGContextRef ctx,
  CGSize offset,
  CGFloat radius
);

void CGContextSetShadowWithColor(
  CGContextRef ctx,
  CGSize offset,
  CGFloat radius,
  CGColorRef color
);

/* Constructing Paths */

void CGContextBeginPath(CGContextRef ctx);

void CGContextClosePath(CGContextRef ctx);

void CGContextMoveToPoint(CGContextRef ctx, float x, float y);

void CGContextAddLineToPoint(CGContextRef ctx, float x, float y);

void CGContextAddLines(CGContextRef ctx, const CGPoint points[], size_t count);

void CGContextAddCurveToPoint(
  CGContextRef ctx,
  float cp1x,
  float cp1y,
  float cp2x,
  float cp2y,
  float x,
  float y
);

void CGContextAddQuadCurveToPoint(
  CGContextRef ctx,
  float cpx,
  float cpy,
  float x,
  float y
);

void CGContextAddRect(CGContextRef ctx, CGRect rect);

void CGContextAddRects(CGContextRef ctx, const CGRect rects[], size_t count);

void CGContextAddArc(
  CGContextRef ctx,
  float x,
  float y,
  float radius,
  float startAngle,
  float endAngle,
  int clockwise
);

void CGContextAddArcToPoint(
  CGContextRef ctx,
  float x1,
  float y1,
  float x2,
  float y2,
  float radius
);

void CGContextAddPath(CGContextRef ctx, CGPathRef path);

void CGContextAddEllipseInRect(CGContextRef ctx, CGRect rect);

/* Painting Paths */

void CGContextStrokePath(CGContextRef ctx);

void CGContextFillPath(CGContextRef ctx);

void CGContextEOFillPath(CGContextRef ctx);

void CGContextDrawPath(CGContextRef ctx, CGPathDrawingMode mode);

void CGContextStrokeRect(CGContextRef ctx, CGRect rect);

void CGContextStrokeRectWithWidth(CGContextRef ctx, CGRect rect, float width);

void CGContextFillRect(CGContextRef ctx, CGRect rect);

void CGContextFillRects(CGContextRef ctx, const CGRect rects[], size_t count);

void CGContextClearRect(CGContextRef c, CGRect rect);

void CGContextFillEllipseInRect(CGContextRef ctx, CGRect rect);

void CGContextStrokeEllipseInRect(CGContextRef ctx, CGRect rect);

void CGContextStrokeLineSegments(
  CGContextRef ctx,
  const CGPoint points[],
  size_t count
);

/* Obtaining Path Information */

int CGContextIsPathEmpty(CGContextRef ctx);

CGPoint CGContextGetPathCurrentPoint(CGContextRef ctx);

CGRect CGContextGetPathBoundingBox(CGContextRef ctx);

/* Clipping Paths */

void CGContextClip(CGContextRef ctx);

void CGContextEOClip(CGContextRef ctx);

void CGContextClipToRect(CGContextRef ctx, CGRect rect);

void CGContextClipToRects(CGContextRef ctx, const CGRect rects[], size_t count);

/* Setting the Color Space and Colors */

void CGContextSetFillColorWithColor(CGContextRef ctx, CGColorRef color);

void CGContextSetStrokeColorWithColor(CGContextRef ctx, CGColorRef color);

void CGContextSetAlpha(CGContextRef ctx, float alpha);

void CGContextSetFillColorSpace(CGContextRef ctx, CGColorSpaceRef colorspace);

void CGContextSetStrokeColorSpace(CGContextRef ctx, CGColorSpaceRef colorspace);

void CGContextSetFillColor(CGContextRef ctx, const float components[]);

void CGContextSetStrokeColor(CGContextRef ctx, const float components[]);

void CGContextSetGrayFillColor(CGContextRef ctx, float gray, float alpha);

void CGContextSetGrayStrokeColor(CGContextRef ctx, float gray, float alpha);

void CGContextSetRGBFillColor(
    CGContextRef ctx,
    float r,
    float g,
    float b,
    float alpha
);

void CGContextSetRGBStrokeColor(
  CGContextRef ctx,
  float r,
  float g,
  float b,
  float alpha
);

void CGContextSetCMYKFillColor(
  CGContextRef ctx,
  float c,
  float m,
  float y,
  float k,
  float alpha
);

void CGContextSetCMYKStrokeColor(
  CGContextRef ctx,
  float c,
  float m,
  float y,
  float k,
  float alpha
);

void CGContextSetRenderingIntent(CGContextRef ctx, CGColorRenderingIntent intent);

/* Drawing Images */

void CGContextDrawImage(CGContextRef ctx, CGRect rect, CGImageRef image);

/* Drawing PDF Documents */
#if 0
void CGContextDrawPDFDocument(
  CGContextRef ctx,
  CGRect rect,
  CGPDFDocumentRef document,
  int page
);

void CGContextDrawPDFPage(CGContextRef ctx, CGPDFPageRef page);
#endif

/* Drawing Text */

void CGContextSetFont(CGContextRef ctx, CGFontRef font);

void CGContextSetFontSize(CGContextRef ctx, float size);

void CGContextSelectFont(
  CGContextRef ctx,
  const char *name,
  float size,
  CGTextEncoding textEncoding
);

void CGContextSetCharacterSpacing(CGContextRef ctx, float spacing);

void CGContextSetTextDrawingMode(CGContextRef ctx, CGTextDrawingMode mode);

void CGContextSetTextPosition(CGContextRef ctx, float x, float y);

CGPoint CGContextGetTextPosition(CGContextRef ctx);

void CGContextSetTextMatrix(CGContextRef ctx, CGAffineTransform transform);

CGAffineTransform CGContextGetTextMatrix(CGContextRef ctx);

void CGContextShowText(CGContextRef ctx, const char *cstring, size_t length);

void CGContextShowTextAtPoint(
  CGContextRef ctx,
  float x,
  float y,
  const char *cstring,
  size_t length
);

void CGContextShowGlyphs(CGContextRef ctx, const CGGlyph *g, size_t count);

void CGContextShowGlyphsAtPoint(
  CGContextRef ctx,
  float x,
  float y,
  const CGGlyph *g,
  size_t count
);

/* Transparency Layers */

void CGContextBeginTransparencyLayer(
  CGContextRef ctx,
  CFDictionaryRef auxiliaryInfo
);

void CGContextBeginTransparencyLayerWithRect(
  CGContextRef ctx,
  CGRect rect,
  CFDictionaryRef auxiliaryInfo
);

void CGContextEndTransparencyLayer(CGContextRef ctx);

#endif /* OPAL_CGContext_h */

