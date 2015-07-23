require 'faraday'
require 'nokogiri'

module TakuhaiStatus
	class KuronekoYamato
		attr_reader :key, :time, :state

		def initialize(key)
			@key = key.gsub(/[^0-9]/, '')
			@time, @state = check
		end

		def finish?
			return !!(@state =~ /^(お客様引渡|配達|投函)完了/)
		end

	private
		def check
			conn = Faraday.new(url: 'http://toi.kuronekoyamato.co.jp/')
			res = conn.post('/cgi-bin/tneko', {number00: '1', number01: @key})
			doc = Nokogiri(res.body)

			begin
				tr = doc.css('.meisai')[0].css('tr').last
				state = tr.css('td')[1].text
				sday = tr.css('td')[2].text
				stime = tr.css('td')[3].text
				time = Time.parse("#{sday} #{stime}")

				return time, state
			rescue NoMethodError
				raise NotMyKey
			rescue ArgumentError
				return Time.now, state || ''
			end
		end
	end
end
