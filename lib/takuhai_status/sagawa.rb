require 'faraday'
require 'nokogiri'

module TakuhaiStatus
	class Sagawa
		attr_reader :key, :time, :state

		def initialize(key)
			@key = key.gsub(/[^0-9]/, '')
			@time, @state = check
		end

		def finish?
			return @state =~ /配達は終了致しました。$/
		end

	private
		def check
			conn = Faraday.new(url: 'http://k2k.sagawa-exp.co.jp')
			res = conn.post('/p/web/okurijosearch.do', {okurijoNo: @key})
			doc = Nokogiri(res.body)

			begin
				table = doc.css('#detail-1 table').first
				state_raw = table.css('tr td')[7]
				if state_raw.text == 'お問い合わせNo.をお確かめ下さい。'
					raise NotMyKey.new('invalid key')
				end
				if state_raw.text == 'お問い合わせのデータは登録されておりません。'
					raise NotMyKey.new('not entry yet')
				end

				state = state_raw.children.map(&:text).first.sub(/^[^0-9]+/, '')
				state = state_raw.children.map(&:text).first if state.empty?

				begin
					time = Time.parse(state.sub(/年/, '-').sub(/月/, '-').sub(/日/, ''))
				rescue ArgumentError
					time = Time.parse(table.css('tr td')[1].text) rescue Time.now
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
