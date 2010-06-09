include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = opal

$(LIBRARY_NAME)_OBJC_FILES = $(wildcard *.m)
$(LIBRARY_NAME)_OBJC_FILES += $(wildcard cairo/*.m)
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
ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags cairo)


ifneq ($(GNUSTEP_TARGET_OS), mingw32)
ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags freetype2)
ADDITIONAL_LDFLAGS += $(shell pkg-config --libs freetype2) -lfontconfig -lX11 -lXrender -lm 
ADDITIONAL_LDFLAGS += $(shell pkg-config --libs cairo) -lgnustep-corebase
else
ADDITIONAL_CPPFLAGS += -D__MINGW__
LIBRARIES_DEPEND_UPON = -lgdi32 -lcairo -lgnustep-corebase
endif


-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
