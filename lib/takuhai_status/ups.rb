require 'open-uri'
require 'faraday'
require 'nokogiri'

module TakuhaiStatus
	class UPS
		attr_reader :key, :time, :state
		@@conn = nil

		def initialize(key)
			@key = key.gsub(/[^a-zA-Z0-9]/, '')
			@time, @state = check
		end

		def finish?
			return !!(@state =~ /配達済み/)
		end

	private
		def check
			@@conn = Faraday.new(url: 'https://wwwapps.ups.com/'){|builder|
				builder.use :cookie_jar
				builder.request :url_encoded
				builder.adapter :net_http
			} unless @@conn
			@@conn.get('/WebTracking/track?loc=ja_JP') # once access to set cookie
			res = @@conn.post('/WebTracking/track?loc=ja_JP', {
				HTMLVersion: '5.0',
				loc: 'ja',
				trackNums: @key,
				'track.x' => 'Track'
			})
			doc = Nokogiri::HTML.parse(res.body)

			begin
				state = doc.css('.newstatus h3')[0].text.strip
				begin
					time = "#{doc.css('#fontControlButtons li li').text.match(/\d{4}\/\d\d\/\d\d \d{1,2}:\d\d/)[0]}+0500)"
				rescue NoMethodError
					time = "#{doc.css('#fontControlButtons li').text.match(/\d{4}\/\d\d\/\d\d/)[0]} 00:00:00+0500)"
				end
				return Time.parse(time).localtime, state
			rescue NoMethodError
				raise NotMyKey
			rescue ArgumentError
				return Time.now, ''
			end
		end
	end
end
