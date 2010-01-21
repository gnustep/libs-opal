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


#include "CoreGraphics/CGPDFContext.h"
#include "CoreGraphics/CGDataConsumer.h"
#include "CGContext-private.h"

#include <CoreFoundation/CoreFoundation.h>
#include <cairo.h>
#include <cairo-pdf.h>
#include "opal.h"

/* Constants */

const CFStringRef kCGPDFContextAuthor = CFSTR("kCGPDFContextAuthor");
const CFStringRef kCGPDFContextCreator = CFSTR("kCGPDFContextCreator");
const CFStringRef kCGPDFContextTitle = CFSTR("kCGPDFContextTitle");
const CFStringRef kCGPDFContextOwnerPassword = CFSTR("kCGPDFContextOwnerPassword");
const CFStringRef kCGPDFContextUserPassword = CFSTR("kCGPDFContextUserPassword");
const CFStringRef kCGPDFContextAllowsPrinting = CFSTR("kCGPDFContextAllowsPrinting");
const CFStringRef kCGPDFContextAllowsCopying = CFSTR("kCGPDFContextAllowsCopying");
const CFStringRef kCGPDFContextOutputIntent = CFSTR("kCGPDFContextOutputIntent");
const CFStringRef kCGPDFContextOutputIntents = CFSTR("kCGPDFContextOutputIntents");
const CFStringRef kCGPDFContextSubject = CFSTR("kCGPDFContextSubject");
const CFStringRef kCGPDFContextKeywords = CFSTR("kCGPDFContextKeywords");
const CFStringRef kCGPDFContextEncryptionKeyLength = CFSTR("kCGPDFContextEncryptionKeyLength");

const CFStringRef kCGPDFContextMediaBox = CFSTR("kCGPDFContextMediaBox");
const CFStringRef kCGPDFContextCropBox = CFSTR("kCGPDFContextCropBox");
const CFStringRef kCGPDFContextBleedBox = CFSTR("kCGPDFContextBleedBox");
const CFStringRef kCGPDFContextTrimBox = CFSTR("kCGPDFContextTrimBox");
const CFStringRef kCGPDFContextArtBox = CFSTR("kCGPDFContextArtBox");

const CFStringRef kCGPDFXOutputIntentSubtype = CFSTR("kCGPDFXOutputIntentSubtype");
const CFStringRef kCGPDFXOutputConditionIdentifier = CFSTR("kCGPDFXOutputConditionIdentifier");
const CFStringRef kCGPDFXOutputCondition = CFSTR("kCGPDFXOutputCondition");
const CFStringRef kCGPDFXRegistryName = CFSTR("kCGPDFXRegistryName");
const CFStringRef kCGPDFXInfo = CFSTR("kCGPDFXInfo");
const CFStringRef kCGPDFXDestinationOutputProfile = CFSTR("kCGPDFXDestinationOutputProfile");

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
