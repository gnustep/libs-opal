#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#else
#include <CoreGraphics/CoreGraphics.h>
#include <CoreText/CoreText.h>

#if 0
NSRange CFRangeMake(NSUInteger loc, NSUInteger len)
{
  return NSMakeRange(loc, len);
}
#endif

#endif

#import <Foundation/Foundation.h>

void dumpFontDescriptorInfo(CTFontDescriptorRef descriptor)
{
  printf("Dumping font descriptor info for %p\n", descriptor);

  NSLog(@"Attribute dictionary: %@", [CTFontDescriptorCopyAttributes(descriptor) autorelease]);

  NSArray *allAttributes = [NSArray arrayWithObjects:
      kCTFontURLAttribute,
      kCTFontNameAttribute,
      kCTFontDisplayNameAttribute,
      kCTFontFamilyNameAttribute,
      kCTFontStyleNameAttribute,
      kCTFontTraitsAttribute,
      kCTFontVariationAttribute,
      kCTFontSizeAttribute,
      kCTFontMatrixAttribute,
      kCTFontCascadeListAttribute,
      kCTFontCharacterSetAttribute,
      kCTFontLanguagesAttribute,
      kCTFontBaselineAdjustAttribute,
      kCTFontMacintoshEncodingsAttribute,
      kCTFontFeaturesAttribute,
      kCTFontFeatureSettingsAttribute,
      kCTFontFixedAdvanceAttribute,
      kCTFontOrientationAttribute,
      kCTFontEnabledAttribute,
      kCTFontFormatAttribute,
      kCTFontRegistrationScopeAttribute,
      kCTFontPriorityAttribute,
      nil];

  NSLog(@"Attributes fetched via CTFontDescriptorCopyAttribute:");

  NSEnumerator *attribEnumerator = [allAttributes objectEnumerator];
  NSString *attrib;
  while (attrib = [attribEnumerator nextObject])
  {
    NSLog(@"Value for '%@': %@", attrib, [CTFontDescriptorCopyAttribute(descriptor, (CFStringRef)attrib) autorelease]);
  }
}

void dumpFontInfo(CTFontRef font)
{
  printf("Dumping font info for %p\n", font);
  
/* Glyphs */

  CFIndex glyphs = CTFontGetGlyphCount(font);
  for (CGGlyph i=0; i<glyphs; i++)
  {
    CGSize advances;
    double advance = CTFontGetAdvancesForGlyphs(font, kCTFontDefaultOrientation, &i, &advances, 1);
    NSLog(@"CTFontGetAdvancesForGlyphs %d returned %lf, and gave advance (%lf, %lf)", i, advance, (double)advances.width, (double)advances.height);
    
    CGRect rects;
    CGRect rect = CTFontGetBoundingRectsForGlyphs(font, kCTFontDefaultOrientation, &i, &rects, 1);    
    NSLog(@"CTFontGetBoundingRectsForGlyphs %d returned ((%lf,%lf),(%lf,%lf)), and gave rect ((%lf,%lf),(%lf,%lf))", i, 
      (double)rect.origin.x, (double)rect.origin.y, (double)rect.size.width, (double)rect.size.height,
      (double)rects.origin.x, (double)rects.origin.y, (double)rects.size.width, (double)rects.size.height);
        
    CGSize translations;
    CTFontGetVerticalTranslationsForGlyphs(font, &i, &translations, 1);
    NSLog(@"CTFontGetVerticalTranslationsForGlyphs %d gave translation (%lf, %lf)", i, advance, (double)translations.width, (double)translations.height);
    
    if (i == 20)
    {
      NSLog(@"---Only showing first 20 glyphs---");
      break;
    }
  }

/*
CGPathRef CTFontCreatePathForGlyph(
  font,
  CGGlyph glyph,
  const CGAffineTransform *transform
);

bool CTFontGetGlyphsForCharacters(
  font,
  const UniChar characters[],
  CGGlyph glyphs[],
  CFIndex count
);*/

  NSLog(@"CTFontGetGlyphWithName('a'): %d", CTFontGetGlyphWithName(font, (CFStringRef)@"a"));

/* Metrics */

  NSLog(@"CTFontGetAscent %lf", (double)CTFontGetAscent(font));

  NSLog(@"CTFontGetDescent %lf", (double)CTFontGetDescent(font));

  NSLog(@"CTFontGetCapHeight %lf", (double)CTFontGetCapHeight(font));

  NSLog(@"CTFontGetSize %lf", (double)CTFontGetSize(font));

  NSLog(@"CTFontGetLeading %lf", (double)CTFontGetLeading(font));

  NSLog(@"CTFontGetUnitsPerEm %d", CTFontGetUnitsPerEm(font));
  
  CGRect bbox = CTFontGetBoundingBox(font);
  NSLog(@"CTFontGetBoundingBox ((%lf,%lf),(%lf,%lf))", (double)bbox.origin.x, (double)bbox.origin.y, (double)bbox.size.width, (double)bbox.size.height);

  NSLog(@"CTFontGetUnderlinePosition %lf", (double)CTFontGetUnderlinePosition(font));

  NSLog(@"CTFontGetUnderlineThickness %lf", (double)CTFontGetUnderlineThickness(font));

  NSLog(@"CTFontGetSlantAngle %lf", (double)CTFontGetSlantAngle(font));

  NSLog(@"CTFontGetXHeight %lf", (double)CTFontGetXHeight(font));

  /* Properties */

  CGAffineTransform xform = CTFontGetMatrix(font);
  NSLog(@"CTFontGetMatrix %lf %lf %lf %lf %lf %lf", (double)xform.a, (double)xform.b, (double)xform.c, (double)xform.d, (double)xform.tx, (double)xform.ty);
   
  NSLog(@"CTFontGetSymbolicTraits %d", CTFontGetSymbolicTraits(font));

  NSLog(@"CTFontCopyAvailableTables: ");
  NSArray *availableTables = [CTFontCopyAvailableTables(font, kCTFontTableOptionNoOptions) autorelease];
  for (NSUInteger i=0; i<[availableTables count]; i++)
  {
    // Ugly!
    int table = NSSwapBigIntToHost((int)[availableTables objectAtIndex: i]);
    char *tableName = (char*)&table;
    printf("%c%c%c%c, ", tableName[0], tableName[1], tableName[2], tableName[3]);
  }
  printf("\n");

  NSLog(@"CTFontCopyTraits %@",  [CTFontCopyTraits(font) autorelease]);

  NSLog(@"CTFontCopyFeatures %@",  [CTFontCopyFeatures(font) autorelease]);

  NSLog(@"CTFontCopyFeatureSettings %@",  [CTFontCopyFeatureSettings(font) autorelease]);

  NSLog(@"CTFontCopyFontDescriptor %@",  [CTFontCopyFontDescriptor(font) autorelease]);

/*CFDataRef CTFontCopyTable(
  font,
  CTFontTableTag table,
  CTFontTableOptions opts
);*/

  NSLog(@"CTFontCopyVariationAxes %@", [CTFontCopyVariationAxes(font) autorelease]);

  NSLog(@"CTFontCopyVariation %@", [CTFontCopyVariation(font) autorelease]);

/* Encoding & Character Set */

  NSLog(@"CTFontGetStringEncoding %d", CTFontGetStringEncoding(font));

  NSLog(@"CTFontCopyCharacterSet %@", [CTFontCopyCharacterSet(font) autorelease]);

  NSLog(@"CTFontCopySupportedLanguages %@", [CTFontCopySupportedLanguages(font) autorelease]);

/* Name */

  NSLog(@"CTFontCopyDisplayName %@", [CTFontCopyDisplayName(font) autorelease]);

  NSArray *nameKeys = [NSArray arrayWithObjects:
     kCTFontCopyrightNameKey,
     kCTFontFamilyNameKey,
     kCTFontSubFamilyNameKey,
     kCTFontStyleNameKey,
     kCTFontUniqueNameKey,
     kCTFontFullNameKey,
     kCTFontVersionNameKey,
     kCTFontPostScriptNameKey,
     kCTFontTrademarkNameKey,
     kCTFontManufacturerNameKey,
     kCTFontDesignerNameKey,
     kCTFontDescriptionNameKey,
     kCTFontVendorURLNameKey,
     kCTFontDesignerURLNameKey,
     kCTFontLicenseNameKey,
     kCTFontLicenseURLNameKey,
     kCTFontSampleTextNameKey,
     kCTFontPostScriptCIDNameKey,
     nil];
  
  NSEnumerator *enumerator = [nameKeys objectEnumerator];
  NSString *nameKey;
  while (nameKey = [enumerator nextObject])
  {
    NSLog(@"Name for '%@': %@", nameKey, [CTFontCopyName(font, nameKey) autorelease]);
  }
  
  enumerator = [nameKeys objectEnumerator];
  while (nameKey = [enumerator nextObject])
  {
    NSString *lang = nil;
    NSString *localName = [CTFontCopyLocalizedName(font, nameKey, &lang) autorelease];
    NSLog(@"Localized name for '%@': %@ (lang=%@)", nameKey, localName, lang);
  }

  NSLog(@"CTFontCopyPostScriptName %@", [CTFontCopyPostScriptName(font) autorelease]);
  NSLog(@"CTFontCopyFamilyName %@", [CTFontCopyFamilyName(font) autorelease]);
  NSLog(@"CTFontCopyFullName %@", [CTFontCopyFullName(font) autorelease]);
}


void enumerateBySerifStyle()
{
  NSLog(@"Listing fonts sorted by serif style:");
  
  CTFontDescriptorRef dummyDescriptor = [CTFontDescriptorCreateWithAttributes([NSDictionary dictionary]) autorelease];
  NSArray *allDescriptors = [CTFontDescriptorCreateMatchingFontDescriptors(dummyDescriptor, nil) autorelease];


  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  
  NSEnumerator *enumerator = [allDescriptors objectEnumerator];
  CTFontDescriptorRef descriptor;
  while (descriptor = [enumerator nextObject])
  {
    CTFontSymbolicTraits t = [[[descriptor objectForKey: kCTFontTraitsAttribute] objectForKey: kCTFontSymbolicTrait] intValue];
    t &= kCTFontClassMaskTrait;
    
    NSString *symbolicTraitString;
    switch (t)
    {
      default:
      case kCTFontUnknownClass:
        symbolicTraitString = @"kCTFontUnknownClass";
        break;
      case kCTFontOldStyleSerifsClass:
        symbolicTraitString = @"kCTFontOldStyleSerifsClass";
        break;
      case kCTFontTransitionalSerifsClass:
        symbolicTraitString = @"kCTFontTransitionalSerifsClass"; 
        break;
      case kCTFontModernSerifsClass:
        symbolicTraitString = @"kCTFontModernSerifsClass"; 
        break;
      case kCTFontClarendonSerifsClass:
        symbolicTraitString = @"kCTFontClarendonSerifsClass"; 
        break;
      case kCTFontSlabSerifsClass:
        symbolicTraitString = @"kCTFontSlabSerifsClass"; 
        break;
      case kCTFontFreeformSerifsClass:
        symbolicTraitString = @"kCTFontFreeformSerifsClass"; 
        break;
      case kCTFontSansSerifClass:
        symbolicTraitString = @"kCTFontSansSerifClass"; 
        break;
      case kCTFontOrnamentalsClass:
        symbolicTraitString = @"kCTFontOrnamentalsClass"; 
        break;
      case kCTFontScriptsClass:
        symbolicTraitString = @"kCTFontScriptsClass"; 
        break;
      case kCTFontSymbolicClass:
        symbolicTraitString = @"kCTFontSymbolicClass"; 
        break;
    }
    
    if (nil == [dict objectForKey: symbolicTraitString])
    {
      [dict setObject: [NSMutableArray array] forKey: symbolicTraitString];
    }
    [[dict objectForKey: symbolicTraitString] addObject: descriptor];
  }
  
  enumerator = [dict keyEnumerator];
  NSString *symbolicTraitString;
  while (symbolicTraitString = [enumerator nextObject])
  {
    NSArray *descriptors = [dict objectForKey: symbolicTraitString];
    NSLog(@"%@ fonts: (%d)", symbolicTraitString, [descriptors count]);
    
    NSEnumerator *enumerator2 = [descriptors objectEnumerator];
    while (descriptor = [enumerator2 nextObject])
    {
      NSLog(@"\t%@", [descriptor objectForKey: kCTFontDisplayNameAttribute]);
    }
  }
}

void draw(CGContextRef ctx, CGRect rect)
{
  CTFontDescriptorRef desc = [CTFontDescriptorCreateWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:
    @"Times-Roman", kCTFontNameAttribute,
    nil]) autorelease];

  NSLog(@"Times initial descriptor: %@", [desc fontAttributes]);

  dumpFontDescriptorInfo(desc);

  /**
   * Matched with a real font.
   */
  NSLog(@"Times initial descriptor URL: %@", [desc objectForKey: kCTFontURLAttribute]);

  
  CTFontRef font = CTFontCreateWithFontDescriptor(desc, 0, NULL);
  
  NSLog(@"Attributes after creating Times font: %@", [[font fontDescriptor] fontAttributes]);
  /**
   * Note this should print the URL even though it's not in the dictionary
   * printed on the previous line
   */
  NSLog(@"Times font URL: %@", [CTFontCopyAttribute(font, kCTFontURLAttribute) autorelease]);

  CTFontDescriptorRef monoDesc = [CTFontDescriptorCreateWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:
    [NSDictionary dictionaryWithObjectsAndKeys: 
      [NSNumber numberWithInt: kCTFontMonoSpaceTrait], kCTFontSymbolicTrait,
       nil
    ], kCTFontTraitsAttribute,
    nil]) autorelease];
  
  
  NSLog(@"Monospaced font attributes: %@ URL: %@", [monoDesc fontAttributes], [monoDesc objectForKey: kCTFontURLAttribute]);

  dumpFontDescriptorInfo(monoDesc);

  CTFontDescriptorRef monoDescMatching = [CTFontDescriptorCreateMatchingFontDescriptor(monoDesc, [NSSet setWithObject: kCTFontTraitsAttribute]) autorelease];
  NSLog(@"Monospaced font attribute after matching: %@ URL: %@", [monoDescMatching fontAttributes], [monoDescMatching objectForKey: kCTFontURLAttribute]);  

  NSLog(@"Family name of font created with monoDesc: %@", [[CTFontCreateWithFontDescriptor(monoDesc, 12, NULL) autorelease] familyName]);
  NSLog(@"Family name of font created with monoDescMatching: %@", [[CTFontCreateWithFontDescriptor(monoDescMatching, 12, NULL) autorelease] familyName]);  
  
  NSArray *monospaceFonts = [CTFontDescriptorCreateMatchingFontDescriptors(monoDesc, [NSSet setWithObject: kCTFontTraitsAttribute]) autorelease];
  NSLog(@"All monospace font descriptors on the system: %@", monospaceFonts);
  
  // A test string
  NSString *hamlet = @"Ay, marry, is't;\nBut to my mind, though I am native here\nAnd to the manner born, it is a custom\nMore honour'd in the breach than the observance.\nThis heavy-headed revel east and west\nMakes us traduc'd and tax'd of other nations;\nThey clip us drunkards and with swinish phrase\nSoil our addition; and indeed it takes\nFrom our achievements, though perform'd at height,\nThe pith and marrow of our attribute.\nSo oft it chances in particular men\nThat, for some vicious mole of nature in them,\nAs in their birth,- wherein they are not guilty,\nSince nature cannot choose his origin,-\nBy the o'ergrowth of some complexion,\nOft breaking down the pales and forts of reason,\nOr by some habit that too much o'erleavens\nThe form of plausive manners, that these men\nCarrying, I say, the stamp of one defect,\nBeing nature's livery, or fortune's star,\nTheir virtues else- be they as pure as grace,\nAs infinite as man may undergo-\nShall in the general censure take corruption\nFrom that particular fault. The dram of e'il\nDoth all the noble substance often dout To his own scandal.\n";

  CGMutablePathRef path = [CGPathCreateMutable() autorelease];
  CGPathAddRect(path, NULL, CGRectMake(rect.origin.x, rect.origin.y + 100, rect.size.width/2, rect.size.height - 200));
  CGContextAddPath(ctx, path);
  CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);
  CGContextStrokePath(ctx);
  
  NSAttributedString *as = [[[NSMutableAttributedString alloc] initWithString: hamlet] autorelease];
  CTFramesetterRef fs = [CTFramesetterCreateWithAttributedString(as) autorelease];

  CTFrameRef frame = [CTFramesetterCreateFrame(fs, CFRangeMake(0,0), path, NULL) autorelease];
  CTFrameDraw(frame, ctx);
  
  
  dumpFontInfo(font);

  enumerateBySerifStyle();
}
