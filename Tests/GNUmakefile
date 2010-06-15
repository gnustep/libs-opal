include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = qeb2 shadows shapes layers texttest pdf
APP_NAME = images

ifeq ($(GNUSTEP_TARGET_OS), mingw32)
main_file = win32.m
else
main_file = x11.m
endif

qeb2_C_FILES = qeb2-draw.c 
qeb2_OBJC_FILES = $(main_file)
shadows_C_FILES = shadows.c
shadows_OBJC_FILES = $(main_file)
shapes_C_FILES = arcs.c ovals.c rects.c shapes.c
shapes_OBJC_FILES = $(main_file)
layers_C_FILES = layers.c
layers_OBJC_FILES = $(main_file)
texttest_OBJC_FILES = texttest.m $(main_file)
pdf_C_FILES = arcs.c ovals.c rects.c
pdf_OBJC_FILES = pdf.m
images_OBJC_FILES = images.m $(main_file)
images_RESOURCE_FILES = test.png test.jpg

ifneq ($(GNUSTEP_TARGET_OS), mingw32)
ADDITIONAL_LDFLAGS += -lfontconfig -lX11 -lXrender -lm 
endif

ADDITIONAL_OBJCFLAGS += -Wall -g -std=gnu99
ADDITIONAL_CFLAGS += -Wall -g -std=gnu99
ADDITIONAL_LDFLAGS += -L../Source/obj 
ADDITIONAL_TOOL_LIBS = -lopal -lgnustep-corebase
ADDITIONAL_INCLUDE_DIRS = -I../Headers

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
