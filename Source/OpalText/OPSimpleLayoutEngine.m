/** <title>OPSimpleLayoutEngine</title>

   <abstract>C Interface to text layout library</abstract>

   Copyright <copy>(C) 2011 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Mar 2011

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */


#import "OPSimpleLayoutEngine.h"
#import "CTRun-private.h"
#import <CoreText/CTFont.h>
#import <CoreText/CTStringAttributes.h>

@implementation OPSimpleLayoutEngine

- (CTRunRef) layoutString: (NSString*)chars
	   withAttributes: (NSDictionary*)attribs
{
  const NSUInteger length = [chars length];
  CGGlyph *glyphs;
  unichar *characters;
  CGSize *advances;
  CTFontRef font = [attribs objectForKey: (id)kCTFontAttributeName];
  CTRun *run = nil;

  if (length == 0)
  {
    return nil;
  }

  if (font == nil)
  {
    /* A string with no font of its own is set in the face and size the
       typesetter falls back to. */
    font = CTFontCreateWithName((CFStringRef)@"Helvetica", 12, NULL);
  }
  else
  {
    [(id)font retain];
  }
  if (font == nil)
  {
    NSLog(@"OPSimpleLayoutEngine: no font to lay the string out with");
    return nil;
  }

  glyphs = malloc(sizeof(CGGlyph) * length);
  characters = malloc(sizeof(unichar) * length);
  advances = malloc(sizeof(CGSize) * length);
  if (glyphs != NULL && characters != NULL && advances != NULL)
  {
    [chars getCharacters: characters range: NSMakeRange(0, length)];

    if (CTFontGetGlyphsForCharacters(font, characters, glyphs, length))
    {
      NSMutableDictionary *used = (attribs == nil)
	? [NSMutableDictionary dictionary]
	: [[attribs mutableCopy] autorelease];

      CTFontGetAdvancesForGlyphs(font,
				 kCTFontDefaultOrientation,
				 glyphs,
				 advances,
				 length);

      /* The run keeps the font it was laid out with, which is the one the
	 caller asked for or the fallback chosen above. */
      [used setObject: (id)font forKey: (id)kCTFontAttributeName];
      run = [[[CTRun alloc] initWithGlyphs: glyphs
				  advances: advances
				     count: length
				attributes: used
			       stringRange: CFRangeMake(0, length)]
	      autorelease];
    }
  }

  free(glyphs);
  free(characters);
  free(advances);
  [(id)font release];
  return run;
}

@end

