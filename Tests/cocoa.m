#import <Cocoa/Cocoa.h>

void draw(CGContextRef ctx, CGRect r);

@interface MyView : NSView
@end
@implementation MyView
- (void)drawRect: (NSRect)rect
{
  CGRect r = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
  draw([[NSGraphicsContext currentContext] graphicsPort], r);
}
@end

@interface AppDelegate : NSObject
{
  NSWindow *win;
  NSView *view;
}
@end

@implementation AppDelegate

- (void) applicationDidFinishLaunching: (id)notif
{
  NSRect r = NSMakeRect(0,0,640,480);
  win = [[NSWindow alloc] initWithContentRect: r
     styleMask:NSResizableWindowMask
     backing:NSBackingStoreBuffered
     defer:NO];
  view = [[MyView alloc] initWithFrame: r];
  [win setContentView: view];
  [win makeKeyAndOrderFront: nil];
}

@end



int main(int argc, char *argv[])
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  id delegate = [[AppDelegate alloc] init];
  [[NSApplication sharedApplication] setDelegate: delegate];
  [NSApp run];
  [pool release];
  return 0;
}
