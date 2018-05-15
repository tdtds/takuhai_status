require 'faraday'
require 'faraday/cookie_jar'
require 'nokogiri'

module TakuhaiStatus
	class TMGCargo
		attr_reader :key, :time, :state
		TakuhaiStatus.add_service(self)
		@@conn = nil

		def initialize(key)
			@key = key.gsub(/[^0-9]/, '')
			@time, @state = check
		end

		def finish?
			return !!(@state =~ /配達完了|返品/)
		end

	private
		def check
			@@conn = Faraday.new(url: 'http://track-a.tmg-group.jp'){|builder|
				builder.use :cookie_jar
				builder.request :url_encoded
				builder.adapter :net_http
			} unless @@conn
			@@conn.get('/cts/TmgCargoSearchAction.do')
			res = @@conn.post('/cts/TmgCargoSearchAction.do', {
				'inputData[0].inq_no' => @key,
				'method_id' => 'POPUPSEA'
			})
			doc = Nokogiri(res.body)
			begin
				state = doc.css('#list tr td')[2].text.strip
				raise if state =~ /お荷物情報が見つかりません/
				return Time.now, state
			rescue
				raise NotMyKey
			end
		end
	end
end
