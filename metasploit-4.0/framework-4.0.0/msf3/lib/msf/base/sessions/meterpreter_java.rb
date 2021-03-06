##
# $Id: meterpreter_java.rb 12196 2011-04-01 00:51:33Z egypt $
##

require 'msf/base/sessions/meterpreter'

module Msf
module Sessions

###
#
# This class creates a platform-specific meterpreter session type
#
###
class Meterpreter_Java_Java < Msf::Sessions::Meterpreter
	def supports_ssl?
		false
	end
	def supports_zlib?
		false
	end
	def initialize(rstream, opts={})
		super
		self.platform      = 'java/java'
		self.binary_suffix = 'jar'
	end
end

end
end

