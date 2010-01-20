include $(GNUSTEP_MAKEFILES)/common.make

CTOOL_NAME = qeb2 shadows shapes layers texttest

qeb2_C_FILES = qeb2.c qeb2-draw.c
shadows_C_FILES = shadows.c
shapes_C_FILES = arcs.c ovals.c rects.c shapes.c
layers_C_FILES = layers.c
texttest_C_FILES = texttest.c

ADDITIONAL_LDFLAGS += \
	$(shell pkg-config --libs freetype2) \
	$(shell pkg-config --libs cairo) \
	-lfontconfig -lX11 -lXrender -lm -framework CoreFoundation

ADDITIONAL_LDFLAGS += -L../Source/obj -lopal
ADDITIONAL_INCLUDE_DIRS = -I../Headers

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/ctool.make
-include GNUmakefile.postamble
