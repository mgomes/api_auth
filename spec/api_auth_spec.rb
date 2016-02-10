# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'ApiAuth' do
  describe 'generating secret keys' do
    it 'should generate secret keys' do
      ApiAuth.generate_secret_key
    end

    it 'should generate secret keys that are 88 characters' do
      expect(ApiAuth.generate_secret_key.size).to be(88)
    end

    it 'should generate keys that have a Hamming Distance of at least 65' do
      key1 = ApiAuth.generate_secret_key
      key2 = ApiAuth.generate_secret_key
      expect(Amatch::Hamming.new(key1).match(key2)).to be > 65
    end
  end

  def hmac(secret_key, request, canonical_string = nil)
    canonical_string ||= ApiAuth::Headers.new(request).canonical_string
    digest = OpenSSL::Digest.new('sha1')
    ApiAuth.b64_encode(OpenSSL::HMAC.digest(digest, secret_key, canonical_string))
  end

  describe '.sign!' do
    let(:request) { RestClient::Request.new(:url => 'http://google.com', :method => :get) }
    let(:headers) { ApiAuth::Headers.new(request) }

    it 'generates date header before signing' do
      expect(ApiAuth::Headers).to receive(:new).and_return(headers)

      expect(headers).to receive(:set_date).ordered
      expect(headers).to receive(:sign_header).ordered

      ApiAuth.sign!(request, 'abc', '123')
    end

    it 'generates content-md5 header before signing' do
      expect(ApiAuth::Headers).to receive(:new).and_return(headers)
      expect(headers).to receive(:calculate_md5).ordered
      expect(headers).to receive(:sign_header).ordered

      ApiAuth.sign!(request, 'abc', '123')
    end

    it 'returns the same request object back' do
      expect(ApiAuth.sign!(request, 'abc', '123')).to be request
    end

    it 'calculates the hmac_signature as expected' do
      ApiAuth.sign!(request, '1044', '123')
      signature = hmac('123', request)
      expect(request.headers['Authorization']).to eq("APIAuth 1044:#{signature}")
    end

    context 'when passed the with_http_method option' do
      let(:request) do
        Net::HTTP::Put.new('/resource.xml?foo=bar&bar=foo',
                           'content-type' => 'text/plain',
                           'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg==',
                           'date' => Time.now.utc.httpdate
        )
      end

      let(:canonical_string) { ApiAuth::Headers.new(request).canonical_string_with_http_method }

      it 'calculates the hmac_signature with http method' do
        ApiAuth.sign!(request, '1044', '123', :with_http_method => true)
        signature = hmac('123', request, canonical_string)
        expect(request['Authorization']).to eq("APIAuth 1044:#{signature}")
      end
    end
  end

  describe '.authentic?' do
    let(:request) do
      new_request = Net::HTTP::Put.new('/resource.xml?foo=bar&bar=foo',
                                       'content-type' => 'text/plain',
                                       'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg==',
                                       'date' => Time.now.utc.httpdate
      )

      signature = hmac('123', new_request)
      new_request['Authorization'] = "APIAuth 1044:#{signature}"
      new_request
    end

    it 'validates that the signature in the request header matches the way we sign it' do
      expect(ApiAuth.authentic?(request, '123')).to eq true
    end

    it 'fails to validate a non matching signature' do
      expect(ApiAuth.authentic?(request, '456')).to eq false
    end

    it 'fails to validate non matching md5' do
      request['content-md5'] = '12345'
      expect(ApiAuth.authentic?(request, '123')).to eq false
    end

    it 'fails to validate expired requests' do
      request['date'] = 16.minutes.ago.utc.httpdate
      expect(ApiAuth.authentic?(request, '123')).to eq false
    end

    it 'fails to validate if the date is invalid' do
      request['date'] = "٢٠١٤-٠٩-٠٨ ١٦:٣١:١٤ +٠٣٠٠"
      expect(ApiAuth.authentic?(request, '123')).to eq false
    end

    context 'canonical string contains the http_method' do
      let(:request) do
        new_request = Net::HTTP::Put.new('/resource.xml?foo=bar&bar=foo',
                                         'content-type' => 'text/plain',
                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg==',
                                         'date' => Time.now.utc.httpdate
        )
        canonical_string = ApiAuth::Headers.new(new_request).canonical_string_with_http_method
        signature = hmac('123', new_request, canonical_string)
        new_request['Authorization'] = "APIAuth 1044:#{signature}"
        new_request
      end

      it 'validates for canonical_strings containing the http_method' do
        expect(ApiAuth.authentic?(request, '123')).to eq true
      end

      it 'fails to validate if the request method differs' do
        canonical_string = ApiAuth::Headers.new(request).canonical_string_with_http_method('POST')
        signature = hmac('123', request, canonical_string)
        request['Authorization'] = "APIAuth 1044:#{signature}"
        expect(ApiAuth.authentic?(request, '123')).to eq false
      end
    end
  end

  describe '.access_id' do
    context 'normal APIAuth Auth header' do
      let(:request) do
        RestClient::Request.new(
          :url => 'http://google.com',
          :method => :get,
          :headers => { :authorization => 'APIAuth 1044:aGVsbG8gd29ybGQ=' }
        )
      end

      it 'parses it from the Auth Header' do
        expect(ApiAuth.access_id(request)).to eq('1044')
      end
    end

    context 'Corporate prefixed APIAuth header' do
      let(:request) do
        RestClient::Request.new(
          :url => 'http://google.com',
          :method => :get,
          :headers => { :authorization => 'Corporate APIAuth 1044:aGVsbG8gd29ybGQ=' }
        )
      end

      it 'parses it from the Auth Header' do
        expect(ApiAuth.access_id(request)).to eq('1044')
      end
    end
  end
end
