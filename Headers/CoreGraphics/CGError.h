
/** <title>CGError</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2017 Free Software Foundation, Inc.</copy>

   Author: Daniel Ferreira
   Date: Jun 2017

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

enum {
  kCGErrorSuccess = 0,

  kCGErrorFailure = 1000,
  kCGErrorIllegalArgument = 1001,
  kCGErrorInvalidConnection = 1002,
  kCGErrorInvalidContext = 1003,
  kCGErrorCannotComplete = 1004,
  kCGErrorNotImplemented = 1006,
  kCGErrorRangeCheck = 1007,
  kCGErrorTypeCheck = 1008,
  kCGErrorInvalidOperation = 1010,
  kCGErrorNoneAvailable = 1011,
};
typedef int CGError;
