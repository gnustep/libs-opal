/** <title>CGPDFContext</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen <ewasylishen@gmail.com>
   Date: January, 2010

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

#include <Foundation/NSString.h>
#include "CoreGraphics/CGPDFContext.h"
#include "CoreGraphics/CGDataConsumer.h"
#include "CGContext-private.h"

#include <CoreFoundation/CoreFoundation.h>
#include <cairo.h>
#include <cairo-pdf.h>
#include "opal.h"

/* Constants */

const CFStringRef kCGPDFContextAuthor = @"kCGPDFContextAuthor";
const CFStringRef kCGPDFContextCreator = @"kCGPDFContextCreator";
const CFStringRef kCGPDFContextTitle = @"kCGPDFContextTitle";
const CFStringRef kCGPDFContextOwnerPassword = @"kCGPDFContextOwnerPassword";
const CFStringRef kCGPDFContextUserPassword = @"kCGPDFContextUserPassword";
const CFStringRef kCGPDFContextAllowsPrinting = @"kCGPDFContextAllowsPrinting";
const CFStringRef kCGPDFContextAllowsCopying = @"kCGPDFContextAllowsCopying";
const CFStringRef kCGPDFContextOutputIntent = @"kCGPDFContextOutputIntent";
const CFStringRef kCGPDFContextOutputIntents = @"kCGPDFContextOutputIntents";
const CFStringRef kCGPDFContextSubject = @"kCGPDFContextSubject";
const CFStringRef kCGPDFContextKeywords = @"kCGPDFContextKeywords";
const CFStringRef kCGPDFContextEncryptionKeyLength = @"kCGPDFContextEncryptionKeyLength";

const CFStringRef kCGPDFContextMediaBox = @"kCGPDFContextMediaBox";
const CFStringRef kCGPDFContextCropBox = @"kCGPDFContextCropBox";
const CFStringRef kCGPDFContextBleedBox = @"kCGPDFContextBleedBox";
const CFStringRef kCGPDFContextTrimBox = @"kCGPDFContextTrimBox";
const CFStringRef kCGPDFContextArtBox = @"kCGPDFContextArtBox";

const CFStringRef kCGPDFXOutputIntentSubtype = @"kCGPDFXOutputIntentSubtype";
const CFStringRef kCGPDFXOutputConditionIdentifier = @"kCGPDFXOutputConditionIdentifier";
const CFStringRef kCGPDFXOutputCondition = @"kCGPDFXOutputCondition";
const CFStringRef kCGPDFXRegistryName = @"kCGPDFXRegistryName";
const CFStringRef kCGPDFXInfo = @"kCGPDFXInfo";
const CFStringRef kCGPDFXDestinationOutputProfile = @"kCGPDFXDestinationOutputProfile";

/* Functions */

void CGPDFContextAddDestinationAtPoint(
  CGContextRef ctx,
  CFStringRef name,
  CGPoint point)
{
  errlog("CGPDFContextAddDestinationAtPoint not supported.");
}

void CGPDFContextBeginPage(CGContextRef ctx, CFDictionaryRef pageInfo)
{
  // FIXME: Not sure what this should do. Nothing?
}

void CGPDFContextClose(CGContextRef ctx)
{
  cairo_status_t cret;
  cairo_surface_finish(cairo_get_target(ctx->ct));
  
  cret = cairo_status(ctx->ct);
  if (cret) {
    errlog("%s:%d: CGPDFContextClose status: %s\n",
           __FILE__, __LINE__, cairo_status_to_string(cret));
    return;
  }
}

cairo_status_t opal_CGPDFContextWriteFunction(
  void *closure,
  unsigned char *data,
  unsigned int length)
{
  CGDataConsumerRef consumer = (CGDataConsumerRef)closure;
  // FIXME: send the data to consumer
  return CAIRO_STATUS_SUCCESS;
}

CGContextRef CGPDFContextCreate(
  CGDataConsumerRef consumer,
  const CGRect *mediaBox,
  CFDictionaryRef *auxiliaryInfo)
{
  CGRect box;
  if (mediaBox == NULL) {
    box = CGRectMake(0, 0, 8.5 * 72, 11 * 72);
  } else {
    box = *mediaBox;
  }
  
  //FIXME: We ignore the origin of mediaBox.. is that correct?
  
  cairo_surface_t *surf = cairo_pdf_surface_create_for_stream(
    opal_CGPDFContextWriteFunction,
    consumer,
    box.size.width,
    box.size.height);
  
  CGContextRef ctx = opal_new_CGContext(surf, box.size);
  return ctx;
}

CGContextRef CGPDFContextCreateWithURL(
  CFURLRef url,
  const CGRect *mediaBox,
  CFDictionaryRef auxiliaryInfo)
{
  const char *path; 
  CGRect box;
  if (mediaBox == NULL) {
    box = CGRectMake(0, 0, 8.5 * 72, 11 * 72);
  } else {
    box = *mediaBox;
  }
  
  //FIXME: We ignore the origin of mediaBox.. is that correct?
  
  //FIXME: Use system native path style?
  CFStringRef pathString = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
  int length = CFStringGetMaximumSizeOfFileSystemRepresentation(pathString);
  path = malloc(length);
  
  if (!CFStringGetFileSystemRepresentation(pathString, path, length)) {
     free(path);
     errlog("%s:%d: CFStringGetFileSystemRepresentation failed\n",
           __FILE__, __LINE__);
     return NULL; 
  }
  
  cairo_surface_t *surf = cairo_pdf_surface_create(
    path,
    box.size.width,
    box.size.height);
  free(path);
  
  CGContextRef ctx = opal_new_CGContext(surf, box.size);
  return ctx;
}

void CGPDFContextEndPage(CGContextRef ctx)
{
  cairo_status_t cret;
  cairo_show_page(ctx->ct);
  
  cret = cairo_status(ctx->ct);
  if (cret) {
    errlog("%s:%d: CGPDFContextEndPage status: %s\n",
           __FILE__, __LINE__, cairo_status_to_string(cret));
    return;
  }
}

void CGPDFContextSetDestinationForRect(
  CGContextRef ctx,
  CFStringRef name,
  CGRect rect)
{
  errlog("CGPDFContextSetDestinationForRect not supported.");
}

void CGPDFContextSetURLForRect(CGContextRef ctx, CFURLRef url, CGRect rect)
{
  errlog("CGPDFContextSetURLForRect not supported.");
}
