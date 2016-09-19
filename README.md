# Rack::Redic

Rack::Session::Redic provides simple cookie based session management.
Session data is stored in Redis via the Redic gem. The corresponding
session key is maintained in the cookie.

You may optionally supply the class/module you would like to use when
marshalling objects in and out of Redis. All that is required is that
this class respond to the  `load` and `dump` methods, returning the
session hash and a string respectively.

Addtionally, you may pass in the URL for your Redis server. The default
URL is fetched from the ENV as 'REDIS_URL' in keeping with Heroku and
others' practices.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack-redic', require: 'rack/session/redic'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-redic


## Usage

Anywhere in your Rack application just add:

```ruby
# Most basic usage.
use Rack::Session::Redic

# Optionally pass in a marshaller.
use Rack::Session::Redic, marshaller: Oj

# And/or pass in the URL of your Redis server.
use Rack::Session::Redic, marshaller: Oj, url: 'redis://host'
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/evanleck/rack-redic. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
