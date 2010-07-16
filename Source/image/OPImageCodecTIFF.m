/** <title>OPImageCodecTIFF.m</title>

   <abstract>Bitmap image representation.</abstract>

   Copyright (C) 1996, 2003, 2004 Free Software Foundation, Inc.
   
   Author:  Adam Fedor <fedor@gnu.org>
   Date: Feb 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#if 0

#include <tiff.h>

#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>

#import "CGImageSource-private.h"
#import "CGImageDestination-private.h"
#import "CGDataProvider-private.h"
#import "CGDataConsumer-private.h"


/* 
   tiff.m

   Functions for dealing with tiff images.

   Copyright (C) 1996,1999 Free Software Foundation, Inc.
   
   Author:  Adam Fedor <fedor@colorado.edu>
   Date: Feb 1996

   Support for writing tiffs: Richard Frith-Macdonald

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

/* Code in NSTiffRead, NSTiffGetInfo, and NSTiffGetColormap 
   is derived from tif_getimage, by Sam Leffler. See the copyright below.
*/

/*
 * Copyright (c) 1991, 1992, 1993, 1994 Sam Leffler
 * Copyright (c) 1991, 1992, 1993, 1994 Silicon Graphics, Inc.
 *
 * Permission to use, copy, modify, distribute, and sell this software and 
 * its documentation for any purpose is hereby granted without fee, provided
 * that (i) the above copyright notices and this permission notice appear in
 * all copies of the software and related documentation, and (ii) the names of
 * Sam Leffler and Silicon Graphics may not be used in any advertising or
 * publicity relating to the software without the specific, prior written
 * permission of Sam Leffler and Silicon Graphics.
 * 
 * THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND, 
 * EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY 
 * WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  
 * 
 * IN NO EVENT SHALL SAM LEFFLER OR SILICON GRAPHICS BE LIABLE FOR
 * ANY SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND,
 * OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
 * WHETHER OR NOT ADVISED OF THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF 
 * LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE 
 * OF THIS SOFTWARE.
 */

#include <Foundation/NSArray.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include "GSGuiPrivate.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>
#ifndef __WIN32__
#include <unistd.h>		/* for L_SET, etc definitions */
#endif /* !__WIN32__ */

// tiff.h

#include <tiffio.h>
#include <sys/types.h>

/* Structure to store common information about a tiff. */
typedef struct {
    uint32  imageNumber;
    uint32  subfileType;
    uint32  width;
    uint32  height;
    uint16 bitsPerSample;    /* number of bits per data channel */
    uint16 samplesPerPixel;  /* number of channels per pixel */
    uint16 planarConfig;     /* meshed or separate */
    uint16 photoInterp;      /* photometric interpretation of bitmap data, */
    uint16 compression;
    uint16 extraSamples;     /* Alpha */
    int     assocAlpha;
    int     quality;	      /* compression quality (for jpeg) 1 to 255 */
    int     numImages;	      /* number of images in tiff */
    int     error;
} NSTiffInfo; 

typedef struct {
    uint32 size;
    uint16 *red;
    uint16 *green;
    uint16 *blue;
} NSTiffColormap;

typedef char* realloc_data_callback(char* data, long size);

extern TIFF* NSTiffOpenDataRead(const char* data, long size);
extern TIFF* NSTiffOpenDataWrite(char **data, long *size);
extern int   NSTiffClose(TIFF* image);

extern int   NSTiffGetImageCount(TIFF* image);
extern int   NSTiffWrite(TIFF *image, NSTiffInfo *info, unsigned char *data);
extern int   NSTiffRead(TIFF *image, NSTiffInfo *info, unsigned char *data);
extern NSTiffInfo* NSTiffGetInfo(int imageNumber, TIFF* image);

extern NSTiffColormap* NSTiffGetColormap(TIFF* image);

extern int NSTiffIsCodecConfigured(unsigned int codec);


// end tiff.h





typedef struct {
  char* data;
  long  size;
  long  position;
  char  mode;
  char **outdata;
  long *outposition;
} chandle_t;

static int tiff_error_handler_set = 0;

static void
NSTiffError(const char *func, const char *msg, va_list ap)
{
  NSString *format;

  format = [NSString stringWithFormat: @"Tiff Error (%s) %s", func, msg];
  NSLogv(format, ap);
}

static void 
NSTiffWarning(const char *func, const char *msg, va_list ap)
{
  NSString *format;

  format = [NSString stringWithFormat: @"Tiff Warning (%s) %s", func, msg];
  format = [NSString stringWithFormat: format  arguments: ap];
  NSDebugLLog(@"NSTiff", @"%@", format);
}

/* Client functions that provide reading/writing of data for libtiff */
static tsize_t
TiffHandleRead(thandle_t handle, tdata_t buf, tsize_t count)
{
  chandle_t* chand = (chandle_t *)handle;
  if (chand->position >= chand->size)
    return 0;
  if (chand->position + count > chand->size)
    count = chand->size - chand->position;
  memcpy(buf, chand->data + chand->position, count);
  return count;
}

static tsize_t
TiffHandleWrite(thandle_t handle, tdata_t buf, tsize_t count)
{
  chandle_t* chand = (chandle_t *)handle;
  if (chand->mode == 'r')
    return 0;
  if (chand->position + count > chand->size)
    {
      chand->size = chand->position + count + 1;
      chand->data = objc_realloc(chand->data, chand->size);
      *(chand->outdata) = chand->data;
      if (chand->data == NULL)
	return 0;
    }
  memcpy(chand->data + chand->position, buf, count);
  chand->position += count;
  if (chand->position > *(chand->outposition))
    *(chand->outposition) = chand->position;
  
  return count;
}

static toff_t
TiffHandleSeek(thandle_t handle, toff_t offset, int mode)
{
  chandle_t* chand = (chandle_t *)handle;
  switch(mode) 
    {
    case SEEK_SET: chand->position = offset; break;
    case SEEK_CUR: chand->position += offset; break;
    case SEEK_END: 
      if (offset > 0 && chand->mode == 'r')
        return 0;
      chand->position += offset; break;
      break;
    }
  return chand->position;
}

static int
TiffHandleClose(thandle_t handle)
{
  chandle_t* chand = (chandle_t *)handle;

  /* Presumably, we don't need the handle anymore */
  OBJC_FREE(chand);
  return 0;
}

static toff_t
TiffHandleSize(thandle_t handle)
{
  chandle_t* chand = (chandle_t *)handle;
  return chand->size;
}

static int
TiffHandleMap(thandle_t handle, tdata_t* data, toff_t* size)
{
  chandle_t* chand = (chandle_t *)handle;
  
  *data = chand->data;
  *size = chand->size;
    
  return 1;
}

static void
TiffHandleUnmap(thandle_t handle, tdata_t data, toff_t size)
{
  /* Nothing to unmap. */
}

/* Open a tiff from a stream. Returns NULL if can't read tiff information.  */
TIFF* 
NSTiffOpenDataRead(const char* data, long size)
{
  chandle_t* handle;

  if (tiff_error_handler_set == 0)
    {
      tiff_error_handler_set = 1;
      TIFFSetErrorHandler(NSTiffError);
      TIFFSetWarningHandler(NSTiffWarning);
    }

  OBJC_MALLOC(handle, chandle_t, 1);
  handle->data = (char*)data;
  handle->outdata = 0;
  handle->position = 0;
  handle->outposition = 0;
  handle->size = size;
  handle->mode = 'r';
  return TIFFClientOpen("GSTiffReadData", "r",
			(thandle_t)handle,
			TiffHandleRead, TiffHandleWrite,
			TiffHandleSeek, TiffHandleClose,
			TiffHandleSize,
			TiffHandleMap, TiffHandleUnmap);
}

TIFF* 
NSTiffOpenDataWrite(char **data, long *size)
{
  chandle_t* handle;
  OBJC_MALLOC(handle, chandle_t, 1);
  handle->data = *data;
  handle->outdata = data;
  handle->position = 0;
  handle->outposition = size;
  handle->size = *size;
  handle->mode = 'w';
  return TIFFClientOpen("GSTiffWriteData", "w",
			(thandle_t)handle,
			TiffHandleRead, TiffHandleWrite,
			TiffHandleSeek, TiffHandleClose,
			TiffHandleSize,
			TiffHandleMap, TiffHandleUnmap);
}

int  
NSTiffClose(TIFF* image)
{
  TIFFClose(image);
  return 0;
}

int   
NSTiffGetImageCount(TIFF* image)
{
  int dircount = 1;

  if (image == NULL)
    return 0;

  while (TIFFReadDirectory(image))
    {
      dircount++;
    } 
  return dircount;
}

/* Read some information about the image. Note that currently we don't
   determine numImages. */
NSTiffInfo *      
NSTiffGetInfo(int imageNumber, TIFF* image)
{
  NSTiffInfo* info;
  uint16 *sample_info = NULL;

  if (image == NULL)
    return NULL;

  OBJC_MALLOC(info, NSTiffInfo, 1);
  memset(info, 0, sizeof(NSTiffInfo));
  if (imageNumber >= 0)
    {
      if (TIFFSetDirectory(image, imageNumber) == 0)
	return NULL;
      info->imageNumber = imageNumber;
    }
  
  TIFFGetField(image, TIFFTAG_IMAGEWIDTH, &info->width);
  TIFFGetField(image, TIFFTAG_IMAGELENGTH, &info->height);
  TIFFGetField(image, TIFFTAG_COMPRESSION, &info->compression);
  if (info->compression == COMPRESSION_JPEG)
    TIFFGetField(image, TIFFTAG_JPEGQUALITY, &info->quality);
  TIFFGetField(image, TIFFTAG_SUBFILETYPE, &info->subfileType);
  TIFFGetField(image, TIFFTAG_EXTRASAMPLES, &info->extraSamples, &sample_info);
  info->extraSamples = (info->extraSamples == 1 
			&& ((sample_info[0] == EXTRASAMPLE_ASSOCALPHA) 
			    || (sample_info[0] == EXTRASAMPLE_UNASSALPHA)));
  info->assocAlpha = (info->extraSamples == 1 
		      && sample_info[0] == EXTRASAMPLE_ASSOCALPHA);

  /* If the following tags aren't present then use the TIFF defaults. */
  TIFFGetFieldDefaulted(image, TIFFTAG_BITSPERSAMPLE, &info->bitsPerSample);
  TIFFGetFieldDefaulted(image, TIFFTAG_SAMPLESPERPIXEL, 
			&info->samplesPerPixel);
  TIFFGetFieldDefaulted(image, TIFFTAG_PLANARCONFIG, 
			&info->planarConfig);

  /* If TIFFTAG_PHOTOMETRIC is not present then assign a reasonable default.
     The TIFF 5.0 specification doesn't give a default. */
  if (!TIFFGetField(image, TIFFTAG_PHOTOMETRIC, &info->photoInterp)) 
    {
      switch (info->samplesPerPixel) 
	{
	case 1:
	  info->photoInterp = PHOTOMETRIC_MINISBLACK;
	  break;
	case 3: case 4:
	  info->photoInterp = PHOTOMETRIC_RGB;
	  break;
	default:
	  TIFFError(TIFFFileName(image),
		    "Missing needed \"PhotometricInterpretation\" tag");
	  return NULL;
	}
      TIFFError(TIFFFileName(image),
		"No \"PhotometricInterpretation\" tag, assuming %s\n",
		info->photoInterp == PHOTOMETRIC_RGB ? "RGB" : "min-is-black");
    }

  return info;
}

#define READ_SCANLINE(sample)				\
  if (TIFFReadScanline(image, buf, row, sample) != 1)	\
    {							\
      error = 1;					\
      break;						\
    }

/* Read an image into a data array.  The data array is assumed to have been
   already allocated to the correct size.

   Note that palette images are implicitly coverted to 24-bit contig
   direct color images. Thus the data array should be large 
   enough to hold this information. */
int
NSTiffRead(TIFF *image, NSTiffInfo *info, unsigned char *data)
{
  int     i;
  unsigned int row, col;
  int     maxval;
  int	  error = 0;
  uint8* outP;
  uint8* buf;
  uint8* raster;
  NSTiffColormap* map;
  int scan_line_size;

  if (data == NULL)
    return -1;
	
  map = NULL;
  if (info->photoInterp == PHOTOMETRIC_PALETTE) 
    {
      map = NSTiffGetColormap(image);
      if (!map)
	return -1;
    }

  maxval = (1 << info->bitsPerSample) - 1;
  scan_line_size = TIFFScanlineSize(image);
  buf = _TIFFmalloc(scan_line_size);
  
  raster = (uint8 *)data;
  outP = raster;
  switch (info->photoInterp) 
    {
    case PHOTOMETRIC_MINISBLACK:
    case PHOTOMETRIC_MINISWHITE:
      if (info->planarConfig == PLANARCONFIG_CONTIG) 
	{
	  for (row = 0; row < info->height; ++row) 
	    {
	      READ_SCANLINE(0);
	      memcpy(outP, buf, scan_line_size);
	      outP += scan_line_size;
	    }
	} 
      else 
	{
	  for (i = 0; i < info->samplesPerPixel; i++)
	    for (row = 0; row < info->height; ++row) 
	      {
		READ_SCANLINE(i);
		memcpy(outP, buf, scan_line_size);
		outP += scan_line_size;
	      }
	}
      break;
    case PHOTOMETRIC_PALETTE:
      {
	for (row = 0; row < info->height; ++row) 
	  {
	    uint8 *inP;
	    READ_SCANLINE(0);
	    inP = buf;
	    for (col = 0; col < info->width; col++) 
	      {
		*outP++ = map->red[*inP] / 256;
		*outP++ = map->green[*inP] / 256;
		*outP++ = map->blue[*inP] / 256;
		inP++;
	      }
	  }
	free(map);
      }
      break;
    case PHOTOMETRIC_RGB:
      if (info->planarConfig == PLANARCONFIG_CONTIG) 
	{
	  for (row = 0; row < info->height; ++row) 
	    {
	      READ_SCANLINE(0);
	      memcpy(outP, buf, scan_line_size);
	      outP += scan_line_size;
	    }
	} 
      else 
	{
	  for (i = 0; i < info->samplesPerPixel; i++)
	    for (row = 0; row < info->height; ++row) 
	      {
		READ_SCANLINE(i);
		memcpy(outP, buf, scan_line_size);
		outP += scan_line_size;
	      }
	}
      break;
    default:
      NSLog(@"Tiff: reading photometric %d not supported", info->photoInterp);
      error = 1;
      break;
    }
    
  _TIFFfree(buf);
  return error;
}

#define WRITE_SCANLINE(sample) \
	if (TIFFWriteScanline(image, buf, row, sample) != 1) { \
	    error = 1; \
	    break; \
	}

int  
NSTiffWrite(TIFF *image, NSTiffInfo *info, unsigned char *data)
{
  tdata_t	buf = (tdata_t)data;
  uint16        sample_info[2];
  int		i;
  unsigned int 	row;
  int           error = 0;

  TIFFSetField(image, TIFFTAG_IMAGEWIDTH, info->width);
  TIFFSetField(image, TIFFTAG_IMAGELENGTH, info->height);
  TIFFSetField(image, TIFFTAG_COMPRESSION, info->compression);
  if (info->compression == COMPRESSION_JPEG)
    TIFFSetField(image, TIFFTAG_JPEGQUALITY, info->quality);
  TIFFSetField(image, TIFFTAG_SUBFILETYPE, info->subfileType);
  TIFFSetField(image, TIFFTAG_BITSPERSAMPLE, info->bitsPerSample);
  TIFFSetField(image, TIFFTAG_SAMPLESPERPIXEL, info->samplesPerPixel);
  TIFFSetField(image, TIFFTAG_PLANARCONFIG, info->planarConfig);
  TIFFSetField(image, TIFFTAG_PHOTOMETRIC, info->photoInterp);

  if (info->assocAlpha)
    sample_info[0] = EXTRASAMPLE_ASSOCALPHA;
  else
    sample_info[0] = EXTRASAMPLE_UNASSALPHA;
  TIFFSetField(image, TIFFTAG_EXTRASAMPLES, info->extraSamples, sample_info);

  switch (info->photoInterp) 
    {
      case PHOTOMETRIC_MINISBLACK:
      case PHOTOMETRIC_MINISWHITE:
	if (info->planarConfig == PLANARCONFIG_CONTIG) 
	  {
	    int	line = ceil((float)info->width * info->bitsPerSample / 8.0);

	    for (row = 0; row < info->height; ++row) 
	      {
		WRITE_SCANLINE(0)
		buf += line;
	      }
	  } 
	else 
	  {
	    int	line = ceil((float)info->width / 8.0);

	    for (i = 0; i < info->samplesPerPixel; i++)
	      {
		for (row = 0; row < info->height; ++row) 
		  {
		    WRITE_SCANLINE(i)
		    buf += line;
		  }
	      }
	  }
	break;

      case PHOTOMETRIC_RGB:
	if (info->planarConfig == PLANARCONFIG_CONTIG) 
	  {
	    for (row = 0; row < info->height; ++row) 
	      {
		WRITE_SCANLINE(0)
		buf += info->width * info->samplesPerPixel;
	      }
	  } 
	else 
	  {
	    for (i = 0; i < info->samplesPerPixel; i++)
	      {
		for (row = 0; row < info->height; ++row) 
		  {
		    WRITE_SCANLINE(i)
		    buf += info->width;
		  }
	      }
	  }
	break;

      default:
	NSLog(@"Tiff: photometric %d for image %s not supported", 
	      info->photoInterp, TIFFFileName(image));
	return -1;
	break;
    }
    
  return error;
}

/*------------------------------------------------------------------------*/

/* Many programs get TIFF colormaps wrong.  They use 8-bit colormaps
   instead of 16-bit colormaps.  This function is a heuristic to
   detect and correct this. */
static int
CheckAndCorrectColormap(NSTiffColormap* map)
{
  register unsigned int i;

  for (i = 0; i < map->size; i++)
    if ((map->red[i] > 255)||(map->green[i] > 255)||(map->blue[i] > 255))
      return 16;

#define	CVT(x)		(((x) * 255) / ((1L<<16)-1))
  for (i = 0; i < map->size; i++) 
    {
      map->red[i] = CVT(map->red[i]);
      map->green[i] = CVT(map->green[i]);
      map->blue[i] = CVT(map->blue[i]);
    }
  return 8;
}

/* Gets the colormap for the image if there is one. Returns a
   NSTiffColormap if one was found.
*/
NSTiffColormap *
NSTiffGetColormap(TIFF* image)
{
  NSTiffInfo* info;
  NSTiffColormap* map;

  /* Re-read the tiff information. We pass -1 as the image number which
     means just read the current image. */
  info = NSTiffGetInfo(-1, image);
  if (info->photoInterp != PHOTOMETRIC_PALETTE)
    return NULL;

  OBJC_MALLOC(map, NSTiffColormap, 1);
  map->size = 1 << info->bitsPerSample;

  if (!TIFFGetField(image, TIFFTAG_COLORMAP,
		    &map->red, &map->green, &map->blue)) 
    {
      TIFFError(TIFFFileName(image), "Missing required \"Colormap\" tag");
      OBJC_FREE(map);
      return NULL;
    }
  if (CheckAndCorrectColormap(map) == 8)
    TIFFWarning(TIFFFileName(image), "Assuming 8-bit colormap");

  free(info);
  return map;
}

int NSTiffIsCodecConfigured(unsigned int codec)
{
#if (TIFFLIB_VERSION >= 20041016)
  // starting with version 3.7.0 we can ask libtiff what it is configured to do
  return TIFFIsCODECConfigured(codec);
#else
  // we check the tiffconf.h
#include <tiffconf.h>
#ifndef CCITT_SUPPORT
#  define CCITT_SUPPORT 0
#else
#  define CCITT_SUPPORT 1
#endif
#ifndef PACKBITS_SUPPORT
#  define PACKBITS_SUPPORT 0
#else
#  define PACKBITS_SUPPORT 1
#endif
#ifndef OJPEG_SUPPORT
#  define OJPEG_SUPPORT 0
#else
#  define OJPEG_SUPPORT 1
#endif
#ifndef LZW_SUPPORT
#  define LZW_SUPPORT 0
#else
#  define LZW_SUPPORT 1
#endif
#ifndef NEXT_SUPPORT
#  define NEXT_SUPPORT 0
#else
#  define NEXT_SUPPORT 1
#endif
#ifndef JPEG_SUPPORT
#  define JPEG_SUPPORT 0
#else
#  define JPEG_SUPPORT 1
#endif
/* If this fails, your libtiff is obsolete! Come to think of it
 * if you even are compiling this part your libtiff is obsolete. */
  switch (codec)
  {
    case COMPRESSION_NONE: return 1;
    case COMPRESSION_CCITTFAX3: return CCITT_SUPPORT;
    case COMPRESSION_CCITTFAX4: return CCITT_SUPPORT;
    case COMPRESSION_JPEG: return JPEG_SUPPORT;
    case COMPRESSION_PACKBITS: return PACKBITS_SUPPORT;
    case COMPRESSION_OJPEG: return OJPEG_SUPPORT;
    case COMPRESSION_LZW: return LZW_SUPPORT;
    case COMPRESSION_NEXT: return NEXT_SUPPORT;
    default:
      return 0;
  }
#endif
}


// end tiff.m












@interface CGImageSourceTIFF : CGImageSource
{
  CGDataProviderRef dp;
}
@end

@implementation CGImageSourceTIFF

+ (void)load
{
  [CGImageSource registerSourceClass: self];
}

+ (NSArray *)typeIdentifiers
{
  return [NSArray arrayWithObject: @"public.tiff"];
}

- (id)initWithProvider: (CGDataProviderRef)provider;
{
  self = [super init];
  dp = CGDataProviderRetain(provider);
  return self;
}

- (void)dealloc
{
  CGDataProviderRelease(dp);
  [super dealloc];
}

- (NSDictionary*)propertiesWithOptions: (NSDictionary*)opts
{
  return [NSDictionary dictionary];
}

- (NSDictionary*)propertiesWithOptions: (NSDictionary*)opts atIndex: (size_t)index
{
  return [NSDictionary dictionary];  
}

- (size_t)count
{
  return 1;
}

- (CGImageRef)createImageAtIndex: (size_t)index options: (NSDictionary*)opts
{
  CGImageRef img = NULL;
  png_structp png_struct;
  png_infop png_info, png_end_info;

  if (!(self = [super init]))
    return NULL;

  if (!opal_has_png_header(dp))
    return NULL;
    
  OPDataProviderRewind(dp);
  
  NS_DURING
  {
    png_struct = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, opal_png_error_fn, opal_png_warning_fn);
    if (!png_struct)
      {
        RELEASE(self);
        return NULL;
      }
  
    png_info = png_create_info_struct(png_struct);
    if (!png_info)
      {
        png_destroy_read_struct(&png_struct, NULL, NULL);
        RELEASE(self);
        return NULL;
      }
  
    png_end_info = png_create_info_struct(png_struct);
    if (!png_end_info)
      {
        png_destroy_read_struct(&png_struct, &png_info, NULL);
        RELEASE(self);
        return NULL;
      }

    png_set_read_fn(png_struct, dp, opal_png_reader_func);
  
    png_read_info(png_struct, png_info);
  
    int width = png_get_image_width(png_struct, png_info);
    int height = png_get_image_height(png_struct, png_info);
    int bytes_per_row = png_get_rowbytes(png_struct, png_info);
    int type = png_get_color_type(png_struct, png_info);
    int channels = png_get_channels(png_struct, png_info); // includes alpha
    int depth = png_get_bit_depth(png_struct, png_info);
  
    BOOL alpha = NO;
    CGColorSpaceRef cs = NULL;
    
    switch (type)
    {
      case PNG_COLOR_TYPE_GRAY_ALPHA:
        alpha = YES;
      case PNG_COLOR_TYPE_GRAY:
      	cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
      	break;
      
    	case PNG_COLOR_TYPE_RGB_ALPHA:	
    	  alpha = YES;
      case PNG_COLOR_TYPE_RGB:
      	cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        break;
                	
      case PNG_COLOR_TYPE_PALETTE:
      	png_set_palette_to_rgb(png_struct);
      	if (png_get_valid(png_struct, png_info, PNG_INFO_tRNS))
        {
          alpha = YES;
          png_set_tRNS_to_alpha(png_struct);
        }
        cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
      	break;

      default:
      	NSLog(@"NSBitmapImageRep+PNG: unknown color type %i", type);
      	RELEASE(self);
      	return NULL;
    }
  
    // FIXME: Handle colorspaces properly
    // FIXME: Handle color rendering intent
    // FIXME: Handle gamma
    // FIXME: Handle resolution

    // Create the CGImage
    
    NSMutableData *imgData = [[NSMutableData alloc] initWithLength: height * bytes_per_row];
    {
      unsigned char *row_pointers[height];
      unsigned char *buf = [imgData mutableBytes];
      for (int i = 0; i < height; i++)
      {
        row_pointers[i] = buf + (i * bytes_per_row);
      }
      png_read_image(png_struct, row_pointers);
    }    
    CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData((CFDataRef)imgData);
    [imgData release];
    
    img = CGImageCreate(
      width,
      height,
      depth,
      channels * depth,
      bytes_per_row,
      cs,
      kCGBitmapByteOrderDefault | (alpha ? kCGImageAlphaLast : kCGImageAlphaNone),
      imgDataProvider,
      NULL,
      true,
      kCGRenderingIntentDefault);

    CGColorSpaceRelease(cs);
    CGDataProviderRelease(imgDataProvider);
  }
  NS_HANDLER
  {
    RELEASE(self);
    png_destroy_read_struct(&png_struct, &png_info, &png_end_info);
    NS_VALUERETURN(nil, CGImageRef);
  }
  NS_ENDHANDLER
  
  png_destroy_read_struct(&png_struct, &png_info, &png_end_info);
  
  return img;
}

- (CGImageRef)createThumbnailAtIndex: (size_t)index options: (NSDictionary*)opts
{
  return nil;
}

- (CGImageSourceStatus)status
{
  return kCGImageStatusComplete;
}

- (CGImageSourceStatus)statusAtIndex: (size_t)index
{
  return kCGImageStatusComplete;
}

- (NSString*)type
{
  return @"public.png";
}

- (void)updateDataProvider: (CGDataProviderRef)provider finalUpdate: (bool)finalUpdate
{
  ;
}

@end



@interface CGImageDestinationTIFF : CGImageDestination
{
  CGDataConsumerRef dc;
  CFDictionaryRef props;
  CGImageRef img;
}
@end

@implementation CGImageDestinationTIFF

+ (void)load
{
  [CGImageDestination registerDestinationClass: self];
}

+ (NSArray *)typeIdentifiers
{
  return [NSArray arrayWithObject: @"public.tiff"];
}
- (id) initWithDataConsumer: (CGDataConsumerRef)consumer
                       type: (CFStringRef)type
                      count: (size_t)count
                    options: (CFDictionaryRef)opts
{
  self = [super init];
  
  if (!CFEqual(type, CFSTR("public.tiff")) || count != 1)
  {
    [self release];
    return nil;
  }
  
  dc = CFRetain(consumer);
  
  return self;
}

- (void)dealloc
{
  CGDataConsumerRelease(dc);
  CFRelease(props);
  CGImageRelease(img);
  [super dealloc];    
}

- (void) setProperties: (CFDictionaryRef)properties
{
  props = CFRetain(properties);
}

- (void) addImage: (CGImageRef)image properties: (CFDictionaryRef)properties
{
  img = CGImageRetain(image);
  props = CFRetain(properties);
}

- (bool) finalize
{
  png_structp png_struct;
  png_infop png_info;

  // make the PNG structures
  png_struct = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, opal_png_error_fn, opal_png_warning_fn);
  if (!png_struct)
  {
    return false;
  }

  png_info = png_create_info_struct(png_struct);
  if (!png_info)
  {
    png_destroy_write_struct(&png_struct, NULL);
    return false;
  }

  NS_DURING  
  {
    const bool interlace = false;
    const int width = CGImageGetWidth(img);
    const int height = CGImageGetHeight(img);
    const int bytes_per_row = CGImageGetBytesPerRow(img);    
    const int depth = CGImageGetBitsPerComponent(img);
  
    const int alphaInfo = CGImageGetAlphaInfo(img);
    const CGColorSpaceModel model = CGColorSpaceGetModel(CGImageGetColorSpace(img));
    
    int type;
    switch (model)
    {
      case kCGColorSpaceModelRGB:
        type = PNG_COLOR_TYPE_RGB; 
        break;
      case kCGColorSpaceModelMonochrome:
        type = PNG_COLOR_TYPE_GRAY;
        break;
      default:
        NSLog(@"Unsupported color model");
        return false;
    }
    
    switch (alphaInfo)
    {
      case kCGImageAlphaNone:
        break;
        
      case kCGImageAlphaPremultipliedFirst:
        //png_set_swap_alpha(png_struct);
        NSLog(@"Unsupported alpha type");
        return false;
        
      case kCGImageAlphaPremultipliedLast:
        // FIXME: must un-premultiply
        type |= PNG_COLOR_MASK_ALPHA;
        NSLog(@"Unsupported color model");
        return false;
        
      case kCGImageAlphaFirst:
        //png_set_swap_alpha(png_struct);
        NSLog(@"Unsupported alpha type");
        return false;
        
      case kCGImageAlphaLast:
        type |= PNG_COLOR_MASK_ALPHA;
        break;
        
      case kCGImageAlphaNoneSkipLast:
      case kCGImageAlphaNoneSkipFirst:
        // Will need to process
        NSLog(@"Unsupported alpha type");
        return false;
    }
          
    // init structures
    png_info_init_3(&png_info, png_sizeof(png_info));
    png_set_write_fn(png_struct, dc, opal_png_writer_func, NULL);
    png_set_IHDR(png_struct, png_info, width, height, depth,
     type, PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_BASE,
     PNG_FILTER_TYPE_BASE);
  
    png_write_info(png_struct, png_info);
    
    char *rowdata = malloc(bytes_per_row);
    CGDataProviderRef dp = CGImageGetDataProvider(img);
    const int times = interlace ? png_set_interlace_handling(png_struct) : 1;
    for (int i=0; i<times; i++)
    {
      OPDataProviderRewind(dp);
      for (int j=0; j<height; j++) 
      {
        OPDataProviderGetBytes(dp, rowdata, bytes_per_row);
        png_write_row(png_struct, rowdata);
      }
    }
    free(rowdata);
    
    png_write_end(png_struct, png_info);
  }
  NS_HANDLER
  {
    png_destroy_write_struct(&png_struct, &png_info);
    NS_VALUERETURN(false, bool);
  }
  NS_ENDHANDLER
              
  png_destroy_write_struct(&png_struct, &png_info);
  return true;
}

@end

























































































//
// Setting and Checking Compression Types 
//
/** Returns a C-array of available TIFF compression types.
 */
+ (void) getTIFFCompressionTypes: (const NSTIFFCompression **)list
			   count: (int *)numTypes
{
  // the GNUstep supported types
  static NSTIFFCompression	types[] = {
    NSTIFFCompressionNone,
    NSTIFFCompressionCCITTFAX3,
    NSTIFFCompressionCCITTFAX4,
    NSTIFFCompressionLZW,
    NSTIFFCompressionJPEG,
    NSTIFFCompressionNEXT,
    NSTIFFCompressionPackBits,
    NSTIFFCompressionOldJPEG
  };
  
  // check with libtiff to see what is really available
  int i, j;
  static NSTIFFCompression checkedTypes[8];
  for (i = 0, j = 0; i < 8; i++)
  {
    if (NSTiffIsCodecConfigured([NSBitmapImageRep _localFromCompressionType: types[i]]))
    {
      checkedTypes[j] = types[i];
      j++;
    }
  }
  if (list)
    *list = checkedTypes;
  if (numTypes)
    *numTypes = j;
}

/** Returns a localized string describing a TIFF compression type. */
+ (NSString*) localizedNameForTIFFCompressionType: (NSTIFFCompression)type
{
  switch (type)
    {
      case NSTIFFCompressionNone: return _(@"No Compression");
      case NSTIFFCompressionCCITTFAX3: return _(@"CCITTFAX3 Compression");
      case NSTIFFCompressionCCITTFAX4: return _(@"CCITTFAX4 Compression");
      case NSTIFFCompressionLZW: return _(@"LZW Compression");
      case NSTIFFCompressionJPEG: return _(@"JPEG Compression");
      case NSTIFFCompressionNEXT: return _(@"NEXT Compression");
      case NSTIFFCompressionPackBits: return _(@"PackBits Compression");
      case NSTIFFCompressionOldJPEG: return _(@"Old JPEG Compression");
      default: return nil;
    }
}

/** Returns YES if the receiver can be stored in a representation
    compressed using the compression type.  */
- (BOOL) canBeCompressedUsing: (NSTIFFCompression)compression
{
  BOOL does;
  int codecConf =
    NSTiffIsCodecConfigured([NSBitmapImageRep _localFromCompressionType: compression]);
  switch (compression)
    {
      case NSTIFFCompressionCCITTFAX3:
      case NSTIFFCompressionCCITTFAX4:
	if (_numColors == 1 && _bitsPerSample == 1 && codecConf != 0)
	  does = YES;
	else
	  does = NO;
	break;

      case NSTIFFCompressionLZW: 
      case NSTIFFCompressionNone:
      case NSTIFFCompressionJPEG:	// this is a GNUstep extension; Cocoa does not support
      case NSTIFFCompressionPackBits:
      case NSTIFFCompressionOldJPEG:
      case NSTIFFCompressionNEXT:
      default:
	does = (codecConf != 0);
    }
  return does;
}

/** Returns the receivers compression and compression factor, which is
    set either when the image is read in or by -setCompression:factor:.
    Factor is ignored in many compression schemes. For JPEG compression,
    factor can be any value from 0 to 255, with 255 being the maximum
    compression.  */
- (void) getCompression: (NSTIFFCompression*)compression
		 factor: (float*)factor
{
  *compression = _compression;
  *factor = _comp_factor;
}

- (void) setCompression: (NSTIFFCompression)compression
		 factor: (float)factor
{
  _compression = compression;
  _comp_factor = factor;
}

/** <p> Properties are key-value pairs associated with the representation. Arbitrary
  key-value pairs may be set. If the value is nil, the key is erased from properties.
  There are standard keys that are used to pass information
  and options related to the standard file types that may be read from or written to.
  Certain properties are automatically set when reading in image data.
  Certain properties may be set by the user prior to writing image data in order to set options
  for the data format. </p>
  <deflist>
    <term> NSImageCompressionMethod </term>
    <desc> NSNumber; automatically set when reading TIFF data; writing TIFF data </desc>
    <term> NSImageCompressionFactor </term>
    <desc> NSNumber 0.0 to 255.0; writing JPEG data 
    (GNUstep extension: JPEG-compressed TIFFs too) </desc>
    <term> NSImageProgressive </term>
    <desc> NSNumber boolean; automatically set when reading JPEG data; writing JPEG data.
    Note: progressive display is not supported in GNUstep at this time. </desc>
    <term> NSImageInterlaced </term>
    <desc> NSNumber boolean; only for writing PNG data </desc>
    <term> NSImageGamma </term>
    <desc> NSNumber 0.0 to 1.0; only for reading or writing PNG data </desc>
    <term> NSImageRGBColorTable </term>
    <desc> NSData; automatically set when reading GIF data; writing GIF data </desc>
    <term> NSImageFrameCount </term>
    <desc> NSNumber integer; automatically set when reading animated GIF data.
    Not currently implemented. </desc>
    <term> NSImageCurrentFrame </term>
    <desc> NSNumber integer; only for animated GIF files. Not currently implemented. </desc>
    <term> NSImageCurrentFrameDuration </term>
    <desc> NSNumber float; automatically set when reading animated GIF data </desc>
    <term> NSImageLoopCount </term>
    <desc> NSNumber integer; automatically set when reading animated GIF data </desc>
    <term> NSImageDitherTranparency </term>
    <desc> NSNumber boolean; only for writing GIF data. Not currently supported. </desc>
  </deflist>
*/

#endif