# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# Ensure we have this set before trying to initialize anything.
ENV['REDIS_URL'] ||= 'redis://localhost:6379'

require 'minitest/autorun'
require 'rack/lint'
require 'rack/mock'
require 'rack/session/redic'

ROOT_PATH = '/'

# These tests are unceremoniously copied and modified from
# https://github.com/rack/rack/blob/master/test/spec_session_memcache.rb.
describe Rack::Session::Redic do
  session_key = Rack::Session::Abstract::Persisted::DEFAULT_OPTIONS[:key]
  session_match = /#{ session_key }=([0-9a-fA-F]+);/

  incrementor = lambda do |env|
    env['rack.session']['counter'] ||= 0
    env['rack.session']['counter'] += 1

    Rack::Response.new(env['rack.session'].inspect).to_a
  end

  drop_session = Rack::Lint.new(proc do |env|
    env['rack.session.options'][:drop] = true
    incrementor.call(env)
  end)

  renew_session = Rack::Lint.new(proc do |env|
    env['rack.session.options'][:renew] = true
    incrementor.call(env)
  end)

  defer_session = Rack::Lint.new(proc do |env|
    env['rack.session.options'][:defer] = true
    incrementor.call(env)
  end)

  skip_session = Rack::Lint.new(proc do |env|
    env['rack.session.options'][:skip] = true
    incrementor.call(env)
  end)

  incrementor = Rack::Lint.new(incrementor)

  it 'creates a new cookie' do
    redic = Rack::Session::Redic.new(incrementor)
    response = Rack::MockRequest.new(redic).get(ROOT_PATH)

    assert_includes response[Rack::SET_COOKIE], "#{ session_key }="
    assert_equal('{"counter"=>1}', response.body)
  end

  it 'determines session from a cookie' do
    redic = Rack::Session::Redic.new(incrementor)
    request = Rack::MockRequest.new(redic)
    response = request.get(ROOT_PATH)

    cookie = response[Rack::SET_COOKIE]

    assert_equal('{"counter"=>2}', request.get(ROOT_PATH, Rack::HTTP_COOKIE => cookie).body)
    assert_equal('{"counter"=>3}', request.get(ROOT_PATH, Rack::HTTP_COOKIE => cookie).body)
  end

  it 'determines session only from a cookie by default' do
    redic = Rack::Session::Redic.new(incrementor)
    request = Rack::MockRequest.new(redic)
    response = request.get(ROOT_PATH)
    sid = response[Rack::SET_COOKIE][session_match, 1]

    assert_equal('{"counter"=>1}', request.get("/?rack.session=#{ sid }").body)
    assert_equal('{"counter"=>1}', request.get("/?rack.session=#{ sid }").body)
  end

  it 'determines session from params' do
    redic = Rack::Session::Redic.new(incrementor, cookie_only: false)
    request = Rack::MockRequest.new(redic)
    response = request.get(ROOT_PATH)
    sid = response[Rack::SET_COOKIE][session_match, 1]

    assert_equal('{"counter"=>2}', request.get("/?rack.session=#{ sid }").body)
    assert_equal('{"counter"=>3}', request.get("/?rack.session=#{ sid }").body)
  end

  it 'survives nonexistant cookies' do
    bad_cookie = "rack.session=#{ SecureRandom.hex(16) }"

    redic = Rack::Session::Redic.new(incrementor)
    response = Rack::MockRequest.new(redic).get(ROOT_PATH, Rack::HTTP_COOKIE => bad_cookie)

    assert_equal('{"counter"=>1}', response.body)

    cookie = response[Rack::SET_COOKIE][session_match]

    refute_match(/#{ bad_cookie }/, cookie)
  end

  it 'maintains freshness' do
    redic = Rack::Session::Redic.new(incrementor, expire_after: 3)
    response = Rack::MockRequest.new(redic).get(ROOT_PATH)

    assert_includes response.body, '"counter"=>1'

    cookie = response[Rack::SET_COOKIE]
    response = Rack::MockRequest.new(redic).get(ROOT_PATH, Rack::HTTP_COOKIE => cookie)

    assert_equal response[Rack::SET_COOKIE], cookie
    assert_includes response.body, '"counter"=>2'

    puts 'Sleeping to expire session' if $DEBUG
    sleep 4

    response = Rack::MockRequest.new(redic).get(ROOT_PATH, Rack::HTTP_COOKIE => cookie)

    refute_equal response[Rack::SET_COOKIE], cookie
    assert_includes response.body, '"counter"=>1'
  end

  it 'does not send the same session id if it did not change' do
    redic = Rack::Session::Redic.new(incrementor)
    request = Rack::MockRequest.new(redic)

    res0 = request.get(ROOT_PATH)
    cookie = res0[Rack::SET_COOKIE][session_match]

    assert_equal('{"counter"=>1}', res0.body)

    res1 = request.get(ROOT_PATH, Rack::HTTP_COOKIE => cookie)

    assert_nil res1[Rack::SET_COOKIE]
    assert_equal('{"counter"=>2}', res1.body)

    res2 = request.get(ROOT_PATH, Rack::HTTP_COOKIE => cookie)

    assert_nil res2[Rack::SET_COOKIE]
    assert_equal('{"counter"=>3}', res2.body)
  end

  it 'deletes cookies with :drop option' do
    redic = Rack::Session::Redic.new(incrementor)
    request = Rack::MockRequest.new(redic)
    drop = Rack::Utils::Context.new(redic, drop_session)
    dreq = Rack::MockRequest.new(drop)

    res1 = request.get(ROOT_PATH)
    session = (cookie = res1[Rack::SET_COOKIE])[session_match]

    assert_equal('{"counter"=>1}', res1.body)

    res2 = dreq.get(ROOT_PATH, Rack::HTTP_COOKIE => cookie)

    assert_nil res2[Rack::SET_COOKIE]
    assert_equal('{"counter"=>2}', res2.body)

    res3 = request.get(ROOT_PATH, Rack::HTTP_COOKIE => cookie)

    refute_equal res3[Rack::SET_COOKIE][session_match], session
    assert_equal('{"counter"=>1}', res3.body)
  end

  it 'provides new session id with :renew option' do
    redic = Rack::Session::Redic.new(incrementor)
    request = Rack::MockRequest.new(redic)
    renew = Rack::Utils::Context.new(redic, renew_session)
    renew_request = Rack::MockRequest.new(renew)

    res1 = request.get(ROOT_PATH)
    session = (cookie = res1[Rack::SET_COOKIE])[session_match]

    assert_equal('{"counter"=>1}', res1.body)

    res2 = renew_request.get(ROOT_PATH, Rack::HTTP_COOKIE => cookie)
    new_cookie = res2[Rack::SET_COOKIE]
    new_session = new_cookie[session_match]

    refute_equal new_session, session
    assert_equal('{"counter"=>2}', res2.body)

    res3 = request.get(ROOT_PATH, Rack::HTTP_COOKIE => new_cookie)

    assert_equal('{"counter"=>3}', res3.body)

    # Old cookie was deleted
    res4 = request.get(ROOT_PATH, Rack::HTTP_COOKIE => cookie)

    assert_equal('{"counter"=>1}', res4.body)
  end

  it 'omits cookie with :defer option but still updates the state' do
    redic = Rack::Session::Redic.new(incrementor)
    count = Rack::Utils::Context.new(redic, incrementor)
    defer = Rack::Utils::Context.new(redic, defer_session)
    defer_request = Rack::MockRequest.new(defer)
    count_request = Rack::MockRequest.new(count)

    res0 = defer_request.get(ROOT_PATH)

    assert_nil res0[Rack::SET_COOKIE]
    assert_equal('{"counter"=>1}', res0.body)

    res0 = count_request.get(ROOT_PATH)
    res1 = defer_request.get(ROOT_PATH, Rack::HTTP_COOKIE => res0[Rack::SET_COOKIE])

    assert_equal('{"counter"=>2}', res1.body)
    res2 = defer_request.get(ROOT_PATH, Rack::HTTP_COOKIE => res0[Rack::SET_COOKIE])

    assert_equal('{"counter"=>3}', res2.body)
  end

  it 'omits cookie and state update with :skip option' do
    redic = Rack::Session::Redic.new(incrementor)
    count = Rack::Utils::Context.new(redic, incrementor)
    skip = Rack::Utils::Context.new(redic, skip_session)
    skip_request = Rack::MockRequest.new(skip)
    count_request = Rack::MockRequest.new(count)

    res0 = skip_request.get(ROOT_PATH)

    assert_nil res0[Rack::SET_COOKIE]
    assert_equal('{"counter"=>1}', res0.body)

    res0 = count_request.get(ROOT_PATH)
    res1 = skip_request.get(ROOT_PATH, Rack::HTTP_COOKIE => res0[Rack::SET_COOKIE])

    assert_equal('{"counter"=>2}', res1.body)
    res2 = skip_request.get(ROOT_PATH, Rack::HTTP_COOKIE => res0[Rack::SET_COOKIE])

    assert_equal('{"counter"=>2}', res2.body)
  end

  it 'updates deep hashes correctly' do
    hash_check = proc do |env|
      session = env['rack.session']

      if session.include?('test')
        session[:f][:g][:h] = :j
      else
        session.update a: :b, c: { d: :e }, f: { g: { h: :i } }, 'test' => true
      end

      [200, {}, [session.inspect]]
    end

    redic = Rack::Session::Redic.new(hash_check)
    request = Rack::MockRequest.new(redic)

    res0 = request.get(ROOT_PATH)
    session_id = (cookie = res0[Rack::SET_COOKIE])[session_match, 1]
    ses0 = redic.storage.call('GET', session_id)

    request.get(ROOT_PATH, Rack::HTTP_COOKIE => cookie)
    ses1 = redic.storage.call('GET', session_id)

    refute_equal ses1, ses0
  end
end
