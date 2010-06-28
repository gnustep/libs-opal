#import <Foundation/NSAutoreleasePool.h>
#include <CoreGraphics/CGContext.h>
#include <stdlib.h>
#include <stdio.h>

#include <windows.h>


extern CGContextRef opal_Win32ContextCreate(HDC dc);
void draw(CGContextRef ctx, CGRect r);

LRESULT CALLBACK WindowProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) 
{ 
  switch (msg) 
    {       
    case WM_PAINT:
      {
        PAINTSTRUCT ps;
	      RECT r;
      	GetClientRect(hwnd, &r);
	      HDC hdc = BeginPaint(hwnd, &ps);
	
      	CGContextRef ctx = opal_Win32ContextCreate(hdc);
	      draw(ctx, CGRectMake(0, 0, r.right - r.left, r.bottom - r.top));
	      CGContextRelease(ctx);
	
	      EndPaint(hwnd, &ps);
	      break;
      }
      
    case WM_DESTROY: 
      PostQuitMessage(0); 
      break; 
      
    default: 
      return DefWindowProc(hwnd, msg, wparam, lparam); 
  } 
  return 0; 
} 

APIENTRY int WinMain(HINSTANCE hInst, HINSTANCE x, LPSTR y, int nCmdShow) 
{ 
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  WNDCLASS wc; 
  HWND hwnd; 
  MSG msg; 
  const char *title = "Opal";

  wc.style = CS_HREDRAW | CS_VREDRAW; 
  wc.lpfnWndProc = WindowProc; 
  wc.cbClsExtra = 0; 
  wc.cbWndExtra = 0; 
  wc.hInstance = hInst; 
  wc.hIcon = LoadIcon(NULL, IDI_WINLOGO); 
  wc.hCursor = LoadCursor(NULL, IDC_ARROW); 
  wc.hbrBackground = (HBRUSH)COLOR_WINDOWFRAME; 
  wc.lpszMenuName = NULL; 
  wc.lpszClassName = title; 

  if (!RegisterClass(&wc)) 
    return 0; 

  hwnd = CreateWindow(title, title, WS_OVERLAPPEDWINDOW, 
		      CW_USEDEFAULT, CW_USEDEFAULT, 640, 480, 
		      NULL, NULL, hInst, NULL); 
  if (!hwnd)
    return 0; 

  ShowWindow(hwnd,nCmdShow); 
  UpdateWindow(hwnd); 

  while (GetMessage(&msg, NULL, 0, 0) > 0) 
    { 
      NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
      TranslateMessage(&msg); 
      DispatchMessage(&msg); 
      [pool2 release];
    }
  [pool release];
  return 0;
} 
