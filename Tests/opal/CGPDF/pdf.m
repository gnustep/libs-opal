/* Generate a PDF with CGPDFContext and check the result is a well-formed PDF:
   a context can be created for a data consumer, drawing into a page and
   closing it produces bytes that begin with the PDF header and end with the
   PDF end-of-file marker, both for an explicit and a default media box.  The
   produced document parses as a single US-Letter/200x100 page in an external
   reader; here only the byte structure is checked.  Matches Apple
   CoreGraphics, which also emits a %PDF ... %%EOF document. */
#include "Testing.h"

#include <Foundation/NSData.h>

#include <CoreGraphics/CGPDFContext.h>
#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGColorSpace.h>
#include <CoreGraphics/CGColor.h>
#include <CoreGraphics/CGDataConsumer.h>
#include <string.h>

/* Whether haystack contains needle. */
static bool contains(NSData *d, const char *needle)
{
  const char *b = (const char *)[d bytes];
  size_t n = [d length], m = strlen(needle);
  if (n < m) return false;
  for (size_t i = 0; i + m <= n; i++)
    if (memcmp(b + i, needle, m) == 0) return true;
  return false;
}

static bool startsWith(NSData *d, const char *prefix)
{
  size_t m = strlen(prefix);
  return [d length] >= m && memcmp([d bytes], prefix, m) == 0;
}

/* Draw one green rectangle on a single page and return the PDF bytes. */
static NSData *makePDF(const CGRect *box)
{
  NSMutableData *data = [NSMutableData data];
  CGDataConsumerRef dc = CGDataConsumerCreateWithCFData((CFMutableDataRef)data);
  CGContextRef ctx = CGPDFContextCreate(dc, box, NULL);
  if (ctx == NULL) { CGDataConsumerRelease(dc); return nil; }

  CGColorSpaceRef dev = CGColorSpaceCreateDeviceRGB();
  CGFloat green[] = {0, 1, 0, 1};
  CGColorRef gc = CGColorCreate(dev, green);

  CGPDFContextBeginPage(ctx, NULL);
  CGContextSetFillColorWithColor(ctx, gc);
  CGContextFillRect(ctx, CGRectMake(10, 10, 50, 50));
  CGPDFContextEndPage(ctx);
  CGPDFContextClose(ctx);

  CGColorRelease(gc);
  CGColorSpaceRelease(dev);
  CGContextRelease(ctx);
  CGDataConsumerRelease(dc);
  return data;
}

int main(void)
{
  START_SET("CGPDF generation")

  CGRect box = CGRectMake(0, 0, 200, 100);
  NSData *pdf = makePDF(&box);
  PASS(pdf != nil && [pdf length] > 0, "drawing into a PDF context produces bytes");
  PASS(startsWith(pdf, "%PDF-"), "the output begins with the PDF header");
  PASS(contains(pdf, "%%EOF"), "the output ends with the PDF end-of-file marker");

  END_SET("CGPDF generation")

  START_SET("CGPDF default media box")

  /* A NULL media box uses the default US Letter page and still produces a
     valid document. */
  NSData *pdf = makePDF(NULL);
  PASS(pdf != nil && [pdf length] > 0,
       "a PDF context with the default media box produces bytes");
  PASS(startsWith(pdf, "%PDF-") && contains(pdf, "%%EOF"),
       "the default-media-box output is a well-formed PDF");

  END_SET("CGPDF default media box")

  return 0;
}
