##
# $Id: patchupdllinject.rb 14034 2011-10-23 11:56:13Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'
require 'msf/core/payload/windows/dllinject'

###
#
# Injects an arbitrary DLL in the exploited process.
#
###
module Metasploit3

	# $Revision: 14034 $
	include Msf::Payload::Windows::DllInject

end