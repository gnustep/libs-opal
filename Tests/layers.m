#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#else
#include <CoreGraphics/CoreGraphics.h>
#endif

#include <stdio.h>

#define pi 3.14159265358979323846

CGLayerRef makeSampleLayer(CGContextRef ctx){
  CGRect layerBounds = CGRectMake(0,0,50, 50);
  CGLayerRef layer = CGLayerCreateWithContext(ctx, layerBounds.size, NULL);
  CGContextRef layerCtx = CGLayerGetContext(layer);

  CGContextSetRGBFillColor(layerCtx, 1, 1, 0, 0.5);
  CGContextFillRect(layerCtx, layerBounds);
  
  CGContextSetRGBStrokeColor(layerCtx, 0, 0, 0, 0.7);
  CGContextStrokeRect(layerCtx, layerBounds);


  // Draw a smiley
  CGContextBeginPath(layerCtx);
  printf("%d", CGContextIsPathEmpty(layerCtx));
  CGContextMoveToPoint(layerCtx, 14, 35); CGContextAddArc(layerCtx, 10, 35, 4, 0, 2 * pi, 0); CGContextClosePath(layerCtx);
  CGContextMoveToPoint(layerCtx, 44, 35);  CGContextAddArc(layerCtx, 40, 35, 4, 0, 2 * pi, 0); CGContextClosePath(layerCtx);
  CGContextMoveToPoint(layerCtx, 16, 15);  CGContextAddArc(layerCtx, 12, 15, 4, 0, 2 * pi, 0); CGContextClosePath(layerCtx);
  CGContextMoveToPoint(layerCtx, 23, 10);  CGContextAddArc(layerCtx, 19, 10, 4, 0, 2 * pi, 0); CGContextClosePath(layerCtx);
  CGContextMoveToPoint(layerCtx, 29, 8);  CGContextAddArc(layerCtx, 25, 8, 4, 0, 2 * pi, 0); CGContextClosePath(layerCtx);
  CGContextMoveToPoint(layerCtx, 35, 10);  CGContextAddArc(layerCtx, 31, 10, 4, 0, 2 * pi, 0); CGContextClosePath(layerCtx);
  CGContextMoveToPoint(layerCtx, 42, 15);  CGContextAddArc(layerCtx, 38, 15, 4, 0, 2 * pi, 0); CGContextClosePath(layerCtx);

  CGContextSetRGBFillColor(layerCtx, 1, 0, 0, 0.5);
  CGContextSetRGBStrokeColor(layerCtx, 0, 0, 0, 1);
  CGContextDrawPath(layerCtx, kCGPathFillStroke);

  
  return layer;
}

void draw(CGContextRef ctx, CGRect r)
{
  CGContextSetRGBFillColor(ctx, 0, 0, 1, 0.5);
  CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);
  CGContextFillRect(ctx, CGRectMake(10,10,r.size.width - 20, r.size.height - 20));
  CGContextStrokeRect(ctx, CGRectMake(10,10,r.size.width - 20, r.size.height - 20));
  
  // Draw some copies of a layer
  CGLayerRef layer = makeSampleLayer(ctx);
  
  // Draw some rotated faces
  CGContextSaveGState(ctx);
  CGContextTranslateCTM(ctx, 225, 125);
  int i;
  for (i = 0; i < 3; i++) {
    CGContextRotateCTM(ctx, 0.06);
    CGContextDrawLayerInRect(ctx, CGRectMake(-145,-110,290,220), layer);
  }
  CGContextRestoreGState(ctx);



  CGContextDrawLayerInRect(ctx, CGRectMake(80,15,290,220), layer);
  
  CGContextDrawLayerAtPoint(ctx, CGPointMake(100, 170), layer);
  CGContextDrawLayerAtPoint(ctx, CGPointMake(300, 170), layer);

  CGContextDrawLayerAtPoint(ctx, CGPointMake(100, 60), layer);
  CGContextDrawLayerAtPoint(ctx, CGPointMake(150, 16), layer);
  CGContextDrawLayerAtPoint(ctx, CGPointMake(200, 10), layer);
  CGContextDrawLayerAtPoint(ctx, CGPointMake(250, 16), layer);
  CGContextDrawLayerAtPoint(ctx, CGPointMake(300, 60), layer);
  CGLayerRelease(layer); 
}

