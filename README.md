# TakuhaiStatus

日本国内外の宅配便の配達ステータスを統一的に得る

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'takuhai_status'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install takuhai_status

## Usage

```ruby
require 'takuhai_status'

code = '123456789012' # code of a devivery service
s = TakuhaiStatus.scan(code) #=> an instance of services
s.stat    #=> status string of this service as String
s.time    #=> Time instance of status changed
s.finish? #=> dose the cargo derivering finished?

# or make new instance of a service directly
s = TakuhaiStatus::KuronekoYamato.new(code)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tdtds/takuhai_status.


## License

The gem is available as open source under the terms of the GPL3.

