#!/usr/bin/env ruby
#
# $Id: exe2vbs.rb 9212 2010-05-03 17:13:09Z jduck $
#
# This script converts an EXE to a vbs script
#
# $Revision: 9212 $
#

msfbase = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
$:.unshift(File.join(File.dirname(msfbase), '..', 'lib'))

require 'rex'
require 'msf/base'

def usage
	$stderr.puts("    Usage: #{$0} [exe] [vbs]\n")
	exit
end

exe = ARGV.shift
vbs = ARGV.shift

if (not (exe and vbs))
	usage
end

out = File.new(vbs, "w")
inp = File.open(exe, "rb")

dat = ""
while(buf = inp.read(8192))
	dat << buf
end

out.write(Msf::Util::EXE.to_exe_vbs(dat))
out.close
inp.close

$stderr.puts "[*] Converted #{dat.length} bytes of EXE into a vbs script"
