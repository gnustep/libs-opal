/** <title>CGImage</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2010,2016 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen <ewasylishen@gmail.com>
   Date: June, 2010
   Author: BALATON Zoltan <balaton@eik.bme.hu>
   Date: 2006

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

#include "CoreGraphics/CGImage.h"
#include "CGDataProvider-private.h"
#include <cairo.h>

@interface CGImage : NSObject
{
@public
  bool ismask;
  size_t width;
  size_t height;
  size_t bitsPerComponent;
  size_t bitsPerPixel;
  size_t bytesPerRow;
  CGDataProviderRef dp;
  CGFloat *decode;
  bool shouldInterpolate;
  /* alphaInfo is always AlphaNone for mask */
  CGBitmapInfo bitmapInfo;
  /* cspace and intent are only set for image */
  CGColorSpaceRef cspace;
  CGColorRenderingIntent intent;
  /* used for CGImageCreateWithImageInRect */
  CGRect crop;
  cairo_surface_t *surf;
}
@end

