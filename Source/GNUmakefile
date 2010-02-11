include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = opal

$(LIBRARY_NAME)_OBJC_FILES = $(wildcard *.m)
$(LIBRARY_NAME)_HEADER_FILES_DIR = ../Headers/CoreGraphics
$(LIBRARY_NAME)_INCLUDE_DIRS = -I../Headers
$(LIBRARY_NAME)_HEADER_FILES_INSTALL_DIR = CoreGraphics
$(LIBRARY_NAME)_HEADER_FILES = \
	CGAffineTransform.h \
	CGBase.h \
	CGBitmapContext.h \
	CGColor.h \
	CGColorSpace.h \
	CGContext.h \
	CGDataConsumer.h \
	CGDataProvider.h \
	CGFont.h \
	CGFunction.h \
	CGGeometry.h \
	CGImage.h \
	CGLayer.h \
	CGPDFContext.h \
	CGPDFDocument.h \
	CGPath.h \
	CGPattern.h \
	CGShading.h

ADDITIONAL_OBJCFLAGS += -Wall -g -std=gnu99

# Use := to compute the flags we need so that the subshells are
# spawned only once
OPAL_CPPFLAGS := $(shell pkg-config --cflags freetype2) \
	         $(shell pkg-config --cflags cairo)

# Then add them to ADDITIONAL_CPPFLAGS
ADDITIONAL_CPPFLAGS += $(OPAL_CPPFLAGS)


OPAL_LDFLAGS := $(shell pkg-config --libs freetype2) \
		$(shell pkg-config --libs cairo)

ADDITIONAL_LDFLAGS += \
	$(OPAL_LDFLAGS) \
	-lfontconfig -lX11 -lXrender -lm

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
