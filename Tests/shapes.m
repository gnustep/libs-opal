#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#else
#include <CoreGraphics/CoreGraphics.h>
#endif
#define pi 3.14159265358979323846

extern void frameArc(CGContextRef context, CGRect r, int startAngle, int arcAngle);
extern void paintArc(CGContextRef context, CGRect r, int startAngle, int arcAngle);
extern void frameOval(CGContextRef context, CGRect r);
extern void paintOval(CGContextRef context, CGRect r);
extern void frameRect(CGContextRef context, CGRect r);
extern void paintRect(CGContextRef context, CGRect r);
extern void fillRoundedRect(CGContextRef context, CGRect rect, CGFloat ovalWidth, CGFloat ovalHeight);
extern void strokeRoundedRect(CGContextRef context, CGRect rect, CGFloat ovalWidth, CGFloat ovalHeight);

void draw(CGContextRef ctx, CGRect r)
{
	CGRect bounds = r;
	double a, b;
	int count, k;

	CGContextSetRGBFillColor(ctx, 0, 0, 0, 1);
	CGContextFillRect(ctx, CGRectMake(0, r.size.height / 2, r.size.width, r.size.height / 2));

	// Use a transparency layer for the first shape

        CGContextSetAlpha(ctx, 0.5);
        CGContextBeginTransparencyLayer(ctx, NULL);

	// Calculate the dimensions for an oval inside the bounding box
	a = 0.9 * bounds.size.width/4;
	b = 0.3 * bounds.size.height/2;
	count = 5;

	// Set the fill color to a partially transparent blue
	CGContextSetRGBFillColor(ctx, 0, 0, 1, 1);

	// Set the stroke color to an opaque black
	CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);

	// Set the line width to be used, in user space units.
	CGContextSetLineWidth(ctx, 3);

	// Save the conexts state because we are going to be moving the origin and
	// rotating context for drawing, but we would like to restore the current
	// state before drawing the next image.
	CGContextSaveGState(ctx);

	// Move the origin to the middle of the first image (left side) to draw.
	CGContextTranslateCTM(ctx, bounds.size.width/4, bounds.size.height/2);
  CGColorRef shadowColor = CGColorCreateGenericRGB(0, 0.2, 0.3, 0.75);
  
	// Draw "count" ovals, rotating the context around the newly translated origin
	// 1/count radians after drawing each oval
	for (k = 0; k < count; k++)
	{
    CGContextSaveGState(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeMake(6.0,-6.0), 2.0, shadowColor);
		// Paint the oval with the fill color
		paintOval(ctx, CGRectMake(-a, -b, 2 * a, 2 * b));
    CGContextRestoreGState(ctx);
      
		// Frame the oval with the stroke color
		frameOval(ctx, CGRectMake(-a, -b, 2 * a, 2 * b));

		// Rotate the context around the center of the image
		CGContextRotateCTM(ctx, pi / count);
	}
	// Restore the saved state to a known state for dawing the next image
	CGContextRestoreGState(ctx);
  CGColorRelease(shadowColor);
  
	// End the transparency layer
  CGContextEndTransparencyLayer(ctx);



	// Calculate a bounding box for the rounded rect
	a = 0.9 * bounds.size.width/4;
	b = 0.3 * bounds.size.height/2;
	count = 5;

	// Set the fill color to a partially transparent red
	CGContextSetRGBFillColor(ctx, 1, 0, 0, 0.5);

	// Set the stroke color to an opaque black
	CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);

	// Set the line width to be used, in user space units.
	CGContextSetLineWidth(ctx, 3);

	// Save the conexts state because we are going to be moving the origin and
	// rotating context for drawing, but we would like to restore the current
	// state before drawing the next image.
	CGContextSaveGState(ctx);

	// Move the origin to the middle of the second image (right side) to draw.
	CGContextTranslateCTM(ctx, bounds.size.width/4 + bounds.size.width/2, bounds.size.height/2);

	for (k = 0; k < count; k++)
	{
		// Fill then stroke the rounding rect, otherwise the fill would cover the stroke
		fillRoundedRect(ctx, CGRectMake(-a, -b, 2 * a, 2 * b), 20, 20);
		strokeRoundedRect(ctx, CGRectMake(-a, -b, 2 * a, 2 * b), 20, 20);
		// Rotate the context for the next rounded rect
		CGContextRotateCTM(ctx, pi / count);
	}
	CGContextRestoreGState(ctx);       
}

