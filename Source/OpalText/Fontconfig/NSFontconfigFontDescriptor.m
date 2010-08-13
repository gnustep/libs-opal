/** <title>NSFontconfigFontDescriptor</title>

   <abstract>C Interface to text layout library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Aug 2010

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


@interface NSFontconfigFontDescriptor : NSFontDescriptor
{
  FcPattern *_pat;
}

- (void)addURL: (NSURL*)url
{
  NSString *path = [url path];
  if ([url isFileURL] && path != nil)
  {
    FcPatternAddString(_pat, FC_FILE, [path UTF8String]);
  }
  else
  {
    NSLog(@"Warning, URL %@ is invalid", url);
  }
}

- (void)addName: (NSString*)name
{
  // FIXME: Fontconfig ignores PostScript names of fonts; we need
  // https://bugs.freedesktop.org/show_bug.cgi?id=18095 fixed.
  
  // This is a hack to guess the family name from a PostScript name
  // It will often fail because PostScript names are sometimes abbreviated

  NSMutableString *family = [NSMutableString stringWithCapacity: 50];

  // FIXME: write the hack
  /*
  const NSUInteger nameLength = [name length];
  for (NSUInteger i=0; i<nameLength; i++)
  {
    if ([
  }*/

  FcPatternAddString(_pat, FC_FAMILY, [name UTF8String]);
}

- (void)addDisplayName: (NSString*)name
{
  FcPatternAddString(_pat, FC_FULLNAME, [name UTF8String]);
}

- (void)addFamilyName: (NSString*)name
{
  FcPatternAddString(_pat, FC_FAMILY, [name UTF8String]);
}

- (void)addStyleName: (NSString*)style
{
  FcPatternAddString(_pat, FC_STYLE, [style UTF8String]);
}

- (void)addTraits: (NSDictionary*)traits
{
  if ([traits objectForKey: kCTFontSymbolicTrait])
  {
    CTFontSymbolicTraits symTraits = [traits objectForKey: kCTFontSymbolicTrait];

    if (symTraits & kCTFontItalicTrait)
    {
      // NOTE: May be overridden by kCTFontSlantTrait
      FcPatternAddInteger(_pat, FC_SLANT, FC_SLANT_ITALIC); 
    }
    if (symTraits & kCTFontBoldTrait)
    {
      // NOTE: May be overridden by kCTFontWeightTrait
      FcPatternAddInteger(_pat, FC_WEIGHT, FC_WEIGHT_BOLD); 
    }
    if (symTraits & kCTFontExpandedTrait)
    {
      // NOTE: May be overridden by kCTFontWidthTrait
      FcPatternAddInteger(_pat, FC_WIDTH, FC_WIDTH_EXPANDED);
    }
    if (symTraits & kCTFontCondensedTrait)
    {
      // NOTE: May be overridden by kCTFontWidthTrait
      FcPatternAddInteger(_pat, FC_WIDTH, FC_WIDTH_CONDENSED);
    }
    if (symTraits & kCTFontMonoSpaceTrait)
    {
      FcPatternAddInteger(_pat, FC_SPACING, FC_MONO);
    }
    if (symTraits & kCTFontVerticalTrait)
    {
      // FIXME: What is this supposed to mean?
    }
    if (symTraits & kCTFontUIOptimizedTrait)
    {
			// NOTE: Fontconfig can't express this
    }

    CTFontStylisticClass class = symbolicTraits & kCTFontClassMaskTrait;
    char *addWeakFamilyName = NULL;
    switch (class)
    {
      default:
      case kCTFontUnknownClass:
      case kCTFontOrnamentalsClass:
      case kCTFontScriptsClass:
      case kCTFontSymbolicClass:
        // FIXME: Is there some way to convey these to Fontconfig?
        break;
      case kCTFontOldStyleSerifsClass:
      case kCTFontTransitionalSerifsClass:
      case kCTFontModernSerifsClass:
      case kCTFontClarendonSerifsClass:
      case kCTFontSlabSerifsClass:
      case kCTFontFreeformSerifsClass:
		  	addWeakFamilyName = "serif";
        break;
      case kCTFontSansSerifClass:
        addWeakFamilyName = "sans";
        break;
    }
    if (addWeakFamilyName)
    {
      FcValue value;
      value.type = FcTypeString;
      value.u.s = addWeakFamilyName;
      FcPatternAddWeak(_pat, FC_FAMILY, value, FcTrue);
    }
  }

  if ([traits objectForKey: kCTFontWeightTrait])
  {
    /**
     * Scale: -1 is thinnest, 0 is normal, 1 is heaviest
     */
    double weight = [[traits objectForKey: kCTFontWeightTrait] doubleValue];
    weight = MAX(-1, MIN(1, weight));
    int fcWeight;
    if (weight <= 0)
    {
			fcWeight = FC_WEIGHT_THIN + ((weight + 1.0) * (FC_WEIGHT_NORMAL - FC_WEIGHT_THIN));
    }
    else
    {
 			fcWeight = FC_WEIGHT_NORMAL + (weight * (FC_WEIGHT_ULTRABLACK - FC_WEIGHT_NORMAL));
    }
    FcPatternAddInteger(_pat, FC_WEIGHT, fcWeight);
  }

  if ([traits objectForKey: kCTFontWidthTrait])
  {
    /**
     * Scale: -1 is most condensed, 0 is normal, 1 is most spread apart
     */
    double width = [[traits objectForKey: kCTFontWidthTrait] doubleValue];
    width = MAX(-1, MIN(1, width));
    int fcWidth;
    if (width <= 0)
    {
			fcWidth = FC_WIDTH_ULTRACONDENSED + ((width + 1.0) * (FC_WIDTH_NORMAL - FC_WIDTH_ULTRACONDENSED));
    }
    else
    {
 			fcWidth = FC_WIDTH_NORMAL + (width * (FC_WIDTH_ULTRAEXPANDED - FC_WIDTH_NORMAL));
    }
    FcPatternAddInteger(_pat, FC_WIDTH, fcWidth);
  }

  if ([traits objectForKey: kCTFontSlantTrait])
  {
    /**
     * Scale: -1 is 30 degree counterclockwise slant, 0 is no slant, 1
     * is 30 degree clockwise slant
     */
    double slant = [[traits objectForKey: kCTFontSlantTrait] doubleValue];

    // NOTE: Fontconfig can't express this as a scale
    if (slant > 0)
    {
      FcPatternAddInteger(_pat, FC_SLANT, FC_SLANT_ITALIC);
    }
    else
    {
      FcPatternAddInteger(_pat, FC_SLANT, FC_SLANT_ROMAN);
    }
  }
}

- (void)addVariation: (NSDictionary*)variationDict
{
  // NOTE: Fontconfig doesn't support variation axes
}

- (void)addSize: (NSNumber*)size
{
  FcPatternAddDouble(_pat, FC_SIZE, [size doubleValue]);
}

- (void)addMatrix: (NSData*)matrixData
{
  CGAffineTransform xform = CGAffineTransformIdentity;
  [matrixData getBytes: &xform length: sizeof(CGAffineTransform)];

  FcMatrix fcXform;
  fcXform.xx = xform.a;
  fcXform.xy = xform.b;
  fcXform.yx = xform.c;
  fcXform.yy = xform.d;
  FcPatternAddMatrix(_pat, FC_MATRIX, fcXform);
}

- (void)addCascadeList: (NSArray*)cascadeList
{
  // NOTE: Don't think we can support this
}

- (void)addCharacterSet: (NSCharacterSet*)characterSet
{
  // FIXME: Keep a cache of NSCharacterSet->FcCharSet pairs, because
  // this is really slow.

  FcCharSet *fcSet = FcCharSetCreate();
    
  for (uint32_t plane=0; plane<=16; plane++)
  {
    if ([characterSet hasMemberInPlane: plane])
    {
       for (uint32_t codePoint = plane<<16; codePoint <= 0xffff + (plane<<16); codePoint++)
       {
          if ([characterSet longCharacterIsMember: codePoint])
          {
            FcCharSetAddChar(fcSet, codePoint);
          }
       }
    }
  }

  FcPatternAddCharSet(_pat, FC_CHARSET, fcSet);
  FcCharSetDestroy(fcSet);
}

- (void)addLanguages: (NSArray*)languages
{
  FcLangSet *fcLangSet = FcLangSetCreate();

  NSUInteger languagesCount = [languages count];
  for (NSUInteger i=0; i<languagesCount; i++)
  {
    FcLangSetAdd(_pat, [[languages objectAtIndex: i] UTF8String]);
  }

  FcPatternAddLangSet(_pat, FC_LANG, fcLangSet);
  FcLangSetDestroy(fcLangSet);
}

- (void)addBaselineAdjust: (NSNumber*)baselineAdjust
{
  // NOTE: Don't think we can support this
}

- (void)addMacintoshEncodings: (NSNumber *)macintoshEncodings
{
  // NOTE: Don't think we can support this
}

- (void)addFeatures: (NSArray*)fontFeatures
{
  // NOTE: Don't think we can support this
}

- (void)addFeatureSettings: (NSArray*)fontFeatureSettings
{
  // NOTE: Don't think we can support this
}

- (void)addFixedAdvance: (NSNumber*)fixedAdvance
{
  // NOTE: Don't think we can support this
}

- (void)addOrientation: (NSNumber*)orientation
{
  CTFontOrientation orient = [orientation intValue];
  switch (orient)
  {
    default:
    case kCTFontDefaultOrientation:
    case kCTFontHorizontalOrientation:
      break;
    case kCTFontVerticalOrientation:
      FcPatternAddBool(_pat, FC_VERTICAL_LAYOUT, FcTrue);
      break;
  }
}

- (void)addFormat: (NSNumber*)format
{
  CTFontFormat fmt = [format intValue];
  switch (fmt)
  {
    default:
    case kCTFontFormatUnrecognized:
    case kCTFontFormatOpenTypePostScript:
    case kCTFontFormatOpenTypeTrueType:
    case kCTFontFormatTrueType:
    case kCTFontFormatPostScript:
      break;
    case kCTFontFormatBitmap:
      FcPatternAddBool(_pat, FC_OUTLINE, FcFalse);
      break;
  }
}

- (void)addRegistrationScope: (NSNumber*)registrationScope
{
  // NOTE: Don't think we can support this
}

- (void)addPriority: (NSNumber*)priority
{
  // NOTE: Don't think we can support this
}

- (void)addEnabled: (NSNumber*)enabled
{
  // NOTE: Don't think we can support this
}

//-------------

- (NSString*)readFontconfigString: (const char *)key
{
  unsigned char *string = NULL;
  if (FcResultMatch == FcPatternGetString(_pat, key, 0, &string))
  {
    if (string)
    {
      return [NSString stringWithUTF8String: string];
    }
  }
  return nil;
}

- (NSNumber*)readFontconfigInteger: (const char *)key
{
  
}



//-------------

- (id) initWithFontAttributes: (NSDictionary *)attributes
{
  self = [super initWithFontAttributes: attributes];
  if (nil == self)
  {
    return nil;
  }

  _pat = FcPatternCreate();
 
  // Call the corresponding add...: method for each element in the attributes dictionary
  [self handleAddValues];

  

  NSLog(@"NSFontconfigFontDescriptor: Input attributes %@", attributes);
  NSLog(@"NSFontconfigFontDescriptor: Output pattern:);
  FcPatternPrint(_pat); 

  return self;
}

- (void)dealloc
{
  FcPatternDestroy(_pat);
  [super dealloc];
}

/**
 * Overridden
 */
- (NSArray *) matchingFontDescriptorsWithMandatoryKeys: (NSSet *)keys
{

}


/**
 * Overridden
 */
- (id) objectForKey: (NSString *)attribute
{
  // First check our dictionary, if the value is not there, then ensure our fontconfig
  // pattern is "matched", and return the value from that.

  id object = [super objectForKey: attribute];

  if (nil == object)
  {
    
  }
  return object;
}

/**
 * Overridden
 */
- (id) localizedObjectForKey: (NSString*)key language: (NSString**)languageOut
{
}

@end
