include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = qeb2 shadows shapes layers texttest textlayout pdf images gradients colorspace paths

ifeq ($(GNUSTEP_TARGET_OS), mingw32)
main_file = win32.m
else
main_file = x11.m
endif

qeb2_OBJC_FILES = $(main_file) qeb2-draw.m
shadows_OBJC_FILES = $(main_file) shadows.m
shapes_OBJC_FILES = $(main_file) arcs.m ovals.m rects.m shapes.m
paths_OBJC_FILES = $(main_file) paths.m
layers_OBJC_FILES = $(main_file) layers.m
texttest_OBJC_FILES = $(main_file) texttest.m
textlayout_OBJC_FILES = $(main_file) textlayout.m
pdf_OBJC_FILES = pdf.m arcs.m ovals.m rects.m
images_OBJC_FILES = $(main_file) images.m
images_RESOURCE_FILES = test.png test.jpg
gradients_OBJC_FILES = $(main_file) gradients.m
colorspace_OBJC_FILES = $(main_file) colorspace.m


ifneq ($(GNUSTEP_TARGET_OS), mingw32)
ADDITIONAL_LDFLAGS += -lfontconfig -lX11 -lXrender -lm 
else
ADDITIONAL_LDFLAGS += -lgdi32
endif

ADDITIONAL_OBJCFLAGS += -Wall -g -O0 -std=gnu99
ADDITIONAL_CFLAGS += -Wall -g -O0 -std=gnu99
ADDITIONAL_LDFLAGS += -L../Source/obj 
ADDITIONAL_TOOL_LIBS = -lopal
ADDITIONAL_INCLUDE_DIRS = -I../Headers

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
