include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = qeb2 shadows shapes layers texttest pdf

qeb2_C_FILES = qeb2.c qeb2-draw.c
shadows_C_FILES = shadows.c
shapes_C_FILES = arcs.c ovals.c rects.c shapes.c
layers_C_FILES = layers.c
texttest_OBJC_FILES = texttest.m
pdf_C_FILES = arcs.c ovals.c rects.c
pdf_OBJC_FILES = pdf.m

# Use := to compute the flags we need so that the subshells are
# spawned only once
OPAL_LDFLAGS := $(shell pkg-config --cflags freetype2) \
	         $(shell pkg-config --cflags cairo)

# Then add them to ADDITIONAL_CPPFLAGS
ADDITIONAL_LDFLAGS += \
	$(OPAL_LDFLAGS) \
	-lfontconfig -lX11 -lXrender -lm -lgnustep-corebase

ADDITIONAL_LDFLAGS += -L../Source/obj -lopal
ADDITIONAL_INCLUDE_DIRS = -I../Headers

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
