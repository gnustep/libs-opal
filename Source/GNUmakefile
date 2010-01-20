include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = opal

$(LIBRARY_NAME)_C_FILES = $(wildcard *.c)
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

ADDITIONAL_CFLAGS = -Wall -g -std=gnu99

ADDITIONAL_CPPFLAGS = \
	$(shell pkg-config --cflags freetype2) \
	$(shell pkg-config --cflags cairo)
	
ADDITIONAL_LDFLAGS = \
	$(shell pkg-config --libs freetype2) \
	$(shell pkg-config --libs cairo) \
	-lfontconfig -lX11 -lXrender -lm

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
