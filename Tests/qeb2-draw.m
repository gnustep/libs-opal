/*
	File:		myDraw.m
	
	Description:	Quartz 2D early bird sample from WWDC 2001

	Author:		DH

	Copyright: 	© Copyright 2000 Apple Computer, Inc. All rights reserved.
	
	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
				("Apple") in consideration of your agreement to the following terms, and your
				use, installation, modification or redistribution of this Apple software
				constitutes acceptance of these terms.  If you do not agree with these terms,
				please do not use, install, modify or redistribute this Apple software.

				In consideration of your agreement to abide by the following terms, and subject
				to these terms, Apple grants you a personal, non-exclusive license, under Apple’s
				copyrights in this original Apple software (the "Apple Software"), to use,
				reproduce, modify and redistribute the Apple Software, with or without
				modifications, in source and/or binary forms; provided that if you redistribute
				the Apple Software in its entirety and without modifications, you must retain
				this notice and the following text and disclaimers in all such redistributions of
				the Apple Software.  Neither the name, trademarks, service marks or logos of
				Apple Computer, Inc. may be used to endorse or promote products derived from the
				Apple Software without specific prior written permission from Apple.  Except as
				expressly stated in this notice, no other rights or licenses, express or implied,
				are granted by Apple herein, including but not limited to any patent rights that
				may be infringed by your derivative works or by other works in which the Apple
				Software may be incorporated.

				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
				WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
				PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
				COMBINATION WITH YOUR PRODUCTS.

				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
				CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
				GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
				ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
				OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
				(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
				ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
				
	Change History (most recent first):

*/


/*
 *  myDraw.m
 *
 *  Copyright (c) 2001 Apple Computer, Inc. All rights reserved.
 *
 */
 
#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#else
#include <CoreGraphics/CoreGraphics.h>
#endif

#define kNumOfExamples 4
#define PI 3.14159265358979323846

/*
 * myDraw is called whenever the view is updated.
 * context - CG context to draw into
 * windowRect - rectangle defining the window rectangle
 */ 

void drawRandomPaths(CGContextRef context, int w, int h)
{
    int i;
    for (i = 0; i < 20; i++) {
        int numberOfSegments = rand() % 8;
        int j;
        CGFloat sx, sy;
        
        CGContextBeginPath(context);
        sx = rand()%w; sy = rand()%h;
        CGContextMoveToPoint(context, rand()%w, rand()%h);
        for (j = 0; j < numberOfSegments; j++) {
            if (j % 2) {
                CGContextAddLineToPoint(context, rand()%w, rand()%h);
            }
            else {
                CGContextAddCurveToPoint(context, rand()%w, rand()%h,  
                    rand()%w, rand()%h,  rand()%h, rand()%h);
            }
        }
        if(i % 2) {
            CGContextAddCurveToPoint(context, rand()%w, rand()%h,
                    rand()%w, rand()%h,  sx, sy);
            CGContextClosePath(context);
            CGContextSetRGBFillColor(context, (CGFloat)(rand()%256)/255, 
                    (CGFloat)(rand()%256)/255, (CGFloat)(rand()%256)/255, 
                    (CGFloat)(rand()%256)/255);
            CGContextFillPath(context);
        }
        else {
            CGContextSetLineWidth(context, (rand()%10)+2);
            CGContextSetRGBStrokeColor(context, (CGFloat)(rand()%256)/255, 
                    (CGFloat)(rand()%256)/255, (CGFloat)(rand()%256)/255, 
                    (CGFloat)(rand()%256)/255);
            CGContextStrokePath(context);
        }
    }
}

void draw(CGContextRef context, CGRect contextRect)
{
    int i;
    int w, h;
    static int n = 0;
    
    w = contextRect.size.width;
    h = contextRect.size.height;
    
    switch (n) {
    case 0:
        // Draw random rectangles (some stroked some filled)
        for (i = 0; i < 20; i++) {
            if(i % 2) {
                CGContextSetRGBFillColor(context, (CGFloat)(rand()%256)/255, 
                        (CGFloat)(rand()%256)/255, (CGFloat)(rand()%256)/255, 
                        (CGFloat)(rand()%256)/255);
                CGContextFillRect(context, CGRectMake(rand()%w, rand()%h, rand()%w, rand()%h));
            }
            else {
                CGContextSetLineWidth(context, (rand()%10)+2);
                CGContextSetRGBStrokeColor(context, (CGFloat)(rand()%256)/255, 
                        (CGFloat)(rand()%256)/255, (CGFloat)(rand()%256)/255, 
                        (CGFloat)(rand()%256)/255);
                CGContextStrokeRect(context, CGRectMake(rand()%w, rand()%h, rand()%w, rand()%h));
            }
        }
        break;
    case 1:
        // Draw random circles (some stroked, some filled)
        for (i = 0; i < 20; i++) {
            CGContextBeginPath(context);
            CGContextAddArc(context, rand()%w, rand()%h, rand()%((w>h) ? h : w), 0, 2*PI, 0);
            CGContextClosePath(context);

            if(i % 2) {
                CGContextSetRGBFillColor(context, (CGFloat)(rand()%256)/255, 
                        (CGFloat)(rand()%256)/255, (CGFloat)(rand()%256)/255, 
                        (CGFloat)(rand()%256)/255);
                CGContextFillPath(context);
            }
            else {
                CGContextSetLineWidth(context, (rand()%10)+2);
                CGContextSetRGBStrokeColor(context, (CGFloat)(rand()%256)/255, 
                        (CGFloat)(rand()%256)/255, (CGFloat)(rand()%256)/255, 
                        (CGFloat)(rand()%256)/255);
                CGContextStrokePath(context);
            }
        }
        break;
    case 2:
        drawRandomPaths(context, w, h);
        break;
    case 3:
        /* Clipping example - draw random path through a circular clip */
        CGContextBeginPath(context);
        CGContextAddArc(context, w/2, h/2, ((w>h) ? h : w)/2, 0, 2*PI, 0);
        CGContextClosePath(context);
        CGContextClip(context);
        
        // Draw something into the clip
        drawRandomPaths(context, w, h);
        
        // Draw an clip path on top as a black stroked circle.
        CGContextBeginPath(context);
        CGContextAddArc(context, w/2, h/2, ((w>h) ? h : w)/2, 0, 2*PI, 0);
        CGContextClosePath(context);
        CGContextSetLineWidth(context, 1);
        CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
        CGContextStrokePath(context);
        break;
        
    default:
        break;
    }
    
    n = ((n+1) % kNumOfExamples);
}
