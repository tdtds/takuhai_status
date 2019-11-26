require 'mechanize'

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
			return !!(@state =~ /営業所へお問い合わせください。|配達は終了致しました。$|^配達完了|引渡完了/)
		end

	private
		def check
			agent = Mechanize.new
			page = agent.get('https://k2k.sagawa-exp.co.jp/p/sagawa/web/okurijoinput.jsp')
			form = page.form_with('main')
			form['main:no1'] = @key
			button = form.button_with('main:toiStart')
			result = agent.submit(form, button)

			begin
				row = result.css('#detail1 tr')
				cells = row[row.size - 1].css('td')
				if cells.size == 3 #has detail
					state = "#{cells[0].text.strip[1,100]} [#{cells[2].text.strip}]"
					time = Time.parse(cells[1].text.strip) rescue Time.now
				else # finished?
					state = cells[0].text.strip
					time = Time.now
				end
				if state =~ /恐れ入りますが、お問い合せ送り状NOをお確かめください。|お荷物データが登録されておりません。/
					raise NotMyKey.new('invalid key')
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
