require "takuhai_status/version"
require "takuhai_status/japanpost"
require "takuhai_status/kuronekoyamato"
require "takuhai_status/sagawa"
require "takuhai_status/tmg_cargo"
require "takuhai_status/ups"

module TakuhaiStatus
	class NotFound < StandardError; end
	class NotMyKey < StandardError; end
	class Multiple < StandardError
		attr_reader :services
		def initialize(msg, services)
			super(msg)
			@services = services
		end
	end

	def self.scan(key)
		services = []
		[].tap{|threads|
			[Sagawa, JapanPost, KuronekoYamato, TMGCargo, UPS].each do |service|
				threads.push(Thread.new{service.new(key)})
			end
		}.each{|thread|
			begin
				services.push(thread.value)
			rescue NotMyKey
			end
		}

		case services.size
		when 0
			raise NotFound
		when 1
			return services.first
		else
			services.delete_if{|service| service.finish?}
			case services.size
			when 0
				raise NotFound
			when 1
				return services.first
			else
				raise Multiple.new('some services found', services)
			end
		end
	end
end
