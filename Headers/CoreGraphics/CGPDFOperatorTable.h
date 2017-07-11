/** <title>CGPDFOperatorTable</title>

   <abstract>C Interface to graphics drawing library
             - geometry routines</abstract>

   Copyright (C) 2010 Free Software Foundation, Inc.
   Author: Eric Wasylishen <ewasylishen@gmail.com>

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

#ifndef OPAL_CGPDFOperatorTable_h
#define OPAL_CGPDFOperatorTable_h

/* Data Types */

#ifdef INTERNAL_BUILD_OBJC
@class CGPDFOperatorTable;
typedef CGPDFOperatorTable* CGPDFOperatorTableRef;
#else
typedef struct CGPDFOperatorTable* CGPDFOperatorTableRef;
#endif

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGPDFScanner.h>

/* Callbacks */

typedef void (*CGPDFOperatorCallback)(CGPDFScannerRef scanner, void *info);

/* Functions */

CGPDFOperatorTableRef CGPDFOperatorTableCreate();

void CGPDFOperatorTableSetCallback(
  CGPDFOperatorTableRef table,
  const char *name,
  CGPDFOperatorCallback callback
);

CGPDFOperatorTableRef CGPDFOperatorTableRetain(CGPDFOperatorTableRef table);

void CGPDFOperatorTableRelease(CGPDFOperatorTableRef table);

#endif /* OPAL_CGPDFOperatorTable_h */