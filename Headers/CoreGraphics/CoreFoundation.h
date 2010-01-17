/** <title>CoreFoundation</title>
 
 <abstract>C Interface to graphics drawing library</abstract>
 
 Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

 Author: Eric Wasylishen
 Date: Jan 2010
 
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
 
#ifndef OPAL_CoreFoundation_h
#define OPAL_CoreFoundation_h

typedef unsigned long CFTypeID;

#	ifdef __OBJC__
@class NSDictionary, NSString, NSArray;
typedef NSDictionary* CFDictionaryRef;
typedef NSString* CFStringRef;
typedef NSData* CFDataRef;
typedef NSArray* CFArrayRef;
#	else
typedef struct cf_dictionary  *CFDictionaryRef;
typedef struct cf_string  *CFStringRef;
typedef struct cf_data *CFDataRef;
typedef struct cf_array *CFArrayRef;
#	endif

#endif

