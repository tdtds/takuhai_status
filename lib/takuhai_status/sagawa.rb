require 'faraday'
require 'nokogiri'

module TakuhaiStatus
	class Sagawa
		attr_reader :key, :time, :state
		TakuhaiStatus.add_service(self)

		def initialize(key)
			@key = key.strip
			raise NotMyKey.new('invalid key format') unless @key =~ /\A[0-9]+\Z/
			@time, @state = check
		end

		def finish?
			return !!(@state =~ /営業所へお問い合わせ下さい。|配達は終了致しました。$|^配達完了|引渡完了/)
		end

	private
		def check
			conn = Faraday.new(url: 'http://k2k.sagawa-exp.co.jp')
			res = conn.post('/p/web/okurijosearch.do', {okurijoNo: @key})
			doc = Nokogiri(res.body)

			begin
				cells = doc.css('.table_okurijo_detail2').css('tr').last.css('td')
				state = "#{cells[0].text.strip} [#{cells[2].text.strip}]".sub(/^./, '')
				time = Time.parse(cells[1].text.strip)
				return time, state
			rescue NoMethodError # detail2 table not found, use detail table
				begin
					time = Time.now
					state = doc.css('.table_okurijo_detail').first.css('tr').last.css('td').text.strip
					if state =~ /恐れ入りますが、お問い合せ送り状NOをお確かめください。|お荷物データが登録されておりません。/
						raise NotMyKey.new('invalid key')
					end
					return time, state
				rescue NoMethodError
					raise NotMyKey.new('invalid response')
				end
			rescue ArgumentError
				return Time.now, ''
			end
		end
	end
end
