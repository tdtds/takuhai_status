require 'faraday'
require 'faraday/cookie_jar'
require 'faraday_middleware'
require 'nokogiri'

module TakuhaiStatus
	class TMGCargo
		attr_reader :key, :time, :state
		TakuhaiStatus.add_service(self)
		@@conn = nil

		def initialize(key)
			@key = key.strip
			raise NotMyKey.new('invalid key format') unless @key =~ /\A[0-9]+\Z/
			@time, @state = check
		end

		def finish?
			return !!(@state =~ /配達完了|返品/)
		end

	private
		def check
			@@conn = Faraday.new(url: 'https://track-a.tmg-tms.com'){|builder|
				builder.use :cookie_jar
				builder.use FaradayMiddleware::FollowRedirects
				builder.request :url_encoded
				builder.adapter :net_http
			} unless @@conn
			top = @@conn.get('/cts/TmgCargoSearchAction.do')
			res = @@conn.post(top.env.url, { # replace with redirected url
				'inputData[0].inq_no' => @key,
				'method_id' => 'POPUPSEA'
			})
			doc = Nokogiri(res.body)
			begin
				state = doc.css('#list tr td')[2].text.strip
				raise if state =~ /お荷物情報が見つかりません/
				raise if state == '2' # skip error state occurs sometime
				return Time.now, state
			rescue
				raise NotMyKey.new(state)
			end
		end
	end
end
