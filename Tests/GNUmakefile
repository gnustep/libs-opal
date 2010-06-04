include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = qeb2 shadows shapes layers texttest pdf

ifeq ($(GNUSTEP_TARGET_OS), mingw32)
main_file = win32.c
else
main_file = x11.c
endif

qeb2_C_FILES = qeb2-draw.c $(main_file)
shadows_C_FILES = shadows.c $(main_file)
shapes_C_FILES = arcs.c ovals.c rects.c shapes.c $(main_file)
layers_C_FILES = layers.c $(main_file)
texttest_OBJC_FILES = texttest.m $(main_file)
pdf_C_FILES = arcs.c ovals.c rects.c
pdf_OBJC_FILES = pdf.m


# Then add them to ADDITIONAL_CPPFLAGS
ADDITIONAL_LDFLAGS += -lgnustep-corebase

ifneq ($(GNUSTEP_TARGET_OS), mingw32)
ADDITIONAL_LDFLAGS += -lfontconfig -lX11 -lXrender -lm 
endif

ADDITIONAL_LDFLAGS += -L../Source/obj $(shell pkg-config --libs cairo)
ADDITIONAL_INCLUDE_DIRS = -I../Headers $(shell pkg-config --cflags cairo)

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
