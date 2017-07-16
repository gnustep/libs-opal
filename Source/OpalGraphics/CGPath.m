/** <title>CGPath</title>

 <abstract>C Interface to graphics drawing library</abstract>

 Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

 Author: Eric Wasylishen
 Date: June 2010

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

#import <Foundation/NSObject.h>
#include "CoreGraphics/CGPath.h"

#import "OPPath.h"

typedef struct
{
  double x, y;
} double_point;

// This magic number is 4 *(sqrt(2) -1)/3
#define KAPPA 0.5522847498

static NSUInteger _OPPathElementPointCount(CGPathElementType type)
{
  NSUInteger numPoints;
  switch (type)
  {
    case kCGPathElementMoveToPoint:
      numPoints = 1;
      break;
    case kCGPathElementAddLineToPoint:
      numPoints = 1;
      break;
    case kCGPathElementAddQuadCurveToPoint:
      numPoints = 2;
      break;
    case kCGPathElementAddCurveToPoint:
      numPoints = 3;
      break;
    case kCGPathElementCloseSubpath:
    default:
      numPoints = 0;
      break;
  }

  return numPoints;
}

CGPathRef CGPathCreateCopy(CGPathRef path)
{
  return [path copy];
}

CGMutablePathRef CGPathCreateMutable()
{
  return [[CGMutablePath alloc] init];
}

CGMutablePathRef CGPathCreateMutableCopy(CGPathRef path)
{
  return [[CGMutablePath alloc] initWithCGPath: path];
}

CGMutablePathRef CGPathCreateMutableCopyByTransformingPath(
  CGPathRef path, const CGAffineTransform *m)
{
  CGMutablePathRef ret = CGPathCreateMutable();

  NSUInteger count = [path count];
  for (NSUInteger i = 0; i < count; i++)
  {
    CGPoint points[3];
    CGPathElementType type = [path elementTypeAtIndex: i points: points];
    NSUInteger numPoints = _OPPathElementPointCount(type);

    for (NSUInteger i = 0; i < numPoints; i++)
    {
      points[i] = CGPointApplyAffineTransform(points[i], *m);
    }
    [ret addElementWithType: type
                     points: points];
  }

  return ret;
}

CGPathRef CGPathRetain(CGPathRef path)
{
  return [path retain];
}

void CGPathRelease(CGPathRef path)
{
  [path release];
}

bool CGPathIsEmpty(CGPathRef path)
{
  return [path count] == 0;
}

bool CGPathEqualToPath(CGPathRef path1, CGPathRef path2)
{
  return [path1 isEqual: path2];
}

bool CGPathIsRect(CGPathRef path, CGRect *rect)
{
  return [path isRect: rect];
}

CGRect CGPathGetBoundingBox(CGPathRef path)
{
  NSUInteger count = [path count];
  CGFloat minX = 0.0;
  CGFloat minY = 0.0;
  CGFloat maxX = 0.0;
  CGFloat maxY = 0.0;

  for (NSUInteger i=0; i<count; i++)
  {
    CGPoint points[3];
    CGPathElementType type = [path elementTypeAtIndex: i points: points];
    NSUInteger numPoints = _OPPathElementPointCount(type);
      
    if (i == 0)
    {
      minX = points[0].x;
      minY = points[0].y;
      maxX = points[0].x;
      maxY = points[0].y;
    }

    for (NSUInteger p=0; p<numPoints; p++)
    {
      if (points[p].x < minX)
      {
        minX = points[p].x;
      }
      else if (points[p].x > maxX)
      {
        maxX = points[p].x;
      }
      
      if (points[p].y < minY)
      {
        minY = points[p].y;
      }
      else if (points[p].y > maxY)
      {
        maxY = points[p].y;
      }
    }
  }

  return CGRectMake(minX, minY, (maxX-minX), (maxY-minY));
}

CGPoint CGPathGetCurrentPoint(CGPathRef path)
{
  if (CGPathIsEmpty(path))
  {
    return CGPointZero;
  }

  NSUInteger count = [path count];
  // FIXME: ugly loop
  for (NSUInteger i=(count-1); i>=0 && i<count; i--)
  {
    CGPoint points[3];
    CGPathElementType type =[path elementTypeAtIndex: i points: points];

    switch (type)
    {
      case kCGPathElementMoveToPoint:
      case kCGPathElementAddLineToPoint:
        return points[0];
      case kCGPathElementAddQuadCurveToPoint:
        return points[1];
      case kCGPathElementAddCurveToPoint:
        return points[2];
      case kCGPathElementCloseSubpath:
      default:
        break;
    }
  }
  return CGPointZero;
}

static int winding_line(double_point from, double_point to, double_point p)
{
  int y_dir;
  double k, x;

  if (from.y == to.y)
    return 0;

  if (to.y < from.y)
    {
      y_dir = -2;
      if (p.y < to.y)
	return 0;
      if (p.y > from.y)
	return 0;
    }
  else
    {
      y_dir = 2;
      if (p.y < from.y)
	return 0;
      if (p.y > to.y)
	return 0;
    }

  if (p.y == from.y || p.y == to.y)
    y_dir /= 2;

  /* The line is intersected.  Check if the intersection is outside the
     line's bounding box.  */
  if (to.x < from.x)
    {
      if (p.x < to.x)
	return 0;
      if (p.x > from.x)
	return y_dir;
    }
  else
    {
      if (p.x < from.x)
	return 0;
      if (p.x > to.x)
	return y_dir;
    }

  /* Determine the exact x coordinate of the intersection.  */
  k = (double)(from.x - to.x) / (double)(from.y - to.y);
  x = to.x + k * (double)(p.y - to.y);
  if (x < p.x)
    return y_dir;

  return 0;
}

static int winding_curve(double_point from, double_point to, double_point c1,
                         double_point c2, double_point p, int depth)
{
  double x0, x1;
  double y0, y1;
  double scale;

  /* Get the vertical extents of the convex hull.  */
  y0 = y1 = from.y;
  if (to.y < y0)
    y0 = to.y;
  else if (to.y > y1)
    y1 = to.y;
  if (c1.y < y0)
    y0 = c1.y;
  else if (c1.y > y1)
    y1 = c1.y;
  if (c2.y < y0)
    y0 = c2.y;
  else if (c2.y > y1)
    y1 = c2.y;

  /* If the point is outside the convex hull, the line can't intersect the
     curve.  */
  if (p.y < y0 || p.y > y1)
    return 0;

  /* Get the horizontal convex hull.  */
  x0 = x1 = from.x;
  if (to.x < x0)
    x0 = to.x;
  else if (to.x > x1)
    x1 = to.x;
  if (c1.x < x0)
    x0 = c1.x;
  else if (c1.x > x1)
    x1 = c1.x;
  if (c2.x < x0)
    x0 = c2.x;
  else if (c2.x > x1)
    x1 = c2.x;

  /* If the point is left of the convex hull, the line doesn't intersect
     the curve.  */
  if (p.x < x0)
    return 0;

  /* If the point is right of the convex hull, the net winding count is 0,
     1, or -1, and it depends only on how the end-points are placed in
     relation to the point.  Essentially, it's equivalent to a line.  */
  if (p.x > x1)
    return winding_line(from, to, p);

  /* Limit the recursion, just to be safe.  */
  if (depth >= 40)
    return winding_line(from, to, p);

  /* The line possibly intersects the curve in some interesting way.  If the
     curve is flat enough, we can pretend it's a line.  Otherwise, we
     subdivide and recurse.

     First, calculate a suitable scale based on the coordinates of the
     convex hull.  This is used to get a good cutoff for the subdivision.
     Since it's based on the coordinates in the curve, scaling the curve
     up or down won't affect relative accuracy.  Note that if the scale is
     zero, the convex hull, and thus the curve, has no extent.  */

  scale = fabs(x0) + fabs(x1) + fabs(y0) + fabs(y1);
  if (!scale)
    return 0;

  scale /= 40000000.0;

  /* Deal with the degenerate case to == from.  */
  if (to.x == from.x && to.y == from.y)
    {
      if (x1 - x0 < scale && y1 - y0 < scale)
	return winding_line(from, to, p);
    }
  else
    {
      double dx, dy;
      double nx, ny;
      double d0, d1, d2, d3;

      /* Get the direction vector and the normal vector.  */
      dx = to.x - from.x;
      dy = to.y - from.y;
      d0 = sqrt(dx * dx + dy * dy);
      dx /= d0;
      dy /= d0;
      nx = dy;
      ny = -dx;

      /* Check that the distances along the direction vector are
	 monotone.  */

      d0 = from.x * dx + from.y * dy;
      d1 = c1.x * dx + c1.y * dy;
      d2 = c2.x * dx + c2.y * dy;
      d3 = to.x * dx + to.y * dy;

      if ((d3 > d2 && d2 > d1 && d1 > d0)
	  || (d3 < d2 && d2 < d1 && d1 < d0))
	{
	  /* Check that the control points are close to the straigt line
	     between from and to.  */
	  d0 = to.x * nx + to.y * ny;
	  d1 = c1.x * nx + c1.y * ny;
	  d2 = c2.x * nx + c2.y * ny;

	  if (fabs(d0 - d1) < scale && fabs(d0 - d2) < scale)
	    {
	      /* It's flat enough.  */
	      return winding_line(from, to, p);
	    }
	}
    }

  {
    /* Subdivide.  */
    double_point m, l1, l2, r1, r2;

    m.x = (from.x + to.x + 3 * (c1.x + c2.x)) / 8;
    m.y = (from.y + to.y + 3 * (c1.y + c2.y)) / 8;

    l1.x = (from.x + c1.x) / 2;
    l1.y = (from.y + c1.y) / 2;

    l2.x = (from.x + 2 * c1.x + c2.x) / 4;
    l2.y = (from.y + 2 * c1.y + c2.y) / 4;

    r2.x = (to.x + c2.x) / 2;
    r2.y = (to.y + c2.y) / 2;

    r1.x = (to.x + 2 * c2.x + c1.x) / 4;
    r1.y = (to.y + 2 * c2.y + c1.y) / 4;

    return winding_curve(from, m, l1, l2, p, depth + 1)
           + winding_curve(m, to, r1, r2, p, depth + 1);
  }
}

static int _OPPathGetWindingCount(CGPathRef path, CGPoint point)
{
  int total;
  CGPathElementType type;
  NSInteger count;
  BOOL first;
  CGPoint pts[3];
  CGPoint first_p, last_p;
  NSInteger i;

  total = 0;
  count = [path count];

  if (count == 0)
    return 0;

  type = [path elementTypeAtIndex: 0 points: pts];
  if (type != kCGPathElementMoveToPoint)
    {
      return 0;
    }
  last_p = first_p = pts[0];
  first = NO;

#define D(a) (double_point){a.x,a.y}
  for (i = 1; i < count; i++)
    {
      type = [path elementTypeAtIndex: i points: pts];
      switch(type)
	{
	  case kCGPathElementMoveToPoint:
	    if (!first)
	      {
		total += winding_line(D(last_p), D(first_p), D(point));
	      }
	    last_p = first_p = pts[0];
	    first = NO;
	    break;
	  case kCGPathElementAddLineToPoint:
	    if (first)
	      {
		return 0;
	      }
	    total += winding_line(D(last_p), D(pts[0]), D(point));
	    last_p = pts[0];
	    break;
          case kCGPathElementAddQuadCurveToPoint:
            // FIXME!!!: The winding count for a quad curve is currently
            // unimplemented.
            break;

	  case kCGPathElementAddCurveToPoint:
	    if (first)
	      {
		return 0;
	      }
	    total += winding_curve(D(last_p), D(pts[2]), D(pts[0]), D(pts[1]), D(point), 0);
	    last_p = pts[2];
	    break;
	  case kCGPathElementCloseSubpath:
	    if (first)
	      {
		return 0;
	      }
	    first = YES;
	    total += winding_line(D(last_p), D(first_p), D(point));
	    break;
	  default:
	    return 0;
	}
    }

  if (!first)
    total += winding_line(D(last_p), D(first_p), D(point));
#undef D

  return total / 2;
}

bool CGPathContainsPoint(
  CGPathRef path,
  const CGAffineTransform *m,
  CGPoint point,
  int eoFill)
{
  int sum;

  if ([path count] == 0)
    return NO;

  if (!CGRectContainsPoint(CGPathGetPathBoundingBox(path), point))
    return NO;

  sum = _OPPathGetWindingCount(path, point);
  if (!eoFill)
  {
    return !(sum == 0);
  }
  else
  {
    return ((sum % 2) != 0);
  }
}

void CGPathAddArc(
  CGMutablePathRef path,
  const CGAffineTransform *m,
  CGFloat x,
  CGFloat y,
  CGFloat radius,
  CGFloat startAngle,
  CGFloat endAngle,
  int clockwise)
{
  CGFloat diff;
  CGPoint p0, p1, p2, p3;

  if (clockwise)
    {
      if (startAngle != endAngle)
        {
          while (startAngle <= endAngle)
            endAngle -= 2 * M_PI;
        }

      diff = -M_PI_2;
    }
  else
    {
      if (startAngle != endAngle)
        {
          while (endAngle < startAngle)
            endAngle += 2 * M_PI;
        }
      
      diff = M_PI_2;
    }

  CGPoint center = CGPointMake(x, y);

  p0 = CGPointMake (center.x + radius * cos (startAngle), 
		    center.y + radius * sin (startAngle));
  if ([path count] == 0)
    {
      CGPathMoveToPoint(path, m, p0.x, p0.y);
    }
  else
    {
      CGPoint ps = CGPathGetCurrentPoint(path);
      
      if (p0.x != ps.x || p0.y != ps.y)
        {
          CGPathAddLineToPoint(path, m, p0.x, p0.y);
        }
    }
  
  while ((clockwise) ? (startAngle > endAngle) 
	 : (startAngle < endAngle))
    {
      if ((clockwise) ? (startAngle + diff >= endAngle) 
      : (startAngle + diff <= endAngle))
        {
          CGFloat sin_start = sin (startAngle);
          CGFloat cos_start = cos (startAngle);
          CGFloat sign = (clockwise) ? -1.0 : 1.0;

          p1 = CGPointMake (center.x 
              + radius * (cos_start - KAPPA * sin_start * sign), 
              center.y 
              + radius * (sin_start + KAPPA * cos_start * sign));
          p2 = CGPointMake (center.x 
              + radius * (-sin_start * sign + KAPPA * cos_start),
              center.y 
              + radius * (cos_start * sign + KAPPA * sin_start));
          p3 = CGPointMake (center.x + radius * (-sin_start * sign),
              center.y + radius *   cos_start * sign);

          CGPathAddCurveToPoint(path, m, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
          startAngle += diff;
        }
      else
        {
          CGPoint ps = CGPathGetCurrentPoint(path);
          if (m) ps = CGPointApplyAffineTransform(ps, CGAffineTransformInvert(*m));
          CGFloat tangent = tan ((endAngle - startAngle) / 2);
          CGFloat trad = radius * tangent;
          CGPoint pt = CGPointMake (ps.x - trad * sin (startAngle),
                        ps.y + trad * cos (startAngle));
          CGFloat f = (4.0 / 3.0) / (1.0 + sqrt (1.0 +  (tangent * tangent)));
          
          p1 = CGPointMake (ps.x + (pt.x - ps.x) * f, ps.y + (pt.y - ps.y) * f);
          p3 = CGPointMake(center.x + radius * cos (endAngle),
                   center.y + radius * sin (endAngle));
          p2 = CGPointMake (p3.x + (pt.x - p3.x) * f, p3.y + (pt.y - p3.y) * f);
          CGPathAddCurveToPoint(path, m, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
          break;
      }
  }
}

void CGPathAddArcToPoint(
  CGMutablePathRef path,
  const CGAffineTransform *m,
  CGFloat x1,
  CGFloat y1,
  CGFloat x2,
  CGFloat y2,
  CGFloat radius)
{
  CGFloat dx1, dy1, dx2, dy2;
  CGFloat l, a1, a2;
  CGPoint p;

  p = CGPathGetCurrentPoint(path);
 
  dx1 = p.x - x1;
  dy1 = p.y - y1;
  
  l= dx1*dx1 + dy1*dy1;
  if (l <= 0)
    {
      CGPathAddLineToPoint(path, m, x1, y1);
      return;
    }
  l = 1/sqrt(l);
  dx1 *= l;
  dy1 *= l;
  
  dx2 = x2 - x1;
  dy2 = y2 - y1;

  l = dx2*dx2 + dy2*dy2;
  if (l <= 0)
    {
      CGPathAddLineToPoint(path, m, x1, y1);
      return;
    }
	
  l = 1/sqrt(l);
  dx2 *= l; 
  dy2 *= l;
  
  l = dx1*dx2 + dy1*dy2;
  if (l < -0.999)
    {
      CGPathAddLineToPoint(path, m, x1, y1);
      return;
    }

  l = radius/sin(acos(l));
  p.x = x1 + (dx1 + dx2)*l;
  p.y = y1 + (dy1 + dy2)*l;

  if (dx1 < -1)
    a1 = M_PI;
  else if (dx1 > 1)
    a1 = 0;
  else
    a1 = acos(dx1);
  if (dy1 < 0)
    {   
      a1 = -a1;
    }

  if (dx2 < -1)
    a2 = M_PI;
  else if (dx2 > 1)
    a2 = 0;
  else
    a2 = acos(dx2);
  if (dy2 < 0)
    {   
      a2 = -a2;
    }

  l = dx1*dy2 - dx2*dy1;
  if (l < 0)
    {
      a2 = a2 - M_PI_2;
      a1 = a1 + M_PI_2;
      CGPathAddArc(path, m, p.x, p.y, radius, a1, a2, NO);
    }
  else
    {
      a2 = a2 + M_PI_2;
      a1 = a1 - M_PI_2;
      CGPathAddArc(path, m, p.x, p.y, radius, a1, a2, YES);
    }
}

void CGPathAddCurveToPoint(
  CGMutablePathRef path,
  const CGAffineTransform *m,
  CGFloat cx1,
  CGFloat cy1,
  CGFloat cx2,
  CGFloat cy2,
  CGFloat x,
  CGFloat y)
{
  CGPoint points[3];
  points[0] = CGPointMake(cx1, cy1);
  points[1] = CGPointMake(cx2, cy2);
  points[2] = CGPointMake(x, y);
  if (NULL != m)
  {
    NSUInteger i = 0;
    for (i = 0; i < 3; i++)
    {
      points[i] = CGPointApplyAffineTransform(points[i], *m);
    }
  }
  [(CGMutablePath*)path addElementWithType: kCGPathElementAddCurveToPoint
                                    points: (CGPoint*)&points];
}

void CGPathAddLines(
  CGMutablePathRef path,
  const CGAffineTransform *m,
  const CGPoint points[],
  size_t count)
{
  CGPathMoveToPoint(path, m, points[0].x, points[0].y);
  for (NSUInteger i=1; i<count; i++)
  {
    CGPathAddLineToPoint(path, m, points[i].x, points[i].y);
  }
}

void CGPathAddLineToPoint (
  CGMutablePathRef path,
  const CGAffineTransform *m,
  CGFloat x,
  CGFloat y)
{
  CGPoint point = CGPointMake(x, y);
  if (m)
  {
    point = CGPointApplyAffineTransform(point, *m);
  }
  [(CGMutablePath*)path addElementWithType: kCGPathElementAddLineToPoint
                                    points: &point];
}

void CGPathAddPath(
  CGMutablePathRef path1,
  const CGAffineTransform *m,
  CGPathRef path2)
{
  NSUInteger count = [path2 count];
  for (NSUInteger i=0; i<count; i++)
  {
    CGPoint points[3];
    CGPathElementType type = [path2 elementTypeAtIndex: i points: points];
    if (m)
    {
      for (NSUInteger j=0; j<3; j++)
      {
        // FIXME: transforms unused points
        points[j] = CGPointApplyAffineTransform(points[j], *m);
      }
    }
    [(CGMutablePath*)path1 addElementWithType: type points: points];
  }
}

void CGPathAddQuadCurveToPoint(
  CGMutablePathRef path,
  const CGAffineTransform *m,
  CGFloat cx,
  CGFloat cy,
  CGFloat x,
  CGFloat y)
{
  CGPoint points[2] = {
    CGPointMake(cx, cy),
    CGPointMake(x, y)

  };
  if (m)
  {
    points[0] = CGPointApplyAffineTransform(points[0], *m);
    points[1] = CGPointApplyAffineTransform(points[1], *m);
  }
  [(CGMutablePath*)path addElementWithType: kCGPathElementAddQuadCurveToPoint
                                    points: points];
}

void CGPathAddRect(
  CGMutablePathRef path,
  const CGAffineTransform *m,
  CGRect rect)
{
  CGPathMoveToPoint(path, m, CGRectGetMinX(rect), CGRectGetMinY(rect));
  CGPathAddLineToPoint(path, m, CGRectGetMaxX(rect), CGRectGetMinY(rect));
  CGPathAddLineToPoint(path, m, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
  CGPathAddLineToPoint(path, m, CGRectGetMinX(rect), CGRectGetMaxY(rect));
  CGPathCloseSubpath(path);
}

void CGPathAddRects(
  CGMutablePathRef path,
  const CGAffineTransform *m,
  const CGRect rects[],
  size_t count)
{
  for (NSUInteger i=0; i<count; i++)
  {
    CGPathAddRect(path, m, rects[i]);
  }
}

void CGPathApply(
  CGPathRef path,
  void *info,
  CGPathApplierFunction function)
{
  NSUInteger count = [path count];
  for (NSUInteger i=0; i<count; i++)
  {
    CGPoint points[3];
    CGPathElement e;
    e.type = [path elementTypeAtIndex: i points: points];
    e.points = points;
    function(info, &e);
  }
}

void CGPathMoveToPoint(
  CGMutablePathRef path,
  const CGAffineTransform *m,
  CGFloat x,
  CGFloat y)
{
  CGPoint point = CGPointMake(x, y);
  if (m)
  {
    point = CGPointApplyAffineTransform(point, *m);
  }
  [(CGMutablePath*)path addElementWithType: kCGPathElementMoveToPoint
                                    points: &point];
}

void CGPathCloseSubpath(CGMutablePathRef path)
{
  [(CGMutablePath*)path addElementWithType: kCGPathElementCloseSubpath
                                    points: NULL];
}

void CGPathAddEllipseInRect(
  CGMutablePathRef path,
  const CGAffineTransform *m,
  CGRect aRect)
{
  CGPoint p, p1, p2;
  const CGFloat originx = aRect.origin.x;
  const CGFloat originy = aRect.origin.y;
  const CGFloat width = aRect.size.width;
  const CGFloat height = aRect.size.height;
  const CGFloat hdiff = width / 2 * KAPPA;
  const CGFloat vdiff = height / 2 * KAPPA;
  
  p = CGPointMake(originx + width / 2, originy + height);
  CGPathMoveToPoint(path, m, p.x, p.y);
  
  p = CGPointMake(originx, originy + height / 2);
  p1 = CGPointMake(originx + width / 2 - hdiff, originy + height);
  p2 = CGPointMake(originx, originy + height / 2 + vdiff);
  CGPathAddCurveToPoint(path, m, p1.x, p1.y, p2.x, p2.y, p.x, p.y);
  
  p = CGPointMake(originx + width / 2, originy);
  p1 = CGPointMake(originx, originy + height / 2 - vdiff);
  p2 = CGPointMake(originx + width / 2 - hdiff, originy);
  CGPathAddCurveToPoint(path, m, p1.x, p1.y, p2.x, p2.y, p.x, p.y);
  
  p = CGPointMake(originx + width, originy + height / 2);
  p1 = CGPointMake(originx + width / 2 + hdiff, originy);
  p2 = CGPointMake(originx + width, originy + height / 2 - vdiff);
  CGPathAddCurveToPoint(path, m, p1.x, p1.y, p2.x, p2.y, p.x, p.y);
  
  p = CGPointMake(originx + width / 2, originy + height);
  p1 = CGPointMake(originx + width, originy + height / 2 + vdiff);
  p2 = CGPointMake(originx + width / 2 + hdiff, originy + height);
  CGPathAddCurveToPoint(path, m, p1.x, p1.y, p2.x, p2.y, p.x, p.y);
}

static CGPoint point_on_quad_curve(double t, CGPoint a, CGPoint b, CGPoint c)
{
  double ti = 1.0 - t;
  return CGPointMake(ti * ti * a.x + 2 * ti * t * b.x + t * t * c.x,
                     ti * ti * a.y + 2 * ti * t * b.y + t * t * c.y);
}

static CGPoint point_on_cubic_curve(double t, CGPoint a, CGPoint b, CGPoint c,
			            CGPoint d)
{
  double ti = 1.0 - t;
  return CGPointMake(ti * ti * ti * a.x + 3 * ti * ti * t * b.x
		       + 3 * ti * t * t * c.x + t * t * t * d.x,
		     ti * ti * ti * a.y + 3 * ti * ti * t * b.y
		       + 3 * ti * t * t * c.y + t * t * t * d.y);
}

#define CHECK_MAX(max, p) \
  if (p.x > max.x) max.x = p.x; \
  if (p.y > max.y) max.y = p.y;
#define CHECK_MIN(min, p) \
  if (p.x < min.x) min.x = p.x; \
  if (p.y < min.y) min.y = p.y;
#define CHECK_QUADRATIC_CURVE_EXTREMES(x) \
  t = (p.x - points[0].x) / (p.x - 2*points[0].x + points[1].x); \
  if (t > 0.0 && t < 1.0) \
    { \
      q = point_on_quad_curve(t, p, points[0], points[1]); \
      CHECK_MAX(max, q); \
      CHECK_MIN(min, q); \
    }
#define CHECK_CUBIC_CURVE_EXTREMES(x) \
  t = (p.x * (points[2].x - points[1].x) \
       + points[0].x * (-points[2].x - points[1].x) \
       + points[1].x * points[1].x + points[0].x * points[0].x); \
  if (t >= 0.0) \
    { \
      t = sqrt(t); \
      t0 = (points[1].x - 2 * points[0].x + p.x + t) \
           / (-points[2].x + 3 * points[1].x - 3 * points[0].x + p.x); \
      t1 = (points[1].x - 2 * points[0].x + p.x - t) \
           / (-points[2].x + 3 * points[1].x - 3 * points[0].x + p.x); \
  \
      if (t0 > 0.0 && t0 < 1.0) \
        { \
          q = point_on_cubic_curve(t0, p, points[0], points[1], points[2]); \
          CHECK_MAX(max, q) \
          CHECK_MIN(min, q) \
        } \
      if (t1 > 0.0 && t1 < 1.0) \
        { \
          q = point_on_cubic_curve(t1, p, points[0], points[1], points[2]); \
          CHECK_MAX(max, q) \
          CHECK_MIN(min, q) \
        } \
    }

CGRect CGPathGetPathBoundingBox(CGPathRef path)
{
  CGPoint p;
  CGPoint min, max;

  NSUInteger count = [path count];
  if (count == 0)
    return CGRectZero;

  for (NSUInteger i = 0; i < count; i++)
    {
      CGPoint points[3];
      CGPathElementType type = [path elementTypeAtIndex: i points: points];

      if (i == 0)
        min = max = p = points[0];

      switch (type)
        {
          case kCGPathElementCloseSubpath:
            p = points[0];
            continue;

          case kCGPathElementMoveToPoint:
          case kCGPathElementAddLineToPoint:
            CHECK_MAX(max, points[0]);
            CHECK_MIN(min, points[0]);
            p = points[0];
            break;
          
          case kCGPathElementAddQuadCurveToPoint:
            {
              double t;
              CGPoint q;

              CHECK_MAX(max, points[1]);
              CHECK_MIN(min, points[1]);

              CHECK_QUADRATIC_CURVE_EXTREMES(x);
              CHECK_QUADRATIC_CURVE_EXTREMES(y);
              break;
            }

          case kCGPathElementAddCurveToPoint:
            {
              double t0, t1, t;
              CGPoint q;

              CHECK_MAX(max, points[2]);
              CHECK_MIN(min, points[2]);
              
              CHECK_CUBIC_CURVE_EXTREMES(x);
              CHECK_CUBIC_CURVE_EXTREMES(y);

              p = points[2];
              break;
            }
        }
    }

  return CGRectMake(min.x, min.y, max.x - min.x, max.y - min.y);
}

void CGPathAddRoundedRect(CGMutablePathRef path,
                          const CGAffineTransform *m, CGRect rect,
                          CGFloat cornerWidth, CGFloat cornerHeight)
{
  CGPoint startp, endp, controlp1, controlp2, topLeft, topRight, bottomRight;

  cornerWidth = MIN(cornerWidth, rect.size.width / 2.0);
  cornerHeight = MIN(cornerHeight, rect.size.height / 2.0);

  if (cornerWidth == 0.0 || cornerHeight == 0.0)
  {
    CGPathAddRect(path, m, rect);
    return;
  }

  topLeft = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
  topRight = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
  bottomRight = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));

  startp = CGPointMake(topLeft.x + cornerWidth, topLeft.y);
  endp = CGPointMake(topLeft.x, topLeft.y - cornerHeight);
  controlp1 = CGPointMake(startp.x - (KAPPA * cornerWidth), startp.y);
  controlp2 = CGPointMake(endp.x, endp.y + (KAPPA * cornerHeight));
  CGPathMoveToPoint(path, m, startp.x, startp.y);
  CGPathAddCurveToPoint(path, m, controlp1.x, controlp1.y, controlp2.x, controlp2.y, endp.x, endp.y);

  startp = CGPointMake(rect.origin.x, rect.origin.y + cornerHeight);
  endp = CGPointMake(rect.origin.x + cornerWidth, rect.origin.y);
  controlp1 = CGPointMake(startp.x, startp.y - (KAPPA * cornerHeight));
  controlp2 = CGPointMake(endp.x - (KAPPA * cornerWidth), endp.y);
  CGPathAddLineToPoint(path, m, startp.x, startp.y);
  CGPathAddCurveToPoint(path, m, controlp1.x, controlp1.y, controlp2.x, controlp2.y, endp.x, endp.y);

  startp = CGPointMake(bottomRight.x - cornerWidth, bottomRight.y);
  endp = CGPointMake(bottomRight.x, bottomRight.y + cornerHeight);
  controlp1 = CGPointMake(startp.x + (KAPPA * cornerWidth), startp.y);
  controlp2 = CGPointMake(endp.x, endp.y - (KAPPA * cornerHeight));
  CGPathAddLineToPoint(path, m, startp.x, startp.y);
  CGPathAddCurveToPoint(path, m, controlp1.x, controlp1.y, controlp2.x, controlp2.y, endp.x, endp.y);

  startp = CGPointMake(topRight.x, topRight.y - cornerHeight);
  endp = CGPointMake(topRight.x - cornerWidth, topRight.y);
  controlp1 = CGPointMake(startp.x, startp.y + (KAPPA * cornerHeight));
  controlp2 = CGPointMake(endp.x + (KAPPA * cornerWidth), endp.y);
  CGPathAddLineToPoint(path, m, startp.x, startp.y);
  CGPathAddCurveToPoint(path, m, controlp1.x, controlp1.y, controlp2.x, controlp2.y, endp.x, endp.y);

  CGPathCloseSubpath(path);
}

CGPathRef CGPathCreateWithRect(CGRect rect,
                               const CGAffineTransform *m)
{
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathAddRect(path, m, rect);

  return path;
}
