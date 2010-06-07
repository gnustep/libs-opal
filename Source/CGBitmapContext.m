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
 
#include "CGContext-private.h" 
 
CGContextRef CGBitmapContextCreate(
  void *data,
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bytesPerRow,
  CGColorSpaceRef colorspace,
  CGImageAlphaInfo alphaInfo)
{

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

}


CGImageAlphaInfo CGBitmapContextGetAlphaInfo(CGContextRef ctx)
{

}

CGBitmapInfo CGBitmapContextGetBitmapInfo(CGContextRef context)
{

}

size_t CGBitmapContextGetBitsPerComponent(CGContextRef ctx)
{

}

size_t CGBitmapContextGetBitsPerPixel(CGContextRef ctx)
{

}

size_t CGBitmapContextGetBytesPerRow(CGContextRef ctx)
{

}

CGColorSpaceRef CGBitmapContextGetColorSpace(CGContextRef ctx)
{

}

void *CGBitmapContextGetData(CGContextRef ctx)
{

}

size_t CGBitmapContextGetHeight(CGContextRef ctx)
{

}

size_t CGBitmapContextGetWidth(CGContextRef ctx)
{

}

CGImageRef CGBitmapContextCreateImage(CGContextRef ctx)
{

}