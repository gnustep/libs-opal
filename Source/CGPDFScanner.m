/** <title>CGPDFScanner</title>
 
 <abstract>C Interface to graphics drawing library</abstract>
 
 Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

 Author: Eric Wasylishen
 Date: June 2010
  
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

#include "CoreGraphics/CGPDFScanner.h"

CGPDFScannerRef CGPDFScannerCreate(
  CGPDFContentStreamRef cs,
  CGPDFOperatorTableRef table,
  void *info)
{
  
}

bool CGPDFScannerScan(CGPDFScannerRef scanner)
{
  
}

CGPDFContentStreamRef CGPDFScannerGetContentStream(CGPDFScannerRef scanner)
{
  
}

bool CGPDFScannerPopArray(CGPDFScannerRef scanner, CGPDFArrayRef *value)
{
  
}

bool CGPDFScannerPopBoolean(CGPDFScannerRef scanner, CGPDFBoolean *value)
{
  
}

bool CGPDFScannerPopDictionary(CGPDFScannerRef scanner, CGPDFDictionaryRef *value)
{
  
}

bool CGPDFScannerPopInteger(CGPDFScannerRef scanner, CGPDFInteger *value)
{
  
}

bool CGPDFScannerPopName(CGPDFScannerRef scanner, const char **value)
{
  
}

bool CGPDFScannerPopNumber(CGPDFScannerRef scanner, CGPDFReal *value)
{
  
}

bool CGPDFScannerPopObject(CGPDFScannerRef scanner, CGPDFObjectRef *value)
{
  
}

bool CGPDFScannerPopStream(CGPDFScannerRef scanner, CGPDFStreamRef *value)
{
  
}

bool CGPDFScannerPopString(CGPDFScannerRef scanner, CGPDFStringRef *value)
{
  
}

CGPDFScannerRef CGPDFScannerRetain(CGPDFScannerRef scanner)
{
  
}

void CGPDFScannerRelease(CGPDFScannerRef scanner)
{
  
}