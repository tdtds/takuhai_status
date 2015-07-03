require 'faraday'
require 'nokogiri'

module TakuhaiStatus
	class Sagawa
		attr_reader :time, :state

		def initialize(key)
			@key = key.gsub(/[^0-9]/, '')
			@time, @state = check
		end

	private
		def check
			conn = Faraday.new(url: 'http://k2k.sagawa-exp.co.jp')
			res = conn.post('/p/web/okurijosearch.do', {okurijoNo: @key})
			doc = Nokogiri(res.body)

			begin
				table = doc.css('#detail-1 table').first
				if table.css('tr td')[7].text == 'お問い合わせNo.をお確かめ下さい。'
					raise NotMyKey.new('invalid key')
				end
				if table.css('tr td')[7].text == 'お問い合わせのデータは登録されておりません。'
					raise NotMyKey.new('not entry yet')
				end

				time = Time.now
				state = table.css('tr td')[7].text
				[4, 2, 1].each do |offset|
					begin
						time = Time.parse(table.css('tr td')[offset].text)
						break
					rescue ArgumentError # invalid time format
					end
				end
				return time, state
			rescue NoMethodError
				raise NotMyKey.new('invalid response')
			rescue ArgumentError
				return Time.now, ''
			end
		end
	end
end
