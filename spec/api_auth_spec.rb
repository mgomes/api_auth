require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'ApiAuth' do
  let(:default_configuration) { ApiAuth::Configuration.new }

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

  def hmac(secret_key, request, canonical_string = nil, digest = 'sha1')
    canonical_string ||= ApiAuth::Headers.new(request).canonical_string
    digest = OpenSSL::Digest.new(digest)
    ApiAuth.b64_encode(OpenSSL::HMAC.digest(digest, secret_key, canonical_string))
  end

  describe '.sign!' do
    let(:request) { RestClient::Request.new(url: 'http://google.com', method: :get) }
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
      expect(request.headers['Authorization']).to eq("#{default_configuration.algorithm} 1044:#{signature}")
    end

    context 'when passed the hmac digest option' do
      let(:request) do
        Net::HTTP::Put.new('/resource.xml?foo=bar&bar=foo',
                           'content-type' => 'text/plain',
                           'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg==',
                           default_configuration.date_header => Time.now.utc.strftime(default_configuration.date_format))
      end

      let(:canonical_string) { ApiAuth::Headers.new(request).canonical_string }

      it 'calculates the hmac_signature with http method' do
        ApiAuth.sign!(request, '1044', '123', digest: 'sha256')
        signature = hmac('123', request, canonical_string, 'sha256')
        expect(request['Authorization']).to eq("#{default_configuration.algorithm}-HMAC-SHA256 1044:#{signature}")
      end
    end
  end

  describe '.authentic?' do
    let(:request) do
      Net::HTTP::Put.new('/resource.xml?foo=bar&bar=foo',
                         'content-type' => 'text/plain',
                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg==',
                         default_configuration.date_header => Time.now.utc.strftime(default_configuration.date_format))
    end

    let(:signed_request) do
      signature = hmac('123', request)
      request['Authorization'] = "#{default_configuration.algorithm} 1044:#{signature}"
      request
    end

    it 'validates that the signature in the request header matches the way we sign it' do
      expect(ApiAuth.authentic?(signed_request, '123')).to eq true
    end

    it 'fails to validate a non matching signature' do
      expect(ApiAuth.authentic?(signed_request, '456')).to eq false
    end

    it 'fails to validate non matching md5' do
      request['content-md5'] = '12345'
      expect(ApiAuth.authentic?(signed_request, '123')).to eq false
    end

    it 'fails to validate expired requests' do
      request[default_configuration.date_header] = 16.minutes.ago.utc.strftime(default_configuration.date_format)
      expect(ApiAuth.authentic?(signed_request, '123')).to eq false
    end

    context 'when there is a custom date format' do
      before { allow_any_instance_of(ApiAuth::Configuration).to receive(:date_format) { '%Y-%m-%d' } }

      it 'fails to validate expired requests' do
        request[default_configuration.date_header] = 16.minutes.ago.utc.strftime(default_configuration.date_format)
        expect(ApiAuth.authentic?(signed_request, '123')).to eq false
      end
    end

    it 'fails to validate if the date is invalid' do
      request[default_configuration.date_header] = '٢٠١٤-٠٩-٠٨ ١٦:٣١:١٤ +٠٣٠٠'
      expect(ApiAuth.authentic?(signed_request, '123')).to eq false
    end

    it 'fails to validate if the request method differs' do
      canonical_string = ApiAuth::Headers.new(request).canonical_string('POST')
      signature = hmac('123', request, canonical_string)
      request['Authorization'] = "#{default_configuration.algorithm} 1044:#{signature}"
      expect(ApiAuth.authentic?(request, '123')).to eq false
    end

    context 'when passed the hmac digest option' do
      let(:request) do
        new_request = Net::HTTP::Put.new('/resource.xml?foo=bar&bar=foo',
                                         'content-type' => 'text/plain',
                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg==',
                                         default_configuration.date_header => Time.now.utc.strftime(default_configuration.date_format))
        canonical_string = ApiAuth::Headers.new(new_request).canonical_string
        signature = hmac('123', new_request, canonical_string, 'sha256')
        new_request['Authorization'] = "#{default_configuration.algorithm}-HMAC-#{digest} 1044:#{signature}"
        new_request
      end

      context 'valid request digest' do
        let(:digest) { 'SHA256' }

        context 'matching client digest' do
          it 'validates matching digest' do
            expect(ApiAuth.authentic?(request, '123', digest: 'sha256')).to eq true
          end
        end

        context 'different client digest' do
          it 'raises an exception' do
            expect { ApiAuth.authentic?(request, '123', digest: 'sha512') }.to raise_error(ApiAuth::InvalidRequestDigest)
          end
        end
      end

      context 'invalid request digest' do
        let(:digest) { 'SHA111' }

        it 'fails validation' do
          expect(ApiAuth.authentic?(request, '123', digest: 'sha111')).to eq false
        end
      end
    end

    context 'when the clock_skew is configured' do
      before do
        allow_any_instance_of(ApiAuth::Configuration).to receive(:clock_skew) { 60.seconds }
      end

      it 'fails to validate expired requests' do
        request['date'] = 90.seconds.ago.utc.httpdate
        expect(ApiAuth.authentic?(signed_request, '123')).to eq false
      end

      it 'fails to validate far future requests' do
        request['date'] = 90.seconds.from_now.utc.httpdate
        expect(ApiAuth.authentic?(signed_request, '123')).to eq false
      end
    end
  end

  describe '.access_id' do
    context 'normal APIAuth Auth header' do
      let(:request) do
        RestClient::Request.new(
          url: 'http://google.com',
          method: :get,
          headers: { authorization: "#{default_configuration.algorithm} 1044:aGVsbG8gd29ybGQ=" }
        )
      end

      it 'parses it from the Auth Header' do
        expect(ApiAuth.access_id(request)).to eq('1044')
      end
    end

    context 'Corporate prefixed APIAuth header' do
      let(:request) do
        RestClient::Request.new(
          url: 'http://google.com',
          method: :get,
          headers: { authorization: "Corporate #{default_configuration.algorithm} 1044:aGVsbG8gd29ybGQ=" }
        )
      end

      it 'parses it from the Auth Header' do
        expect(ApiAuth.access_id(request)).to eq('1044')
      end
    end
  end
end
