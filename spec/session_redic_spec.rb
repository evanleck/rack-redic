# encoding: UTF-8
# frozen_string_literal: true
require 'rack/lint'
require 'rack/mock'

# These tests are unceremoniously copied and modified from
# https://github.com/rack/rack/blob/master/test/spec_session_memcache.rb.
describe Rack::Session::Redic do
  ROOT = '/'

  session_key = Rack::Session::Abstract::Persisted::DEFAULT_OPTIONS[:key]
  session_match = /#{session_key}=([0-9a-fA-F]+);/

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
    res = Rack::MockRequest.new(redic).get(ROOT)

    expect(res[Rack::SET_COOKIE]).to include("#{ session_key }=")
    expect(res.body).to eq('{"counter"=>1}')
  end

  it 'determines session from a cookie' do
    redic = Rack::Session::Redic.new(incrementor)
    req = Rack::MockRequest.new(redic)
    res = req.get(ROOT)

    cookie = res[Rack::SET_COOKIE]

    expect(req.get(ROOT, Rack::HTTP_COOKIE => cookie).body).to eq('{"counter"=>2}')
    expect(req.get(ROOT, Rack::HTTP_COOKIE => cookie).body).to eq('{"counter"=>3}')
  end

  it 'determines session only from a cookie by default' do
    redic = Rack::Session::Redic.new(incrementor)
    req = Rack::MockRequest.new(redic)
    res = req.get(ROOT)
    sid = res[Rack::SET_COOKIE][session_match, 1]

    expect(req.get("/?rack.session=#{sid}").body).to eq('{"counter"=>1}')
    expect(req.get("/?rack.session=#{sid}").body).to eq('{"counter"=>1}')
  end

  it 'determines session from params' do
    redic = Rack::Session::Redic.new(incrementor, cookie_only: false)
    req = Rack::MockRequest.new(redic)
    res = req.get(ROOT)
    sid = res[Rack::SET_COOKIE][session_match, 1]

    expect(req.get("/?rack.session=#{sid}").body).to eq('{"counter"=>2}')
    expect(req.get("/?rack.session=#{sid}").body).to eq('{"counter"=>3}')
  end

  it 'survives nonexistant cookies' do
    bad_cookie = "rack.session=#{ SecureRandom.hex(16) }"

    redic = Rack::Session::Redic.new(incrementor)
    res = Rack::MockRequest.new(redic).get(ROOT, Rack::HTTP_COOKIE => bad_cookie)

    expect(res.body).to eq('{"counter"=>1}')

    cookie = res[Rack::SET_COOKIE][session_match]
    expect(cookie).not_to match(/#{ bad_cookie }/)
  end

  it 'maintains freshness' do
    redic = Rack::Session::Redic.new(incrementor, expire_after: 3)
    res = Rack::MockRequest.new(redic).get(ROOT)
    expect(res.body).to include('"counter"=>1')

    cookie = res[Rack::SET_COOKIE]
    res = Rack::MockRequest.new(redic).get(ROOT, Rack::HTTP_COOKIE => cookie)

    expect(res[Rack::SET_COOKIE]).to eq(cookie)
    expect(res.body).to include('"counter"=>2')

    puts 'Sleeping to expire session' if $DEBUG
    sleep 4

    res = Rack::MockRequest.new(redic).get(ROOT, Rack::HTTP_COOKIE => cookie)
    expect(res[Rack::SET_COOKIE]).not_to eq(cookie)
    expect(res.body).to include('"counter"=>1')
  end

  it 'does not send the same session id if it did not change' do
    redic = Rack::Session::Redic.new(incrementor)
    req = Rack::MockRequest.new(redic)

    res0 = req.get(ROOT)
    cookie = res0[Rack::SET_COOKIE][session_match]
    expect(res0.body).to eq('{"counter"=>1}')

    res1 = req.get(ROOT, Rack::HTTP_COOKIE => cookie)
    expect(res1[Rack::SET_COOKIE]).to eq(nil)
    expect(res1.body).to eq('{"counter"=>2}')

    res2 = req.get(ROOT, Rack::HTTP_COOKIE => cookie)
    expect(res2[Rack::SET_COOKIE]).to eq(nil)
    expect(res2.body).to eq('{"counter"=>3}')
  end

  it 'deletes cookies with :drop option' do
    redic = Rack::Session::Redic.new(incrementor)
    req = Rack::MockRequest.new(redic)
    drop = Rack::Utils::Context.new(redic, drop_session)
    dreq = Rack::MockRequest.new(drop)

    res1 = req.get(ROOT)
    session = (cookie = res1[Rack::SET_COOKIE])[session_match]
    expect(res1.body).to eq('{"counter"=>1}')

    res2 = dreq.get(ROOT, Rack::HTTP_COOKIE => cookie)
    expect(res2[Rack::SET_COOKIE]).to eq(nil)
    expect(res2.body).to eq('{"counter"=>2}')

    res3 = req.get(ROOT, Rack::HTTP_COOKIE => cookie)
    expect(res3[Rack::SET_COOKIE][session_match]).not_to eq(session)
    expect(res3.body).to eq('{"counter"=>1}')
  end

  it 'provides new session id with :renew option' do
    redic = Rack::Session::Redic.new(incrementor)
    req = Rack::MockRequest.new(redic)
    renew = Rack::Utils::Context.new(redic, renew_session)
    rreq = Rack::MockRequest.new(renew)

    res1 = req.get(ROOT)
    session = (cookie = res1[Rack::SET_COOKIE])[session_match]
    expect(res1.body).to eq('{"counter"=>1}')

    res2 = rreq.get(ROOT, Rack::HTTP_COOKIE => cookie)
    new_cookie = res2[Rack::SET_COOKIE]
    new_session = new_cookie[session_match]
    expect(new_session).not_to eq(session)
    expect(res2.body).to eq('{"counter"=>2}')

    res3 = req.get(ROOT, Rack::HTTP_COOKIE => new_cookie)
    expect(res3.body).to eq('{"counter"=>3}')

    # Old cookie was deleted
    res4 = req.get(ROOT, Rack::HTTP_COOKIE => cookie)
    expect(res4.body).to eq('{"counter"=>1}')
  end

  it 'omits cookie with :defer option but still updates the state' do
    redic = Rack::Session::Redic.new(incrementor)
    count = Rack::Utils::Context.new(redic, incrementor)
    defer = Rack::Utils::Context.new(redic, defer_session)
    dreq = Rack::MockRequest.new(defer)
    creq = Rack::MockRequest.new(count)

    res0 = dreq.get(ROOT)
    expect(res0[Rack::SET_COOKIE]).to eq(nil)
    expect(res0.body).to eq('{"counter"=>1}')

    res0 = creq.get(ROOT)
    res1 = dreq.get(ROOT, Rack::HTTP_COOKIE => res0[Rack::SET_COOKIE])
    expect(res1.body).to eq('{"counter"=>2}')
    res2 = dreq.get(ROOT, Rack::HTTP_COOKIE => res0[Rack::SET_COOKIE])
    expect(res2.body).to eq('{"counter"=>3}')
  end

  it 'omits cookie and state update with :skip option' do
    redic = Rack::Session::Redic.new(incrementor)
    count = Rack::Utils::Context.new(redic, incrementor)
    skip = Rack::Utils::Context.new(redic, skip_session)
    sreq = Rack::MockRequest.new(skip)
    creq = Rack::MockRequest.new(count)

    res0 = sreq.get(ROOT)
    expect(res0[Rack::SET_COOKIE]).to eq(nil)
    expect(res0.body).to eq('{"counter"=>1}')

    res0 = creq.get(ROOT)
    res1 = sreq.get(ROOT, Rack::HTTP_COOKIE => res0[Rack::SET_COOKIE])
    expect(res1.body).to eq('{"counter"=>2}')
    res2 = sreq.get(ROOT, Rack::HTTP_COOKIE => res0[Rack::SET_COOKIE])
    expect(res2.body).to eq('{"counter"=>2}')
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
    req = Rack::MockRequest.new(redic)

    res0 = req.get(ROOT)
    session_id = (cookie = res0[Rack::SET_COOKIE])[session_match, 1]
    ses0 = redic.storage.get(session_id)

    req.get(ROOT, Rack::HTTP_COOKIE => cookie)
    ses1 = redic.storage.get(session_id)

    expect(ses1).not_to eq(ses0)
  end
end