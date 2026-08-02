/** <title>CGFunction</title>

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
#include <stdlib.h>
#include <string.h>
#include "CGFunction-private.h"

@interface CGFunction : NSObject
{
@public
  void *info;
  size_t domainDimension;
  size_t rangeDimension;
  CGFloat *domain;
  CGFloat *range;
  CGFunctionCallbacks callbacks;
}

@end

@implementation CGFunction

- (void) dealloc
{
  if (callbacks.releaseInfo)
    {
      callbacks.releaseInfo(info);
    }
  free(domain);
  free(range);
  [super dealloc];
}

@end


static CGFloat *copyPairs(const CGFloat *values, size_t dimension)
{
  if (values == NULL || dimension == 0)
    {
      return NULL;
    }
  size_t count = 2 * dimension;
  CGFloat *copy = malloc(count * sizeof(CGFloat));
  memcpy(copy, values, count * sizeof(CGFloat));
  return copy;
}

CGFunctionRef CGFunctionCreate(
  void *info,
  size_t domainDimension,
  const CGFloat *domain,
  size_t rangeDimension,
  const CGFloat *range,
  const CGFunctionCallbacks *callbacks)
{
  CGFunction *func = [[CGFunction alloc] init];

  func->info = info;
  func->domainDimension = domainDimension;
  func->rangeDimension = rangeDimension;
  func->domain = copyPairs(domain, domainDimension);
  func->range = copyPairs(range, rangeDimension);
  if (callbacks)
    {
      func->callbacks = *callbacks;
    }
  else
    {
      memset(&func->callbacks, 0, sizeof(CGFunctionCallbacks));
    }

  return func;
}

CGFunctionRef CGFunctionRetain(CGFunctionRef function)
{
  return [function retain];
}

void CGFunctionRelease(CGFunctionRef function)
{
  [function release];
}

size_t OPFunctionGetDomainDimension(CGFunctionRef function)
{
  return function ? function->domainDimension : 0;
}

size_t OPFunctionGetRangeDimension(CGFunctionRef function)
{
  return function ? function->rangeDimension : 0;
}

const CGFloat *OPFunctionGetDomain(CGFunctionRef function)
{
  return function ? function->domain : NULL;
}

void OPFunctionEvaluate(CGFunctionRef function, const CGFloat *in, CGFloat *out)
{
  if (function && function->callbacks.evaluate)
    {
      function->callbacks.evaluate(function->info, in, out);
    }
}
