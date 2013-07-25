/** <title>OPLogging</title>

   <abstract>C Interface to graphics drawing library</abstract>

   This is a helper header to permit a bit easier logging of as many
   Opal calls as possible, to generate easily reproducible test cases
   from dynamic drawing code.

   Copyright <copy>(C) 2013 Free Software Foundation, Inc.</copy>

   Author: Ivan Vucica <ivan@vucica.net>
   Date: 2013

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#ifndef OPAL_OPLogging_h
#define OPAL_OPLogging_h

#define OPAL_LOG_CALLS 1
#if OPAL_LOG_CALLS

extern int _opal_loggingEnabled;
#define OPLOGCALL(fmt, ...) \
  int oldOpalLoggingEnabled = -1; \
  if(_opal_loggingEnabled) \
    { \
      NSDebugLLog(@"OpalCall", @" opal call: */ %s(" fmt "); /* \n", __FUNCTION__, ##__VA_ARGS__); \
      oldOpalLoggingEnabled = _opal_loggingEnabled; \
     _opal_loggingEnabled = 0; \
    }

#define OPRESTORELOGGING() \
  if (oldOpalLoggingEnabled != -1) \
   _opal_loggingEnabled = oldOpalLoggingEnabled;

#else
#define OPLOGCALL(fmt, ...);
#define OPRESTORELOGGING()
#endif

#endif

