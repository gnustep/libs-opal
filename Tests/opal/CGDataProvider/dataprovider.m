/* CGDataProvider: CGDataProviderCopyData returns the provider's bytes for a
   data-backed provider (from a raw buffer and from a Foundation data object)
   and for a sequential (callback) provider, and the releaseData callback given
   to CGDataProviderCreateWithData is called when the provider is released.
   Behaviour checked against Apple CoreGraphics.  The data buffers are held as
   Foundation data objects. */
#include "Testing.h"

#include <Foundation/NSData.h>

#include <CoreGraphics/CGDataProvider.h>
#include <string.h>

static const unsigned char kBytes[] = {10, 20, 30, 40, 50};

/* Sequential provider reading from a fixed buffer. */
typedef struct { const unsigned char *buf; size_t len; size_t pos; } SeqInfo;

static size_t seqGetBytes(void *info, void *buffer, size_t count)
{
  SeqInfo *s = (SeqInfo *)info;
  size_t n = count;
  if (n > s->len - s->pos) n = s->len - s->pos;
  memcpy(buffer, s->buf + s->pos, n);
  s->pos += n;
  return n;
}

static void seqRewind(void *info)
{
  ((SeqInfo *)info)->pos = 0;
}

/* releaseData callback bookkeeping. */
static int releaseCalls = 0;
static void *seenInfo = NULL;
static const void *seenData = NULL;
static size_t seenSize = 0;

static void myRelease(void *info, const void *data, size_t size)
{
  releaseCalls++;
  seenInfo = info;
  seenData = data;
  seenSize = size;
}

static bool dataEquals(NSData *d, const unsigned char *bytes, size_t len)
{
  return d != nil && [d length] == len
    && memcmp([d bytes], bytes, len) == 0;
}

int main(void)
{
  START_SET("CGDataProvider copy data")

  CGDataProviderRef pd = CGDataProviderCreateWithData(NULL, kBytes,
    sizeof(kBytes), NULL);
  NSData *fromData = (NSData *)CGDataProviderCopyData(pd);
  PASS(dataEquals(fromData, kBytes, sizeof(kBytes)),
       "CopyData returns the bytes of a raw-buffer provider");
  CGDataProviderRelease(pd);

  NSData *src = [NSData dataWithBytes: kBytes length: sizeof(kBytes)];
  CGDataProviderRef pc = CGDataProviderCreateWithCFData((CFDataRef)src);
  NSData *fromCF = (NSData *)CGDataProviderCopyData(pc);
  PASS(dataEquals(fromCF, kBytes, sizeof(kBytes)),
       "CopyData returns the bytes of a Foundation-data provider");
  CGDataProviderRelease(pc);

  SeqInfo seq = { kBytes, sizeof(kBytes), 0 };
  CGDataProviderSequentialCallbacks cb = {0, seqGetBytes, NULL, seqRewind, NULL};
  CGDataProviderRef ps = CGDataProviderCreateSequential(&seq, &cb);
  NSData *fromSeq = (NSData *)CGDataProviderCopyData(ps);
  PASS(dataEquals(fromSeq, kBytes, sizeof(kBytes)),
       "CopyData assembles the bytes of a sequential provider");
  CGDataProviderRelease(ps);

  END_SET("CGDataProvider copy data")

  START_SET("CGDataProvider releaseData")

  int marker = 0;
  releaseCalls = 0;
  CGDataProviderRef p = CGDataProviderCreateWithData(&marker, kBytes,
    sizeof(kBytes), myRelease);
  PASS(releaseCalls == 0, "releaseData is not called before the provider is released");

  CGDataProviderRelease(p);
  testHopeful = YES;
  PASS(releaseCalls == 1, "releaseData is called when the provider is released");
  PASS(seenInfo == &marker && seenData == kBytes && seenSize == sizeof(kBytes),
       "releaseData receives the original info, data and size");
  testHopeful = NO;

  END_SET("CGDataProvider releaseData")

  return 0;
}
