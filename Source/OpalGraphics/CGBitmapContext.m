/** <title>CGBitmapContext</title>
 
 <abstract>C Interface to graphics drawing library</abstract>
 
 Copyright <copy>(C) 2009 Free Software Foundation, Inc.</copy>

 Author: Eric Wasylishen
 Date: January 2010
  
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

#include "CoreGraphics/CGBitmapContext.h"
#include "CGContext-private.h" 

#import "OPImageConversion.h"

#import "OPLogging.h"

@interface CGBitmapContext : CGContext
{
@public
  BOOL isCairoDrawingIntoUserBuffer;
  CGColorSpaceRef cs;
  size_t userBufferBitsPerComponent;
  size_t userBufferBytesPerRow;
  void *userBuffer;
  void *releaseInfo;
  CGBitmapContextReleaseDataCallback cb;
  CGBitmapInfo userBufferBitmapInfo;
}

/**
 * Creates a bitmap editing context. Since cairo only supports drawing in a few formats,
 * usually we'll need two memory buffers, one for cairo to draw in and one for the user to 
 * read from.
 */
- (id)       initWithSurface: (cairo_surface_t *)target
isCairoDrawingIntoUserBuffer: (BOOL)isCairoDrawingIntoUserBuffer
        userBufferColorspace: (CGColorSpaceRef)colorspace
  userBufferBitsPerComponent: (size_t)userBufferBitsPerComponent
       userBufferBytesPerRow: (size_t)userBufferBytesPerRow
        userBufferBitmapInfo: (CGBitmapInfo)bitmapInfo
       userBufferReleaseInfo: (void*)i
                  userBuffer: (void*)userBuffer
             releaseCallback: (CGBitmapContextReleaseDataCallback)releaseCallback;

@end

@implementation CGBitmapContext

static BOOL isFormatNativelySupportedByCairo(
  CGBitmapInfo info, 
  CGColorSpaceRef cs, 
  size_t bitsPerComponent, 
  size_t width,
  size_t bytesPerRow,
  cairo_format_t *outFormat)
{
  *outFormat = CAIRO_FORMAT_INVALID;

  if (0 != (info & kCGBitmapFloatComponents))
  {
    return NO;
  }
  
  // NOTE: kCGBitmapByteOrderDefault means big-endian (a.k.a unpacked)
  // cairo can only draw into native-endian integer-packed pixels
  const int order = info & kCGBitmapByteOrderMask;
  if (!((NSHostByteOrder() == NS_LittleEndian) && (order == kCGBitmapByteOrder32Little))
    && !((NSHostByteOrder() == NS_BigEndian) && (order == kCGBitmapByteOrder32Big 
						 || order == kCGBitmapByteOrderDefault)))
  {
    return NO;
  }

  const int alpha = info &  kCGBitmapAlphaInfoMask;
  const CGColorSpaceModel model = CGColorSpaceGetModel(cs);
  const size_t numComps = CGColorSpaceGetNumberOfComponents(cs);
  
  cairo_format_t format = CAIRO_FORMAT_INVALID;

  if (bitsPerComponent == 8
      && numComps == 3
      && model == kCGColorSpaceModelRGB
      && alpha == kCGImageAlphaPremultipliedFirst)
  {
  	format = CAIRO_FORMAT_ARGB32;
  }
  else if (bitsPerComponent == 8
      && numComps == 3
      && model == kCGColorSpaceModelRGB
      && alpha == kCGImageAlphaNoneSkipFirst)
  {
  	format = CAIRO_FORMAT_RGB24;
  }
  else if (bitsPerComponent == 8 && alpha == kCGImageAlphaOnly)
  {
  	format = CAIRO_FORMAT_A8;
  }
  else if (bitsPerComponent == 1 && alpha == kCGImageAlphaOnly)
  {
  	format = CAIRO_FORMAT_A1;
  }
  else
  {
    return NO;
  }

  // Now that we have the format we're going to use, check that the stride is acceptable
  // to cairo.

  if (cairo_format_stride_for_width(format, width) != bytesPerRow)
  {
    return NO;
  }
   
  *outFormat = format; 
  return YES;
}

- (id)       initWithSurface: (cairo_surface_t *)target
isCairoDrawingIntoUserBuffer: (BOOL)isIntoUserBuffer
        userBufferColorspace: (CGColorSpaceRef)colorspace
  userBufferBitsPerComponent: (size_t)bitsPerComponent
       userBufferBytesPerRow: (size_t)bytesPerRow
        userBufferBitmapInfo: (CGBitmapInfo)bitmapInfo
       userBufferReleaseInfo: (void*)i
                  userBuffer: (void*)aUserBuffer
             releaseCallback: (CGBitmapContextReleaseDataCallback)releaseCallback
{
  CGSize size = CGSizeMake(cairo_image_surface_get_width(target),
                           cairo_image_surface_get_height(target));

  if (nil == (self = [super initWithSurface: target size: size]))
  {
    return nil;
  }
  self->isCairoDrawingIntoUserBuffer = isIntoUserBuffer;
  self->cs = CGColorSpaceRetain(colorspace);
  self->userBufferBitsPerComponent = bitsPerComponent;
  self->userBufferBytesPerRow =  bytesPerRow;
  self->userBuffer = aUserBuffer;
  self->releaseInfo = i;
  self->cb = releaseCallback;
  self->userBufferBitmapInfo = bitmapInfo;
  return self;
}

- (void) dealloc
{
  CGContextFlush(self);
  CGColorSpaceRelease(cs);
  if (cb)
  {
  	cb(releaseInfo, userBuffer);
  }
  [super dealloc];    
}

- (void*) data
{
  CGContextFlush(self);

  if (!isCairoDrawingIntoUserBuffer)
  {
    cairo_surface_t *srcCairoSurface = cairo_get_target(self->ct);
    const unsigned char *srcData = cairo_image_surface_get_data(srcCairoSurface);  
    const size_t srcWidth = CGBitmapContextGetWidth(self);
    const size_t srcHeight = CGBitmapContextGetHeight(self);
    const size_t srcBitsPerComponent = 8;
    const size_t srcBitsPerPixel = 32;
    const size_t srcBytesPerRow = cairo_format_stride_for_width(cairo_image_surface_get_format(srcCairoSurface), srcWidth);
    const CGBitmapInfo srcBitmapInfo = kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst;
    const CGColorSpaceRef srcColorSpace = CGColorSpaceCreateDeviceRGB();
    const CGColorRenderingIntent srcIntent = kCGRenderingIntentDefault;

    unsigned char *dstData = userBuffer;
    const size_t dstBitsPerComponent = CGBitmapContextGetBitsPerComponent(self);
    const size_t dstBitsPerPixel = CGBitmapContextGetBitsPerPixel(self);
    const size_t dstBytesPerRow = CGBitmapContextGetBytesPerRow(self);
    
    CGBitmapInfo dstBitmapInfo = CGBitmapContextGetBitmapInfo(self);
    const CGColorSpaceRef dstColorSpace = CGBitmapContextGetColorSpace(self);

    OPImageConvert(
      dstData, srcData,
      srcWidth, srcHeight,
      dstBitsPerComponent, srcBitsPerComponent,
      dstBitsPerPixel, srcBitsPerPixel,
      dstBytesPerRow, srcBytesPerRow,
      dstBitmapInfo, srcBitmapInfo,
      dstColorSpace, srcColorSpace,
      srcIntent);
  }

  return userBuffer;
}

@end


CGContextRef CGBitmapContextCreate(
  void *data,
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bytesPerRow,
  CGColorSpaceRef cs,
  CGBitmapInfo info)
{
  OPLOGCALL("ctx, %p, %d, %d, %d, %d, <colorspace>, <bitmapinfo>",
            data, width, height, bitsPerComponent, bytesPerRow)
  CGContextRef r = CGBitmapContextCreateWithData(data, width, height, 
            bitsPerComponent, bytesPerRow, cs, info, NULL, NULL);
  OPRESTORELOGGING()
  return r;
}

static void OPBitmapDataReleaseCallback(void *info, void *data)
{
  free(data);
}


static void checkSurf(cairo_surface_t *surf)
{
  cairo_status_t status = cairo_surface_status(surf);
  const char *statusString = cairo_status_to_string(status);

  if (CAIRO_STATUS_SUCCESS != status)
  {
    printf("surf status: %s", statusString);
  }
}

CGContextRef CGBitmapContextCreateWithData(
  void *data,
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bytesPerRow,
  CGColorSpaceRef cs,
  CGBitmapInfo info,
  CGBitmapContextReleaseDataCallback callback,
  void *releaseInfo)
{
  OPLOGCALL("ctx, %p, %d, %d, %d, %d, <colorspace>, <bitmapinfo>, "
            "<callback>, <releaseinfo>",
            data, width, height, bitsPerComponent, bytesPerRow)
  cairo_format_t format = CAIRO_FORMAT_INVALID;
  cairo_surface_t *surf;  

  // Create the user requested buffer
  if (data == NULL)
  {
      data = calloc(height * bytesPerRow, 1); // FIXME: checks
      callback = (CGBitmapContextReleaseDataCallback)OPBitmapDataReleaseCallback;
  }

  // Set up the user-requested surface
  const BOOL nativeCairoSupport = isFormatNativelySupportedByCairo(info, cs, bitsPerComponent, width, bytesPerRow, &format);
  if (nativeCairoSupport)
  {
    // Cairo can draw directly into the buffer format the caller provided or requested
    surf = cairo_image_surface_create_for_data(data, format, width, height, bytesPerRow);

    NSDebugLLog(@"Opal", @"CGBitmapContext: using native drawing");
  }
  else
  {
    // Cairo can't draw into the buffer the user provided or requested. Allocate a temporary
    // ARGB32 buffer.
    format = CAIRO_FORMAT_ARGB32;

    const size_t cairoBytesPerRow = cairo_format_stride_for_width(format, width);
    void *cairoData = calloc(height * cairoBytesPerRow, 1);
    surf = cairo_image_surface_create_for_data(cairoData, format, width, height, cairoBytesPerRow);    

    NSDebugLLog(@"Opal", @"CGBitmapContext: using drawing through buffer");
  }
    
  checkSurf(surf);

  OPRESTORELOGGING()
  return [[CGBitmapContext alloc] initWithSurface: surf
                     isCairoDrawingIntoUserBuffer: nativeCairoSupport
                             userBufferColorspace: cs
                       userBufferBitsPerComponent: bitsPerComponent
                            userBufferBytesPerRow: bytesPerRow
                             userBufferBitmapInfo: info
                            userBufferReleaseInfo: releaseInfo                            
                                       userBuffer: data
		                              releaseCallback: callback];
}


CGImageAlphaInfo CGBitmapContextGetAlphaInfo(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    return ((CGBitmapContext *)ctx)->userBufferBitmapInfo & kCGBitmapAlphaInfoMask;
  }
  return kCGImageAlphaNone;
}

CGBitmapInfo CGBitmapContextGetBitmapInfo(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    return ((CGBitmapContext *)ctx)->userBufferBitmapInfo;
  }
  return 0;
}

size_t CGBitmapContextGetBitsPerComponent(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
	  return ((CGBitmapContext *)ctx)->userBufferBitsPerComponent;
  }
  return 0;
}

size_t CGBitmapContextGetBitsPerPixel(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
  	  size_t colorComps = CGColorSpaceGetNumberOfComponents(((CGBitmapContext *)ctx)->cs);
      size_t alphaComps = 0;

      if (CGBitmapContextGetAlphaInfo(ctx) != kCGImageAlphaNone)
      {
        alphaComps = 1;
      }
      
      size_t bitsPerComp = CGBitmapContextGetBitsPerComponent(ctx);
      return bitsPerComp * (colorComps + alphaComps); 
  }
  return 0;
}

size_t CGBitmapContextGetBytesPerRow(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    return ((CGBitmapContext *)ctx)->userBufferBytesPerRow; 
  }
  return 0;
}

CGColorSpaceRef CGBitmapContextGetColorSpace(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
  	return ((CGBitmapContext*)ctx)->cs;
  }
  return nil;
}

void *CGBitmapContextGetData(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    return [(CGBitmapContext *)ctx data];
  }
  return 0;
}

size_t CGBitmapContextGetHeight(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    return cairo_image_surface_get_height(cairo_get_target(ctx->ct));
  }
  return 0;
}

size_t CGBitmapContextGetWidth(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    return cairo_image_surface_get_width(cairo_get_target(ctx->ct));
  }
  return 0;
}

static void OpalReleaseContext(void *info, const void *data, size_t size)
{
  CGContextRelease(info);
}

CGImageRef CGBitmapContextCreateImage(CGContextRef ctx)
{
  OPLOGCALL("ctx")
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    // FIXME: Use the cairo format

    CGDataProviderRef dp = CGDataProviderCreateWithData(
      CGContextRetain(ctx),
      CGBitmapContextGetData(ctx),
      CGBitmapContextGetBytesPerRow(ctx) * CGBitmapContextGetHeight(ctx),
      OpalReleaseContext
    );
    
    CGImageRef img = CGImageCreate(
      CGBitmapContextGetWidth(ctx), 
      CGBitmapContextGetHeight(ctx), 
      CGBitmapContextGetBitsPerComponent(ctx),
      CGBitmapContextGetBitsPerPixel(ctx),
      CGBitmapContextGetBytesPerRow(ctx),
      CGBitmapContextGetColorSpace(ctx),
      CGBitmapContextGetBitmapInfo(ctx),
      dp,
      NULL,
      true,
      kCGRenderingIntentDefault
    );
    
    CGDataProviderRelease(dp);
    OPRESTORELOGGING()
    return img;
  }
  OPRESTORELOGGING()
  return nil;
}
