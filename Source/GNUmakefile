include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = opal

$(LIBRARY_NAME)_OBJC_FILES = $(wildcard *.m)
$(LIBRARY_NAME)_OBJC_FILES += $(wildcard cairo/*.m)
$(LIBRARY_NAME)_OBJC_FILES += $(wildcard image/*.m)

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
	CGGradient.h \
	CGImage.h \
	CGImageDestination.h \
	CGImageSource.h \
	CGLayer.h \
	CGPath.h \
	CGPattern.h \
	CGPDFArray.h \
	CGPDFContentStream.h \
	CGPDFContext.h \
	CGPDFDictionary.h \
	CGPDFDocument.h \
	CGPDFObject.h \
	CGPDFOperatorTable.h \
	CGPDFPage.h \
	CGPDFScanner.h \
	CGPDFString.h \
	CGPDFStream.h \
	CGPSConverter.h \
	CGShading.h \
	CoreGraphics.h

ADDITIONAL_OBJCFLAGS += -Wall -g -O0 -std=gnu99
ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags cairo)
ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags lcms)

ifneq ($(GNUSTEP_TARGET_OS), mingw32)
ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags freetype2)
ADDITIONAL_LDFLAGS += $(shell pkg-config --libs freetype2) -lfontconfig -lX11 -lXrender -lm 
ADDITIONAL_LDFLAGS += $(shell pkg-config --libs cairo) -lgnustep-corebase
else
ADDITIONAL_CPPFLAGS += -D__MINGW__
LIBRARIES_DEPEND_UPON = -lgdi32 -lcairo -lgnustep-corebase
endif

LIBRARIES_DEPEND_UPON += $(shell pkg-config --libs lcms)
LIBRARIES_DEPEND_UPON += $(shell pkg-config --libs libpng)
LIBRARIES_DEPEND_UPON += -ljpeg

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
