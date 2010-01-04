# Simple Makefile to build libopal.a and some examples
# This should be replaced with a proper build system

CFLAGS=-Wall -g
CPPFLAGS=-I. -I/usr/local/include -I/usr/local/include/cairo

# Get the Cairo sources and compile libcairo.a, then set CAIROSRC below.
# Once we start using private Cairo APIs static lib is needed because
# private API functions are not exported in the dynamic lib.

# For release version of cairo
#CAIROSRC=$(PWD)/cairo-1.4.10/src
#CAIROLIBS=$(CAIROSRC)/.libs/libcairo.a

# For development version of Cairo
#CAIROSRC=$(PWD)/git/cairo/src
#CAIROLIBS=$(CAIROSRC)/.libs/libcairo.a \
  $(CAIROSRC)/../../pixman/installed/lib/libpixman-1.a
CAIROSRC=/usr/local/include/cairo
CAIROLIBS=/usr/local/lib/libcairo.a /usr/local/lib/libpixman-1.a

# Portable parts of libopal.a
OPAL_OBJS=CGAffineTransform.o CGColor.o CGColorSpace.o CGContext.o \
  CGDataProvider.o CGFont.o CGImage.o CGLayer.o opal.o
# System specific parts of libopal.a
OPAL-X11_OBJS=opal-x11.o

EXAMPLES=test test1 test2 test3 test4 cgtest1 texttest arclock qeb2 shapes layers

LOADLIBES=$(CAIROLIBS) $(shell pkg-config --libs freetype2) \
  -lfontconfig -lX11 -lXrender -lm

libopal.a: libopal.a($(OPAL_OBJS)) libopal.a($(OPAL-X11_OBJS))

CGContext.o: CPPFLAGS+=-I$(CAIROSRC)
CGFont.o: CPPFLAGS+=-I$(CAIROSRC) $(shell pkg-config --cflags freetype2)
CGImage.o: CPPFLAGS+=-I$(CAIROSRC)
opal-x11.o: CPPFLAGS+=-I$(CAIROSRC)

examples: $(EXAMPLES)

test: libopal.a
test1: libopal.a
test2: libopal.a
test3: libopal.a
test4: libopal.a
cgtest1: libopal.a
texttest: libopal.a
arclock: libopal.a
qeb2: qeb2-draw.o libopal.a
shapes: arcs.o ovals.o rects.o libopal.a
layers: layers.o libopal.a

clean:
	rm -f *.o *~
distclean: clean
	rm -f libopal.a $(EXAMPLES)

.PHONY: clean distclean
