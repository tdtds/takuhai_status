require 'faraday'
require 'json'

module TakuhaiStatus
	class FedEx
		attr_reader :key, :time, :state

		def initialize(key)
			@key = key
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

			package = JSON.parse(res.body)["TrackPackagesResponse"]
			unless package["successful"]
				raise NotMyKey.new(package["errorList"].first["message"])
			end

			current = package["packageList"].first["scanEventList"].first

			t_str = "#{current['date']} #{current['time']}"
			raise NotMyKey.new('no time status in the package') if t_str.size == 1
			time = Time.parse("#{t_str}+09:00")

			state = "#{current['status']}"
			state = "#{state}(#{current['scanDetails']})" if current['scanDetails'].size > 0
			state = "#{state} - #{current['scanLocation']}" if current['scanLocation'].size > 0

			return time, state
		end
	end
end
