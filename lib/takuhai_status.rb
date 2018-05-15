require "logger"
require "timeout"

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

	# loading plugins
	@@services = []
	def self.add_service(service_name)
		@@services << service_name
	end
	Dir.glob("#{File.dirname(__FILE__)}/takuhai_status/*.rb") do |plugin|
		require plugin
	end

	def self.scan(key, timeout: 10, logger: Logger.new(nil))
		services = []
		[].tap{|threads|
			@@services.each do |service|
				threads.push(Thread.new{
					if Thread.method_defined?(:report_on_exception)
						Thread.current.report_on_exception = false
					end
					name = service.to_s.sub(/^.*::/, '')
					begin
						Timeout.timeout(timeout, Timeout::Error) do
							service.new(key)
						end
					rescue Timeout::Error, Faraday::TimeoutError
						m = "Timeout in #{name}(#{key})"
						logger.error m
						raise NotMyKey.new(m)
					end
				})
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
