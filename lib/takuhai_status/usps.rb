require 'faraday'
require 'nokogiri'

module TakuhaiStatus
	class USPS
		attr_reader :key, :time, :state
		TakuhaiStatus.add_service(self)

		def initialize(key)
			@key = key.strip
			raise NotMyKey.new('invalid key format') unless @key =~ /\A[a-zA-Z0-9]+\Z/
			@time, @state = check
		end

		def finish?
			return !!(@state =~ /^Delivered/)
		end

	private
		def check
			url = "https://tools.usps.com/go/TrackConfirmAction?tLabels=#{@key}"
			html = Faraday.new(url: url).get.body
			date, status, detail = Nokogiri(html).css('div.status_feed p');
			date_str = date.text.strip
			status_str = status.text.gsub(/\u00A0/, ' ').strip
			detail_str = detail.text.gsub(/\u00A0/, ' ').strip

			unless date_str.empty?
				return Time.parse(date_str), "#{status_str} (#{detail_str})"
			else
				raise NotMyKey
			end
		end
	end
end
