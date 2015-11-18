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
			return !!(@state =~ /営業所へお問い合わせ下さい。|配達は終了致しました。$/)
		end

	private
		def check
			conn = Faraday.new(url: 'http://k2k.sagawa-exp.co.jp')
			res = conn.post('/p/web/okurijosearch.do', {okurijoNo: @key})
			doc = Nokogiri(res.body)

			begin
				table = doc.css('#detail-1 table').first
				state_line = table.css('tr td')[7].children.map(&:text).first
				if state_line == 'お問い合わせNo.をお確かめ下さい。'
					raise NotMyKey.new('invalid key')
				end
				if state_line == 'お問い合わせのデータは登録されておりません。'
					raise NotMyKey.new('not entry yet')
				end

				state = state_line.split(/[ \u{a0}]+/).last

				begin
					s = state_line.sub(/^[^0-9]+/, '')
					s = state_line if s.empty?
					time = Time.parse(s.gsub(/[^0-9 :]/, '-'))
				rescue ArgumentError
					ship = table.css('tr td')[1].text.strip.gsub(/[^0-9]/, '-')
					time = Time.parse(ship) rescue Time.now
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
