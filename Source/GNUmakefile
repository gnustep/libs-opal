

ifeq ($(GNUSTEP_MAKEFILES),)
  GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(error You need to set GNUSTEP_MAKEFILES before compiling!)
  endif
endif

include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = opal
LIBRARY_NAME = libopal

ifdef NO_OPALTEXT
libopal_SUBPROJECTS = \
	OpalGraphics
else
libopal_SUBPROJECTS = \
	OpalGraphics\
	OpalText
endif

ifneq ($(GNUSTEP_TARGET_OS), mingw32)
LIBRARIES_DEPEND_UPON += $(shell pkg-config --libs freetype2) -lfontconfig -lX11 -lXrender -lm 
LIBRARIES_DEPEND_UPON += $(shell pkg-config --libs cairo)
else
LIBRARIES_DEPEND_UPON += -lgdi32 -lcairo
endif

LIBRARIES_DEPEND_UPON += $(shell pkg-config --libs lcms)
LIBRARIES_DEPEND_UPON += $(shell pkg-config --libs libpng)
LIBRARIES_DEPEND_UPON += -ljpeg -ltiff

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
