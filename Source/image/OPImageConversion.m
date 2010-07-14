/** <title>CGImage-conversion.m</title>

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

#include <stdlib.h>
#include <math.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSValue.h>


/*
 * This code was copied over from XGBitmap.m
 * Here we extract a value a given number of bits wide from a bit
 * offset into a block of memory starting at "base". The bit numbering
 * is assumed to be such that a bit offset of zero and a width of 4 gives
 * the upper 4 bits of the first byte, *not* the lower 4 bits. We do allow
 * the value to cross a byte boundary, though it is unclear as to whether
 * this is strictly necessary for OpenStep tiffs.
 */
static unsigned int
_get_bit_value(unsigned char *base, long msb_off, int bit_width)
{
  long lsb_off, byte1, byte2;
  int shift, value;

  /*
   * Firstly we calculate the position of the msb and lsb in terms
   * of bit offsets and thus byte offsets. The shift is the number of
   * spare bits left in the byte containing the lsb
   */
  lsb_off= msb_off+bit_width-1;
  byte1= msb_off/8;
  byte2= lsb_off/8;
  shift= 7-(lsb_off%8);

  /*
   * We now get the value from the byte array, possibly using two bytes if
   * the required set of bits crosses the byte boundary. This is then shifted
   * down to it's correct position and extraneous bits masked off before
   * being returned.
   */
  value=base[byte2];
  if (byte1!=byte2)
    value|= base[byte1]<<8;
  value >>= shift;

  return value & ((1<<bit_width)-1);
}

/**
 * Returns the values of the components of pixel (x,y), where (0,0) is the 
 * top-left pixel in the image, by storing them in the array pixelData.
 */
- (void) getPixel: (unsigned int[])pixelData atX: (int)x y: (int)y
{
  int i;
  long int offset;
  long int line_offset;

	if (x < 0 || y < 0 || x >= _pixelsWide || y >= _pixelsHigh)
    {
      // outside
      return;
    }

  line_offset = _bytesPerRow * y;
  if (_isPlanar)
    {
      if (_bitsPerSample == 8)
        {
          offset = x + line_offset;
          for (i = 0; i < _numColors; i++)
            {
              pixelData[i] = _imagePlanes[i][offset];
            }
        }
      else
        {
          offset = _bitsPerPixel * x;
          for (i = 0; i < _numColors; i++)
            {
              pixelData[i] = _get_bit_value(_imagePlanes[i] + line_offset, 
                                            offset, _bitsPerSample);
            }
        }
    }
  else
		{
      if (_bitsPerSample == 8)
        {
          offset = (_bitsPerPixel * x) / 8 + line_offset;
          for (i = 0; i < _numColors; i++)
            {
              pixelData[i] = _imagePlanes[0][offset + i];
            }
        }
      else
        {
          offset = _bitsPerPixel * x;
          for (i = 0; i < _numColors; i++)
            {
              pixelData[i] = _get_bit_value(_imagePlanes[0] + line_offset, 
                                            offset, _bitsPerSample);
              offset += _bitsPerSample;
            }
        }
		}
}

static void
_set_bit_value(unsigned char *base, long msb_off, int bit_width, 
               unsigned int value)
{
  long lsb_off, byte1, byte2;
  int shift;
  int all;

  /*
   * Firstly we calculate the position of the msb and lsb in terms
   * of bit offsets and thus byte offsets. The shift is the number of
   * spare bits left in the byte containing the lsb
   */
  lsb_off= msb_off+bit_width-1;
  byte1= msb_off/8;
  byte2= lsb_off/8;
  shift= 7-(lsb_off%8);

  /*
   * We now set the value in the byte array, possibly using two bytes if
   * the required set of bits crosses the byte boundary. This value is 
   * first shifted up to it's correct position and extraneous bits are 
   * masked off.
   */
  value &= ((1<<bit_width)-1);
  value <<= shift;
  all = ((1<<bit_width)-1) << shift;

  if (byte1 != byte2)
    base[byte1] = (value >> 8) | (base[byte1] ^ (all >> 8));
  base[byte2] = (value & 255) | (base[byte2] ^ (all & 255));
}

/**
 * Sets the components of pixel (x,y), where (0,0) is the top-left pixel in
 * the image, to the given array of pixel components. 
 */
- (void) setPixel: (unsigned int[])pixelData atX: (int)x y: (int)y
{
  int i;
  long int offset;
  long int line_offset;

	if (x < 0 || y < 0 || x >= _pixelsWide || y >= _pixelsHigh)
    {
      // outside
      return;
    }

  if (!_imagePlanes || !_imagePlanes[0])
    {
      // allocate plane memory
      [self bitmapData];
    }

  line_offset = _bytesPerRow * y;
  if(_isPlanar)
    {
      if (_bitsPerSample == 8)
        {
          offset = x + line_offset;
          for (i = 0; i < _numColors; i++)
            {
              _imagePlanes[i][offset] = pixelData[i];
            }
        }
      else
        {
          offset = _bitsPerPixel * x;
          for (i = 0; i < _numColors; i++)
            {
              _set_bit_value(_imagePlanes[i] + line_offset, 
                             offset, _bitsPerSample, pixelData[i]);
            }
        }
		}
  else
    {
      if (_bitsPerSample == 8)
        {
          offset = (_bitsPerPixel * x) / 8 + line_offset;
          for (i = 0; i < _numColors; i++)
            {
              _imagePlanes[0][offset + i] = pixelData[i];
            }
        }
      else
        {
          offset = _bitsPerPixel * x;
          for (i = 0; i < _numColors; i++)
            {
              _set_bit_value(_imagePlanes[0] + line_offset, 
                             offset, _bitsPerSample, pixelData[i]);
              offset += _bitsPerSample;
            }
        }
    }
}

/**
 * Returns an NSColor object representing the color of the pixel (x,y), where
 * (0,0) is the top-left pixel in the image.
 */
- (NSColor*) colorAtX: (int)x y: (int)y
{
	unsigned int pixelData[5];

	if (x < 0 || y < 0 || x >= _pixelsWide || y >= _pixelsHigh)
    {
      // outside
      return nil;
    }

	[self getPixel: pixelData atX: x y: y];
	if ([_colorSpace isEqualToString: NSCalibratedRGBColorSpace]
      || [_colorSpace isEqualToString: NSDeviceRGBColorSpace])
		{
      unsigned int ir, ig, ib, ia;
      float fr, fg, fb, fa;
      float scale;

      scale = (float)((1 << _bitsPerSample) - 1);
      if (_hasAlpha)
        {
          // This order depends on the bitmap format
          if (_format & NSAlphaFirstBitmapFormat)
            {
              ia = pixelData[0];
              ir = pixelData[1];
              ig = pixelData[2];
              ib = pixelData[3];
            }
          else
            {
              ir = pixelData[0];
              ig = pixelData[1];
              ib = pixelData[2];
              ia = pixelData[3];
            }

          // Scale to [0.0 ... 1.0] and undo premultiplication
          fa = ia / scale;
          if (_format & NSAlphaNonpremultipliedBitmapFormat)
            {
              fr = ir / scale;
              fg = ig / scale;
              fb = ib / scale;
            }
          else
            {
              fr = ir / (scale * fa);
              fg = ig / (scale * fa);
              fb = ib / (scale * fa);
            }
        }
      else
        {
          ir = pixelData[0];
          ig = pixelData[1];
          ib = pixelData[2];
          // Scale to [0.0 ... 1.0]
          fr = ir / scale;
          fg = ig / scale;
          fb = ib / scale;
          fa = 1.0;
        }
      if ([_colorSpace isEqualToString: NSCalibratedRGBColorSpace])
        {
          return [NSColor colorWithCalibratedRed: fr
                          green: fg
                          blue: fb
                          alpha: fa];
        }
      else
        {
          return [NSColor colorWithDeviceRed: fr
                          green: fg
                          blue: fb
                          alpha: fa];
        }
		}
	else if ([_colorSpace isEqual: NSDeviceWhiteColorSpace]
           || [_colorSpace isEqual: NSCalibratedWhiteColorSpace])
		{
      unsigned int iw, ia;
      float fw, fa;
      float scale;

      scale = (float)((1 << _bitsPerSample) - 1);
      if (_hasAlpha)
        {
          // FIXME: This order depends on the bitmap format
          if (_format & NSAlphaFirstBitmapFormat)
            {
                ia = pixelData[0];
                iw = pixelData[1];
            }
          else
            {
                iw = pixelData[0];
                ia = pixelData[1];
            }

          // Scale to [0.0 ... 1.0] and undo premultiplication
          fa = ia / scale;
          if (_format & NSAlphaNonpremultipliedBitmapFormat)
            {
              fw = iw / scale;
            }
          else
            {
              fw = iw / (scale * fa);
            }
        }
      else
        {
          // FIXME: This order depends on the bitmap format
          iw = pixelData[0];
          // Scale to [0.0 ... 1.0]
          fw = iw / scale;
          fa = 1.0;
        }
      if ([_colorSpace isEqualToString: NSCalibratedWhiteColorSpace])
        {
          return [NSColor colorWithCalibratedWhite: fw
                          alpha: fa];
        }
      else
        {
          return [NSColor colorWithDeviceWhite: fw
                          alpha: fa];
        }
    }
  else if ([_colorSpace isEqual: NSDeviceBlackColorSpace]
           || [_colorSpace isEqual: NSCalibratedBlackColorSpace])
    {
      unsigned int ib, ia;
      float fw, fa;
      float scale;

      scale = (float)((1 << _bitsPerSample) - 1);
      if (_hasAlpha)
        {
          // This order depends on the bitmap format
          if (_format & NSAlphaFirstBitmapFormat)
            {
              ia = pixelData[0];
              ib = pixelData[1];
            }
          else
            {
              ib = pixelData[0];
              ia = pixelData[1];
            }
          // Scale to [0.0 ... 1.0] and undo premultiplication
          fa = ia / scale;
         if (_format & NSAlphaNonpremultipliedBitmapFormat)
           {
             fw = 1.0 - ib / scale;
           }
         else
           {
             fw = 1.0 - ib / (scale * fa);
           }
        }
      else
        {
          ib = pixelData[0];
          // Scale to [0.0 ... 1.0]
          fw = 1.0 - ib / scale;
          fa = 1.0;
        }
      if ([_colorSpace isEqualToString: NSCalibratedBlackColorSpace])
        {
          return [NSColor colorWithCalibratedWhite: fw
                          alpha: fa];
        }
      else
        {
          return [NSColor colorWithDeviceWhite: fw
                          alpha: fa];
        }
		}
  else if ([_colorSpace isEqual: NSDeviceCMYKColorSpace])
    {
      unsigned int ic, im, iy, ib, ia;
      float fc, fm, fy, fb, fa;
      float scale;

      scale = (float)((1 << _bitsPerSample) - 1);
      if (_hasAlpha)
        {
          // This order depends on the bitmap format
          if (_format & NSAlphaFirstBitmapFormat)
            {
              ia = pixelData[0];
              ic = pixelData[1];
              im = pixelData[2];
              iy = pixelData[3];
              ib = pixelData[4];
            }
          else
            {
              ic = pixelData[0];
              im = pixelData[1];
              iy = pixelData[2];
              ib = pixelData[3];
              ia = pixelData[4];
            }

          // Scale to [0.0 ... 1.0] and undo premultiplication
          fa = ia / scale;
          if (_format & NSAlphaNonpremultipliedBitmapFormat)
            {
              fc = ic / scale;
              fm = im / scale;
              fy = iy / scale;
              fb = ib / scale;
            }
          else
            {
              fc = ic / (scale * fa);
              fm = im / (scale * fa);
              fy = iy / (scale * fa);
              fb = ib / (scale * fa);
            }
        }
      else
        {
          ic = pixelData[0];
          im = pixelData[1];
          iy = pixelData[2];
          ib = pixelData[3];
          // Scale to [0.0 ... 1.0]
          fc = ic / scale;
          fm = im / scale;
          fy = iy / scale;
          fb = ib / scale;
          fa = 1.0;
        }

      return [NSColor colorWithDeviceCyan: fc
                      magenta: fm
                      yellow: fy
                      black: fb
                      alpha: fa];
    }

	return nil;
}

/**
 * Sets the color of pixel (x,y), where (0,0) is the top-left pixel in the
 * image.
 */
- (void) setColor: (NSColor*)color atX: (int)x y: (int)y
{
	unsigned int pixelData[5];
  NSColor *conv;

	if (x < 0 || y < 0 || x >= _pixelsWide || y >= _pixelsHigh)
    {
      // outside
      return;
    }

  conv = [color colorUsingColorSpaceName: _colorSpace];
  if (!conv)
    {
      return;
    }
      
  if ([_colorSpace isEqualToString: NSCalibratedRGBColorSpace]
      || [_colorSpace isEqualToString: NSDeviceRGBColorSpace])
    {
      unsigned int ir, ig, ib, ia;
      float fr, fg, fb, fa;
      float scale;

      scale = (float)((1 << _bitsPerSample) - 1);
      [conv getRed: &fr green: &fg blue: &fb alpha: &fa];
      if(_hasAlpha)
        {
          // Scale and premultiply alpha
          if (_format & NSAlphaNonpremultipliedBitmapFormat)
            {
              ir = scale * fr;
              ig = scale * fg;
              ib = scale * fb;
            }
          else
            {
              ir = scale * fr * fa;
              ig = scale * fg * fa;
              ib = scale * fb * fa;
            }
          ia = scale * fa;

          // This order depends on the bitmap format
          if (_format & NSAlphaFirstBitmapFormat)
            {
              pixelData[0] = ia;
              pixelData[1] = ir;
              pixelData[2] = ig;
              pixelData[3] = ib;
            }
          else
            {
              pixelData[0] = ir;
              pixelData[1] = ig;
              pixelData[2] = ib;
              pixelData[3] = ia;
            }
        }
      else
        {
          // Scale
          ir = scale * fr;
          ig = scale * fg;
          ib = scale * fb;
          // This order depends on the bitmap format
          pixelData[0] = ir;
          pixelData[1] = ig;
          pixelData[2] = ib;
        }
    }
	else if ([_colorSpace isEqual: NSDeviceWhiteColorSpace]
           || [_colorSpace isEqual: NSCalibratedWhiteColorSpace])
		{
      unsigned int iw, ia;
      float fw, fa;
      float scale;

      scale = (float)((1 << _bitsPerSample) - 1);
      [conv getWhite: &fw alpha: &fa];
      if (_hasAlpha)
        {
          if (_format & NSAlphaNonpremultipliedBitmapFormat)
            {
              iw = scale * fw;
            }
          else
            {
              iw = scale * fw * fa;
            }
          ia = scale * fa;

          // This order depends on the bitmap format
          if (_format & NSAlphaFirstBitmapFormat)
            {
              pixelData[0] = ia;
              pixelData[1] = iw;
            }
          else
            {
              pixelData[0] = iw;
              pixelData[1] = ia;
            }
        }
      else
        {
          iw = scale * fw;
          pixelData[0] = iw;
        }
    }
  else if ([_colorSpace isEqual: NSDeviceBlackColorSpace]
           || [_colorSpace isEqual: NSCalibratedBlackColorSpace])
    {
      unsigned int iw, ia;
      float fw, fa;
      float scale;

      scale = (float)((1 << _bitsPerSample) - 1);
      [conv getWhite: &fw alpha: &fa];
      if (_hasAlpha)
        {
          if (_format & NSAlphaNonpremultipliedBitmapFormat)
            {
              iw = scale * (1 - fw);
            }
          else
            {
              iw = scale * (1 - fw) * fa;
            }
          ia = scale * fa;

          // This order depends on the bitmap format
          if (_format & NSAlphaFirstBitmapFormat)
            {
              pixelData[0] = ia;
              pixelData[1] = iw;
            }
          else
            {
              pixelData[0] = iw;
              pixelData[1] = ia;
            }
        }
      else
        {
          iw = scale * (1 - fw);
          pixelData[0] = iw;
        }
    }
  else if ([_colorSpace isEqual: NSDeviceCMYKColorSpace])
    {
      unsigned int ic, im, iy, ib, ia;
      float fc, fm, fy, fb, fa;
      float scale;

      scale = (float)((1 << _bitsPerSample) - 1);
      [conv getCyan: &fc magenta: &fm yellow: &fy black: &fb alpha: &fa];
      if(_hasAlpha)
        {
          if (_format & NSAlphaNonpremultipliedBitmapFormat)
            {
              ic = scale * fc;
              im = scale * fm;
              iy = scale * fy;
              ib = scale * fb;
            }
          else
            {
              ic = scale * fc * fa;
              im = scale * fm * fa;
              iy = scale * fy * fa;
              ib = scale * fb * fa;
            }
          ia = scale * fa;

          // This order depends on the bitmap format
          if (_format & NSAlphaFirstBitmapFormat)
            {
              pixelData[0] = ia;
              pixelData[1] = ic;
              pixelData[2] = im;
              pixelData[3] = iy;
              pixelData[4] = ib;
            }
          else
            {
              pixelData[0] = ic;
              pixelData[1] = im;
              pixelData[2] = iy;
              pixelData[3] = ib;
              pixelData[4] = ia;
            }
        }
      else
        {
          ic = scale * fc;
          im = scale * fm;
          iy = scale * fy;
          ib = scale * fb;
          // This order depends on the bitmap format
          pixelData[0] = ic;
          pixelData[1] = im;
          pixelData[2] = iy;
          pixelData[3] = ib;
        }          
    }
  else
    {
      // FIXME: Other colour spaces not implemented
      return;
    }

	[self setPixel: pixelData atX: x y: y];
}

- (void) _premultiply
{
  int x, y;
	unsigned int pixelData[5];
  int start, end, i, ai;
  SEL getPSel = @selector(getPixel:atX:y:);
  SEL setPSel = @selector(setPixel:atX:y:);
  IMP getP = [self methodForSelector: getPSel];
  IMP setP = [self methodForSelector: setPSel];

  if (!_hasAlpha || !(_format & NSAlphaNonpremultipliedBitmapFormat))
    return;

  if (_format & NSAlphaFirstBitmapFormat)
    {
      ai = 0;
      start = 1;
      end = _numColors;
    }
  else
    {
      ai = _numColors - 1;
      start = 0;
      end = _numColors - 1;
    }

  if (_bitsPerSample == 8)
    {
      unsigned int a;

      for (y = 0; y < _pixelsHigh; y++)
        {
          for (x = 0; x < _pixelsWide; x++)
            {
              //[self getPixel: pixelData atX: x y: y];
              getP(self, getPSel, pixelData, x, y);
              a = pixelData[ai];
              if (a != 255)
                {
                  for (i = start; i < end; i++)
                    {
                      unsigned int t = a * pixelData[i] + 0x80;

                      pixelData[i] = ((t >> 8) + t) >> 8;
                    }
                  //[self setPixel: pixelData atX: x y: y];
                  setP(self, setPSel, pixelData, x, y);
                }
            }
        }
    }
  else
    {
      float scale;
      float alpha;

      scale = (float)((1 << _bitsPerSample) - 1);
      for (y = 0; y < _pixelsHigh; y++)
        {
          for (x = 0; x < _pixelsWide; x++)
            {
              //[self getPixel: pixelData atX: x y: y];
              getP(self, getPSel, pixelData, x, y);
              alpha = pixelData[ai] / scale;
              for (i = start; i < end; i++)
                {
                  pixelData[i] *= alpha;
                }
              //[self setPixel: pixelData atX: x y: y];
              setP(self, setPSel, pixelData, x, y);
            }
        }
    }

  _format &= ~NSAlphaNonpremultipliedBitmapFormat;
}

- (void) _unpremultiply
{
  int x, y;
	unsigned int pixelData[5];
  int start, end, i, ai;
  SEL getPSel = @selector(getPixel:atX:y:);
  SEL setPSel = @selector(setPixel:atX:y:);
  IMP getP = [self methodForSelector: getPSel];
  IMP setP = [self methodForSelector: setPSel];

  if (!_hasAlpha || (_format & NSAlphaNonpremultipliedBitmapFormat))
    return;

  if (_format & NSAlphaFirstBitmapFormat)
    {
      ai = 0;
      start = 1;
      end = _numColors;
    }
  else
    {
      ai = _numColors - 1;
      start = 0;
      end = _numColors - 1;
    }

  if (_bitsPerSample == 8)
    {
      unsigned int a;

      for (y = 0; y < _pixelsHigh; y++)
        {
          for (x = 0; x < _pixelsWide; x++)
            {
              //[self getPixel: pixelData atX: x y: y];
              getP(self, getPSel, pixelData, x, y);
              a = pixelData[ai];
              if ((a != 0) && (a != 255))
                {
                  for (i = start; i < end; i++)
                    {
                      unsigned int c;
                      
                      c = (pixelData[i] * 255) / a;
                      if (c >= 255)
                        {
                          pixelData[i] = 255;
                        }
                      else
                        {
                          pixelData[i] = c;
                        }
                    }
                  //[self setPixel: pixelData atX: x y: y];
                  setP(self, setPSel, pixelData, x, y);
                }
            }
        }
    }
  else
    {
      float scale;
      float alpha;

      scale = (float)((1 << _bitsPerSample) - 1);
      for (y = 0; y < _pixelsHigh; y++)
        {
          unsigned int a;

          for (x = 0; x < _pixelsWide; x++)
            {
              //[self getPixel: pixelData atX: x y: y];
              getP(self, getPSel, pixelData, x, y);
              a = pixelData[ai];
              if (a != 0)
                {
                    alpha = scale / a;
                    for (i = start; i < end; i++)
                      {
                        float new = pixelData[i] * alpha;
                        
                        if (new > scale)
                          {
                            pixelData[i] = scale;
                          }
                        else
                          {
                            pixelData[i] = new;
                          }
                      }
                    //[self setPixel: pixelData atX: x y: y];
                    setP(self, setPSel, pixelData, x, y);
                }
            }
        }
    }

  _format |= NSAlphaNonpremultipliedBitmapFormat;
}

- (NSBitmapImageRep *) _convertToFormatBitsPerSample: (int)bps
                                     samplesPerPixel: (int)spp
                                            hasAlpha: (BOOL)alpha
                                            isPlanar: (BOOL)isPlanar
                                      colorSpaceName: (NSString*)colorSpaceName
                                        bitmapFormat: (NSBitmapFormat)bitmapFormat 
                                         bytesPerRow: (int)rowBytes
                                        bitsPerPixel: (int)pixelBits
{
  if (!pixelBits)
    pixelBits = bps * ((isPlanar) ? 1 : spp);
  if (!rowBytes) 
    rowBytes = ceil((float)_pixelsWide * pixelBits / 8);

  // Do we already have the correct format?
  if ((bps == _bitsPerSample) && (spp == _numColors)
      && (alpha == _hasAlpha) && (isPlanar == _isPlanar)
      && (bitmapFormat == _format) && (rowBytes == _bytesPerRow) 
      && (pixelBits == _bitsPerPixel)
      && [_colorSpace isEqualToString: colorSpaceName])
    {
      return self;
    }
  else
    {
      NSBitmapImageRep* new;
      
      new = [[NSBitmapImageRep alloc]
                initWithBitmapDataPlanes: NULL
                pixelsWide: _pixelsWide
                pixelsHigh: _pixelsHigh
                bitsPerSample: bps
                samplesPerPixel: spp
                hasAlpha: alpha
                isPlanar: isPlanar
                colorSpaceName: colorSpaceName
                bitmapFormat: bitmapFormat
                bytesPerRow: rowBytes
                bitsPerPixel: pixelBits];

      if ([_colorSpace isEqualToString: colorSpaceName] ||
          ([_colorSpace isEqualToString: NSDeviceRGBColorSpace] &&
           [colorSpaceName isEqualToString: NSCalibratedRGBColorSpace]) ||
          ([colorSpaceName isEqualToString: NSDeviceRGBColorSpace] &&
           [_colorSpace isEqualToString: NSCalibratedRGBColorSpace]))
        {
          SEL getPSel = @selector(getPixel:atX:y:);
          SEL setPSel = @selector(setPixel:atX:y:);
          IMP getP = [self methodForSelector: getPSel];
          IMP setP = [new methodForSelector: setPSel];
          unsigned int pixelData[5];
          int x, y;
          float _scale;
          float scale;

          NSDebugLLog(@"NSImage", @"Converting %@ bitmap data", _colorSpace);

          if (_bitsPerSample != bps)
            {
              _scale = (float)((1 << _bitsPerSample) - 1);
              scale = (float)((1 << bps) - 1);
            }
          else
            {
              _scale = 1.0;
              scale = 1.0;
            }

          for (y = 0; y < _pixelsHigh; y++)
            {
              for (x = 0; x < _pixelsWide; x++)
                {
                  unsigned int iv[4], ia;
                  float fv[4], fa;
                  int i;

                 //[self getPixel: pixelData atX: x y: y];
                  getP(self, getPSel, pixelData, x, y);

                  if (_hasAlpha)
                    {
                      // This order depends on the bitmap format
                      if (_format & NSAlphaFirstBitmapFormat)
                        {
                          ia = pixelData[0];
                          for (i = 0; i < _numColors - 1; i++)
                            {
                              iv[i] = pixelData[i + 1];
                            }
                        }
                      else
                        {
                          for (i = 0; i < _numColors - 1; i++)
                            {
                              iv[i] = pixelData[i];
                            }
                          ia = pixelData[_numColors - 1];
                        }

                      // Scale to [0.0 ... 1.0]
                      for (i = 0; i < _numColors - 1; i++)
                        {
                          fv[i] = iv[i] / _scale;
                        }
                      fa = ia / _scale;

                      if ((_format & NSAlphaNonpremultipliedBitmapFormat) !=
                          (bitmapFormat & NSAlphaNonpremultipliedBitmapFormat))
                        {
                          if (_format & NSAlphaNonpremultipliedBitmapFormat)
                            {
                              for (i = 0; i < _numColors - 1; i++)
                                {
                                  fv[i] = fv[i] * fa;
                                }
                            }
                          else
                            {
                              for (i = 0; i < _numColors - 1; i++)
                                {
                                  fv[i] = fv[i] / fa;
                                }
                            }
                        }
                    }
                  else 
                    {
                      for (i = 0; i < _numColors; i++)
                        {
                          iv[i] = pixelData[i];
                        }
                      // Scale to [0.0 ... 1.0]
                      for (i = 0; i < _numColors; i++)
                        {
                          fv[i] = iv[i] / _scale;
                        }
                      fa = 1.0;
                    }
                  
                  if (alpha)
                    {
                      // Scale from [0.0 ... 1.0]
                      for (i = 0; i < _numColors; i++)
                        {
                          iv[i] = fv[i] * scale;
                        }
                      ia = fa * scale;

                      if (bitmapFormat & NSAlphaFirstBitmapFormat)
                        {
                          pixelData[0] = ia;
                          for (i = 0; i < spp - 1; i++)
                            {
                              pixelData[i + 1] = iv[i];
                            }
                        }
                      else
                        {
                          for (i = 0; i < spp - 1; i++)
                            {
                              pixelData[i] = iv[i];
                            }
                          pixelData[spp -1] = ia;
                        }
                    }
                  else
                    {
                      // Scale from [0.0 ... 1.0]
                      for (i = 0; i < spp; i++)
                        {
                          pixelData[i] = fv[i] * scale;
                        }
                    }

                  //[new setPixel: pixelData atX: x y: y];
                  setP(new, setPSel, pixelData, x, y);
                }
            }
        }
      else if (([colorSpaceName isEqualToString: NSDeviceRGBColorSpace] ||
               [colorSpaceName isEqualToString: NSCalibratedRGBColorSpace])
          && ([_colorSpace isEqualToString: NSCalibratedWhiteColorSpace] ||
              [_colorSpace isEqualToString: NSCalibratedBlackColorSpace] ||
              [_colorSpace isEqualToString: NSDeviceWhiteColorSpace] ||
              [_colorSpace isEqualToString: NSDeviceBlackColorSpace]))
        {
          SEL getPSel = @selector(getPixel:atX:y:);
          SEL setPSel = @selector(setPixel:atX:y:);
          IMP getP = [self methodForSelector: getPSel];
          IMP setP = [new methodForSelector: setPSel];
          unsigned int pixelData[4];
          int x, y;
          float _scale;
          float scale;
          int max = (1 << bps) - 1;
          BOOL isWhite = [_colorSpace isEqualToString: NSCalibratedWhiteColorSpace] 
              || [_colorSpace isEqualToString: NSDeviceWhiteColorSpace];

          NSDebugLLog(@"NSImage", @"Converting black/white bitmap data");

          if (_bitsPerSample != bps)
            {
              _scale = (float)((1 << _bitsPerSample) - 1);
              scale = (float)((1 << bps) - 1);
            }
          else
            {
              _scale = 1.0;
              scale = 1.0;
            }

          for (y = 0; y < _pixelsHigh; y++)
            {
              for (x = 0; x < _pixelsWide; x++)
                {
                  unsigned int iv, ia;
                  float fv, fa;

                 //[self getPixel: pixelData atX: x y: y];
                  getP(self, getPSel, pixelData, x, y);

                  if (_hasAlpha)
                    {
                      // This order depends on the bitmap format
                      if (_format & NSAlphaFirstBitmapFormat)
                        {
                          ia = pixelData[0];
                          if (isWhite)
                            iv = pixelData[1];
                          else
                            iv = max - pixelData[1];
                        }
                      else
                        {
                          if (isWhite)
                            iv = pixelData[0];
                          else
                            iv = max - pixelData[0];
                          ia = pixelData[1];
                        }

                      // Scale to [0.0 ... 1.0]
                      fv = iv / _scale;
                      fa = ia / _scale;

                      if ((_format & NSAlphaNonpremultipliedBitmapFormat) !=
                          (bitmapFormat & NSAlphaNonpremultipliedBitmapFormat))
                        {
                          if (_format & NSAlphaNonpremultipliedBitmapFormat)
                            {
                              fv = fv * fa;
                            }
                          else
                            {
                              fv = fv / fa;
                            }
                        }
                    }
                  else 
                    {
                      if (isWhite)
                        iv = pixelData[0];
                      else
                        iv = max - pixelData[0];
                      // Scale to [0.0 ... 1.0]
                      fv = iv / _scale;
                      fa = 1.0;
                    }
                  
                  if (alpha)
                    {
                      // Scale from [0.0 ... 1.0]
                      iv = fv * scale;
                      ia = fa * scale;

                      if (bitmapFormat & NSAlphaFirstBitmapFormat)
                        {
                          pixelData[0] = ia;
                          pixelData[1] = iv;
                          pixelData[2] = iv;
                          pixelData[3] = iv;
                        }
                      else
                        {
                          pixelData[0] = iv;
                          pixelData[1] = iv;
                          pixelData[2] = iv;
                          pixelData[3] = ia;
                        }
                    }
                  else
                    {
                      // Scale from [0.0 ... 1.0]
                      iv = fv * scale;
                      pixelData[0] = iv;
                      pixelData[1] = iv;
                      pixelData[2] = iv;
                    }

                  //[new setPixel: pixelData atX: x y: y];
                  setP(new, setPSel, pixelData, x, y);
                }
            }
        }
      else
        {
          SEL getCSel = @selector(colorAtX:y:);
          SEL setCSel = @selector(setColor:atX:y:);
          IMP getC = [self methodForSelector: getCSel];
          IMP setC = [new methodForSelector: setCSel];
          int i, j;

          NSDebugLLog(@"NSImage", @"Slow converting %@ bitmap data to %@", 
                      _colorSpace, colorSpaceName);
          for (j = 0; j < _pixelsHigh; j++)
            {
              CREATE_AUTORELEASE_POOL(pool);
              
              for (i = 0; i < _pixelsWide; i++)
                {
                  NSColor *c;
                  
                  //c = [self colorAtX: i y: j];
                  c = getC(self, getCSel, i, j);
                  //[new setColor: c atX: i y: j];
                  setC(new, setCSel, c, i, j);
                }
              RELEASE(pool);
            }
        }

      return AUTORELEASE(new);
    }  
}

@end
