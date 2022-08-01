require 'spec_helper'
require 'faraday/api_auth'

describe Faraday::ApiAuth::Middleware do
  it 'adds the Authorization headers' do
    conn = Faraday.new('http://localhost/') do |f|
      f.request :api_auth, 'foo', 'secret', digest: 'sha256'
      f.adapter :test do |stub|
        stub.get('http://localhost/test') do |env|
          [200, {}, env.request_headers['Authorization']]
        end
      end
    end
    response = conn.get('test', nil, { 'Date' => 'Tue, 02 Aug 2022 09:29:24 GMT' })
    expect(response.body).to eq 'APIAuth-HMAC-SHA256 foo:Tn/lIZ9kphcO32DwG4wFHenqBt37miDEIkA5ykLgGiQ='
  end
end
