/** <title>opal</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright (C) 2006 Free Software Foundation, Inc.

   Author: BALATON Zoltan <balaton@eik.bme.hu>
   Date: 2006
   
   This file is part of GNUstep

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
   */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include "opal.h"

extern void opal_dealloc_CGContext(void *);
extern void opal_dealloc_CGLayer(void *);
extern void opal_dealloc_CGColor(void *);
extern void opal_dealloc_CGImage(void *);
extern void opal_dealloc_CGDataProvider(void *);
extern void opal_dealloc_CGPattern(void *);

static struct objbase objtypes[] = {
  {"CGContext", opal_dealloc_CGContext},
  {"CGLayer", opal_dealloc_CGLayer},
  {"CGColor", opal_dealloc_CGColor},
  {"CGImage", opal_dealloc_CGImage},
  {"CGDataProvider", opal_dealloc_CGDataProvider},
  {"CGPattern", opal_dealloc_CGPattern},
  {NULL}
};

void errlog(const char *fmt, ...)
{
  va_list ap;

  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
}

void *opal_obj_alloc(const char *name, size_t size)
{
  int typeidx;
  struct objbase *obj;

  for (typeidx=0; objtypes[typeidx].name; typeidx++)
    if (strcmp(objtypes[typeidx].name, name) == 0) break;
  if (!objtypes[typeidx].name) {
    errlog("obj_alloc: Failed to create an unknown object: %s\n", name);
    return NULL;
  }

  obj = calloc(1, size);
  if (!obj) {
    errlog("obj_alloc: calloc failed for %s\n", name);
    return NULL;
  }
  *obj = objtypes[typeidx];
  obj->rc = 1;

  return obj;
}

void *opal_obj_retain(void *obj)
{
  ((struct objbase *)obj)->rc++;
  return obj;
}

void opal_obj_release(void *obj)
{
  struct objbase *o = obj;

  if (--o->rc == 0) o->dealloc(obj);
}
