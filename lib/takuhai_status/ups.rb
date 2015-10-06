require 'open-uri'
require 'nokogiri'

module TakuhaiStatus
	class UPS
		attr_reader :key, :time, :state

		def initialize(key)
			@key = key.gsub(/[^a-zA-Z0-9]/, '')
			@time, @state = check
		end

		def finish?
			return !!(@state =~ /配達済み/)
		end

	private
		def check
			uri = "http://www.ups.com/WebTracking/processInputRequest?loc=ja_JP&Requester=NES&tracknum=#{@key}"
			html = open(uri, &:read)
			# HTML中に謎の大量ヌル文字が含まれていてnokogiriのパースが止まる対策
			html.gsub!(/\u0000/,'')
			doc = Nokogiri::HTML.parse(html, uri, "utf-8")

			begin
				state = doc.css('.newstatus #ttc_tt_spStatus h3')[0].text.strip
				time = "#{doc.css('.secHead ul li')[0].text.match(/\d{4}\/\d\d\/\d\d \d{1,2}:\d\d/)[0]}+0500)"
				return Time.parse(time).localtime, state
			rescue NoMethodError
				raise NotMyKey
			rescue ArgumentError
				return Time.now, ''
			end
		end
	end
end
