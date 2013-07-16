#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#else
#include <CoreGraphics/CoreGraphics.h>
#endif

#include <Foundation/Foundation.h>

static void assert_close(int expected, int actual)
{
    assert(abs(expected - actual) < 10);
}

void draw(CGContextRef ctx, CGRect rect)
{
    CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    
    /* cairo only supports the kCGImageAlphaPremultipliedFirst format */
    CGContextRef bmp = CGBitmapContextCreate(NULL, 2, 2, 8, 8, cs, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(cs);
    
    const double r = 1.0;
    const double g = 0.9;
    const double b = 0.8;
    const double a = 0.7;
    
    /* fill the bottom-left pixel with a semitransparent cream pastel color */
    CGContextSetRGBFillColor(bmp, r, g, b, a);
    CGContextFillRect(bmp, CGRectMake(0, 0, 1, 1));
    
    {
        unsigned char * bytes = CGBitmapContextGetData(bmp);
        
        /* top row, left column */
        assert_close(0, bytes[0]); // r * a
        assert_close(0, bytes[1]); // g * a
        assert_close(0, bytes[2]); // b * a
        assert_close(0, bytes[3]); // a
        
        /* top row, right column */
        assert_close(0, bytes[4]); // r * a
        assert_close(0, bytes[5]); // g * a
        assert_close(0, bytes[6]); // b * a
        assert_close(0, bytes[7]); // a
        
        /* bottom row, left column */
        assert_close(255 * r * a, bytes[8]); // r * a
        assert_close(255 * g * a, bytes[9]); // g * a
        assert_close(255 * b * a, bytes[10]); // b * a
        assert_close(255 * a,     bytes[11]); // a
        
        /* bottom row, right column */
        assert_close(0, bytes[12]); // r * a
        assert_close(0, bytes[13]); // g * a
        assert_close(0, bytes[14]); // b * a
        assert_close(0, bytes[15]); // a
    }
    
    CGContextSetRGBFillColor(ctx, 0, 0, 0, 1);
    CGContextFillRect(ctx, rect);
                             
    CGImageRef img = CGBitmapContextCreateImage(bmp);
    CGContextRelease(bmp);
    
    CGContextDrawImage(ctx, rect, img);
    CGImageRelease(img);
}
