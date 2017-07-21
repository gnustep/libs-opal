/** <title>CGPDFDocument</title>
 
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
#include "CoreGraphics/CGPDFDocument.h"

CGPDFDocumentRef CGPDFDocumentCreateWithProvider(CGDataProviderRef provider)
{
  return nil;
}

CGPDFDocumentRef CGPDFDocumentCreateWithURL(CFURLRef url)
{
  return nil;
}

CGPDFDocumentRef CGPDFDocumentRetain(CGPDFDocumentRef document)
{
  return nil;
}

void CGPDFDocumentRelease(CGPDFDocumentRef document)
{
  
}

int CGPDFDocumentGetNumberOfPages(CGPDFDocumentRef document)
{
  return 0;
}

CGRect CGPDFDocumentGetMediaBox(CGPDFDocumentRef document, int page)
{
  return CGRectNull;
}

CGRect CGPDFDocumentGetCropBox(CGPDFDocumentRef document, int page)
{
  return CGRectNull;
}

CGRect CGPDFDocumentGetBleedBox(CGPDFDocumentRef document, int page)
{
  return CGRectNull;
}

CGRect CGPDFDocumentGetTrimBox(CGPDFDocumentRef document, int page)
{
  return CGRectNull;
}

CGRect CGPDFDocumentGetArtBox(CGPDFDocumentRef document, int page)
{
  return CGRectNull;
}

int CGPDFDocumentGetRotationAngle(CGPDFDocumentRef document, int page)
{
  return 0;
}

CGPDFPageRef CGPDFDocumentGetPage(
  CGPDFDocumentRef document, int pageNumber)
{
  return NULL;
}
