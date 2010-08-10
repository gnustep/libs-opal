include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = opaltext

$(LIBRARY_NAME)_OBJC_FILES = $(wildcard *.m)


$(LIBRARY_NAME)_HEADER_FILES_DIR = ../../Headers/CoreText
$(LIBRARY_NAME)_INCLUDE_DIRS = -I../../Headers
$(LIBRARY_NAME)_HEADER_FILES_INSTALL_DIR = CoreText
$(LIBRARY_NAME)_HEADER_FILES = \
	CoreText.h\
	CTFont.h\
	CTFontCollection.h\
	CTFontDescriptor.h\
	CTFontManager.h\
	CTFontManagerErrors.h\
	CTFontTraits.h\
	CTFrame.h\
	CTFramesetter.h\
	CTGlyphInfo.h\
	CTLine.h\
	CTParagraphStyle.h\
	CTRun.h\
	CTStringAttributes.h\
	CTTextTab.h\
	CTTypesetter.h

ADDITIONAL_OBJCFLAGS += -Wall -g -O0 -std=gnu99
ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags cairo)
ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags lcms)

ifneq ($(GNUSTEP_TARGET_OS), mingw32)
ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags freetype2)
ADDITIONAL_LDFLAGS += $(shell pkg-config --libs freetype2) -lfontconfig -lX11 -lXrender -lm 
ADDITIONAL_LDFLAGS += $(shell pkg-config --libs cairo)
else
ADDITIONAL_CPPFLAGS += -D__MINGW__
LIBRARIES_DEPEND_UPON = -lgdi32 -lcairo
endif

LIBRARIES_DEPEND_UPON += $(shell pkg-config --libs lcms)
LIBRARIES_DEPEND_UPON += $(shell pkg-config --libs libpng)
LIBRARIES_DEPEND_UPON += -ljpeg -ltiff -lopal

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
