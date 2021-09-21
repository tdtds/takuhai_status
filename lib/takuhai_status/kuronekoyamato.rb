require 'faraday'
require 'nokogiri'

module TakuhaiStatus
	class KuronekoYamato
		attr_reader :key, :time, :state
		TakuhaiStatus.add_service(self)

		def initialize(key)
			@key = key.strip
			raise NotMyKey.new('invalid key format') unless @key =~ /\A[0-9]+\Z/
			@time, @state = check
		end

		def finish?
			return !!(@state =~ /^(お客様引渡|配達|投函)完了|返品/)
		end

	private
		def check
			conn = Faraday.new(url: 'http://toi.kuronekoyamato.co.jp/')
			res = conn.post('/cgi-bin/tneko', {number00: '1', number01: @key})
			doc = Nokogiri(res.body.force_encoding('UTF-8'))

			begin
				current = doc.css('.tracking-invoice-block-detail ol li').last
				state = "#{current.css('.item').text} [#{current.css('.name').text}]"
				month, day, hour, minute = current.css('.date').text.split(/[^\d]+/)
				time = Time.local(Time.now.year, month, day, hour, minute)

				#if state == '国内到着'
				#	begin
				#		time, state = global_state(doc)
				#	rescue
				#		$stderr.puts "error in yamato global, about #{key}"
				#	end
				#end

				return time, state
			rescue NoMethodError
				raise NotMyKey
			rescue ArgumentError
				return Time.now, state || ''
			end
		end

		def global_state(doc)
			form = doc.css('form[method=POST]')
			values = form.css('input[type=hidden]').map{|x| [x[:name], x[:value]]}.flatten
			params = Hash[*values]

			res = Faraday.new.post(
				'http://globaltoi.kuronekoyamato.co.jp/Global/outside',
				params
			)
			html = res.body.force_encoding('Shift_JIS').encode('UTF-8')
			tr = Nokogiri(html).css('table.detail tr')
			state = tr[tr.size-1].css('td')[1].text
			loc = tr[tr.size-1].css('td')[4].text.strip.chop.chop
			stime = "#{tr[tr.size-1].css('td')[2].text} #{tr[tr.size-1].css('td')[3].text}"
			return Time.parse(stime), "#{state}[#{loc}]"
		end
	end
end
