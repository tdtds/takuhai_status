require 'faraday'
require 'json'

module TakuhaiStatus
	class FedEx
		attr_reader :key, :time, :state

		def initialize(key)
			@key = key.gsub(/[^0-9]/, '')
			@time, @state = check
		end

		def finish?
			return !!(@state =~ /認可済み業者に委託/)
		end

	private
		def check
			data = {
				"TrackPackagesRequest": {
					"appType": "WTRK",
					"uniqueKey": "",
					"processingParameters": {},
					"trackingInfoList": [
						{
							"trackNumberInfo": {
								"trackingNumber": @key,
								"trackingQualifier": "",
								"trackingCarrier": ""
							}
						}
					]
				}
			}
			conn = Faraday.new(url: 'https://www.fedex.com'){|builder|
				builder.request :url_encoded
				builder.adapter :net_http
			}
			res = conn.post('/trackingCal/track', {
				data: data.to_json,
				action: 'trackpackages',
				locale: 'ja_JP',
				version: '1',
				format: 'json'
			})
			begin
				data = JSON.parse(res.body)
				raise unless data["TrackPackagesResponse"]["successful"]

				package = data["TrackPackagesResponse"]["packageList"].first
				current = package["scanEventList"].first

				begin
					time = Time.parse("#{current['date']} #{current['time']}#{current['+09:00']}")
				rescue ArgumentError
					raise NotMyKey.new('no time status in the package');
				end

				state = "#{current['status']}"
				state = "#{state}(#{current['scanDetails']})" if current['scanDetails'].size > 0
				state = "#{state} - #{current['scanLocation']}" if current['scanLocation'].size > 0

				return time, state
			rescue NotMyKey
				raise
			rescue
				return (@time || Time.now), (@state || '')
			end
		end
	end
end
