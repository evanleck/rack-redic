# Rack::Session::Redic

`Rack::Session::Redic` provides simple cookie based session management. Session
data is stored in [Redis](redis) via the [Redic](redic) gem. The corresponding
session key is maintained in the cookie.

Options include:

- `:marshaller` - You may optionally supply the class/module you would like to
  use when marshalling objects in and out of Redis. All that is required is that
  this class respond to the `load` and `dump` methods, returning the session hash
  and a string respectively.
- `:url` - Additionally, you may pass in the URL for your Redis server. The
  default URL is fetched from the `ENV` as `REDIS_URL` in keeping with Heroku and
  others' practices.
- `:expire_after` - Finally, expiration will be passed to the Redis server via
  the 'EX' option on 'SET'. Expiration should be in seconds, just like Rack's
  default handling of the `:expire_after` option. This option will refresh the
  expiration set in Redis with each request.

Any other options will get passed to `Rack::Session::Abstract::Persisted`.

## Installation

Add this line to your application's Gemfile or gems.rb file:

```ruby
gem 'rack-redic', require: 'rack/session/redic'
```

And then execute:

```sh
bundle
```

Or install it yourself as:

```sh
gem install rack-redic
```

## Usage

Anywhere in your Rack application just add:

```ruby
# Most basic usage.
use Rack::Session::Redic

# Optionally pass in a marshaller.
use Rack::Session::Redic, marshaller: Oj

# And/or pass in the URL of your Redis server.
use Rack::Session::Redic, marshaller: Oj, url: 'redis://host:port'

# And/or pass in the expiration. (1_800 is 30 minutes in seconds)
use Rack::Session::Redic, marshaller: Oj, url: 'redis://host:port', expire_after: 1_800
```

## Custom Marshallers

Since the class/module passed as `:marshaller` only needs to respond to the
methods `load` and `dump`, you can create any kind of marshaller you would like.
I've included examples for MessagePack and Oj here as reference.

### [MessagePack](msgpack)

```ruby
require 'msgpack'

MessagePack::DefaultFactory.register_type(0x00, Symbol)

module MessagePackMarshaller
  def self.dump(object)
    MessagePack.pack(object)
  end

  def self.load(string)
    MessagePack.unpack(string)
  end
end
```

Then, while adding it your Rack application.

```ruby
use Rack::Session::Redic, marshaller: MessagePackMarshaller
```

**NOTE:** MessagePack [serializes symbols as strings by default](symbols) so I
suggest customizing that behavior per their instructions. You can [read more
about MessagePack's extension formats here](extensions).

### [Oj](oj)

Oj responds to `load` and `dump` by default so there's no adapter module needed.

```ruby
use Rack::Session::Redic, marshaller: Oj
```

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).

[extensions]: https://github.com/msgpack/msgpack/blob/master/spec.md#types-extension-type
[msgpack]: https://github.com/msgpack/msgpack-ruby
[oj]: https://github.com/ohler55/oj
[redic]: https://github.com/amakawa/redic
[redis]: http://redis.io
[symbols]: https://github.com/msgpack/msgpack-ruby#serializing-and-deserializing-symbols
