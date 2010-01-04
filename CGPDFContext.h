/** <title>CGPDFContext</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright (C) 2006 BALATON Zoltan <balaton@eik.bme.hu>

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

#ifndef OPAL_CGPDFContext_h
#define OPAL_CGPDFContext_h

#include <CGContext.h>

/* Functions */

CGContextRef CGPDFContextCreate(
  CGDataConsumerRef consumer,
  const CGRect *mediaBox,
  /* CFDictionaryRef */ void *auxiliaryInfo /* ignored */
);

#endif /* OPAL_CGPDFContext_h */
