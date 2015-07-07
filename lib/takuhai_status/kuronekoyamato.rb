require 'faraday'
require 'nokogiri'

module TakuhaiStatus
	class KuronekoYamato
		attr_reader :key, :time, :state

		def initialize(key)
			@key = key.gsub(/[^0-9]/, '')
			@time, @state = check
		end

	private
		def check
			conn = Faraday.new(url: 'http://toi.kuronekoyamato.co.jp/')
			res = conn.post('/cgi-bin/tneko', {number00: '1', number01: @key})
			doc = Nokogiri(res.body)

			begin
				tr = doc.css('.meisai')[0].css('tr').last
				sday = tr.css('td')[2].text
				stime = tr.css('td')[3].text
				time = Time.parse("#{sday} #{stime}")
				state = tr.css('td')[1].text

				return time, state
			rescue NoMethodError
				raise NotMyKey
			rescue ArgumentError
				return Time.now, ''
			end
		end
	end
end
