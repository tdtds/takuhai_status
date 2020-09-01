require 'open-uri'
require 'nokogiri'

module TakuhaiStatus
	class JapanPost
		attr_reader :key, :time, :state
		TakuhaiStatus.add_service(self)

		def initialize(key)
			@key = key.strip
			raise NotMyKey.new('invalid key format') unless @key =~ /\A[a-zA-Z0-9]+\Z/
			@time, @state = check
		end

		def finish?
			return !!(@state =~ /差出人に返送済み|お届け済み|コンビニエンスストアに引渡|窓口でお渡し|転送|配達局から出発/)
		end

	private
		def check
			uri = "https://trackings.post.japanpost.jp/services/srv/search/direct?reqCodeNo1=#{@key}"
			doc = Nokogiri(URI.open(uri, &:read))

			begin
				begin
					# japanese baggage
					cols = doc.css('.tableType01')[1].css('tr')
					col = cols[cols.size - 2]
					stime = col.css('td')[0].text
					time = Time.parse(stime)
					station = " [#{col.css('td')[3].text}]"
					station = " [#{col.css('td')[4].text.strip}]" if station.size <= 4
					station = "" if station.size <= 4
					state = "#{col.css('td')[1].text}#{station}"
				rescue NoMethodError
					# international baggage
					cols = doc.css('.tableType01 tr')
					col = cols[cols.size - 2]
					stime = col.css('td')[2].text
					time = Time.parse(stime)
					station = " [#{col.css('td')[4].text}/#{col.css('td')[5].text}]"
					state = "#{col.css('td')[3].text}#{station}"
				end

				return time, state
			rescue NoMethodError
				raise NotMyKey
			rescue ArgumentError
				return Time.now, ''
			end
		end
	end
end
