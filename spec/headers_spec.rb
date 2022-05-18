require 'spec_helper'

describe ApiAuth::Headers do
  describe '#canonical_string' do
    context 'uri edge cases' do
      let(:request) { RestClient::Request.new(url: uri, method: :get) }
      subject(:headers) { described_class.new(request) }
      let(:uri) { '' }

      context 'uri with just host without /' do
        let(:uri) { 'https://google.com'.freeze }

        it 'return / as canonical string path' do
          expect(subject.canonical_string).to eq('GET,,,/,')
        end

        it 'does not change request url (by removing host)' do
          expect(request.url).to eq(uri)
        end
      end

      context 'uri with host and /' do
        let(:uri) { 'https://google.com/'.freeze }

        it 'return / as canonical string path' do
          expect(subject.canonical_string).to eq('GET,,,/,')
        end

        it 'does not change request url (by removing host)' do
          expect(request.url).to eq(uri)
        end
      end

      context 'uri has a string matching https:// in it' do
        let(:uri) { 'https://google.com/?redirect_to=https://www.example.com'.freeze }

        it 'return /?redirect_to=https://www.example.com as canonical string path' do
          expect(subject.canonical_string).to eq('GET,,,/?redirect_to=https://www.example.com,')
        end

        it 'does not change request url (by removing host)' do
          expect(request.url).to eq(uri)
        end
      end
    end

    context 'string construction' do
      context 'with a driver that supplies http_method' do
        let(:request) { RestClient::Request.new(url: 'https://google.com', method: :get) }
        subject(:headers) { described_class.new(request) }
        let(:driver) { headers.instance_variable_get('@request') }

        before do
          allow(driver).to receive(:http_method).and_return 'GET'
          allow(driver).to receive(:content_type).and_return 'text/html'
          allow(driver).to receive(:content_hash).and_return '12345'
          allow(driver).to receive(:request_uri).and_return '/foo'
          allow(driver).to receive(:timestamp).and_return 'Mon, 23 Jan 1984 03:29:56 GMT'
        end

        context 'when not passed an override' do
          it "constructs the canonical_string with the driver's http method" do
            expect(headers.canonical_string).to eq 'GET,text/html,12345,/foo,Mon, 23 Jan 1984 03:29:56 GMT'
          end
        end

        context 'when passed an override' do
          it 'constructs the canonical_string with the overridden http method' do
            expect(headers.canonical_string('put')).to eq 'PUT,text/html,12345,/foo,Mon, 23 Jan 1984 03:29:56 GMT'
          end
        end
      end

      context "when a driver that doesn't supply http_method" do
        let(:request) do
          Curl::Easy.new('/resource.xml?foo=bar&bar=foo') do |curl|
            curl.headers = { 'Content-Type' => 'text/plain' }
          end
        end
        subject(:headers) { described_class.new(request) }
        let(:driver) { headers.instance_variable_get('@request') }

        before do
          allow(driver).to receive(:http_method).and_return nil
          allow(driver).to receive(:content_type).and_return 'text/html'
          allow(driver).to receive(:content_hash).and_return '12345'
          allow(driver).to receive(:request_uri).and_return '/foo'
          allow(driver).to receive(:timestamp).and_return 'Mon, 23 Jan 1984 03:29:56 GMT'
        end

        context 'when not passed an override' do
          it 'raises an error' do
            expect { headers.canonical_string }.to raise_error(ArgumentError)
          end
        end

        context 'when passed an override' do
          it 'constructs the canonical_string with the overridden http method' do
            expect(headers.canonical_string('put')).to eq 'PUT,text/html,12345,/foo,Mon, 23 Jan 1984 03:29:56 GMT'
          end
        end
      end

      context "when there's a proxy server (e.g. Nginx) with rewrite rules" do
        let(:request) do
          Faraday::Request.create('GET') do |req|
            req.options = Faraday::RequestOptions.new(Faraday::FlatParamsEncoder)
            req.params = Faraday::Utils::ParamsHash.new
            req.url('/resource.xml?foo=bar&bar=foo')
            req.headers = { 'X-Original-URI' => '/api/resource.xml?foo=bar&bar=foo' }
          end
        end
        subject(:headers) { described_class.new(request) }
        let(:driver) { headers.instance_variable_get('@request') }

        before do
          allow(driver).to receive(:content_type).and_return 'text/html'
          allow(driver).to receive(:content_hash).and_return '12345'
          allow(driver).to receive(:timestamp).and_return 'Mon, 23 Jan 1984 03:29:56 GMT'
        end

        context 'the driver uses the original_uri' do
          it 'constructs the canonical_string with the original_uri' do
            expect(headers.canonical_string).to eq 'GET,text/html,12345,/api/resource.xml?foo=bar&bar=foo,Mon, 23 Jan 1984 03:29:56 GMT'
          end
        end
      end

      context 'when headers to sign are provided' do
        let(:request) do
          Faraday::Request.create('GET') do |req|
            req.options = Faraday::RequestOptions.new(Faraday::FlatParamsEncoder)
            req.params = Faraday::Utils::ParamsHash.new
            req.url('/resource.xml?foo=bar&bar=foo')
            req.headers = { 'X-Forwarded-For' => '192.168.1.1' }
          end
        end
        subject(:headers) { described_class.new(request) }
        let(:driver) { headers.instance_variable_get('@request') }

        before do
          allow(driver).to receive(:content_type).and_return 'text/html'
          allow(driver).to receive(:content_hash).and_return '12345'
          allow(driver).to receive(:timestamp).and_return 'Mon, 23 Jan 1984 03:29:56 GMT'
        end

        context 'the driver uses the original_uri' do
          it 'constructs the canonical_string with the original_uri' do
            expect(headers.canonical_string(nil, %w[X-FORWARDED-FOR]))
              .to eq 'GET,text/html,12345,/resource.xml?bar=foo&foo=bar,Mon, 23 Jan 1984 03:29:56 GMT,192.168.1.1'
          end
        end
      end
    end
  end

  describe '#calculate_hash' do
    subject(:headers) { described_class.new(request) }
    let(:driver) { headers.instance_variable_get('@request') }

    context 'no content hash already calculated' do
      let(:request) do
        RestClient::Request.new(
          url: 'https://google.com',
          method: :post,
          payload: "hello\nworld"
        )
      end

      it 'populates the content hash header' do
        expect(driver).to receive(:populate_content_hash)
        headers.calculate_hash
      end
    end

    context 'hash already calculated' do
      let(:request) do
        RestClient::Request.new(
          url: 'https://google.com',
          method: :post,
          payload: "hello\nworld",
          headers: { 'X-Authorization-Content-SHA256' => 'abcd' }
        )
      end

      it "doesn't populate the X-Authorization-Content-SHA256 header" do
        expect(driver).not_to receive(:populate_content_hash)
        headers.calculate_hash
      end
    end
  end

  describe '#content_hash_mismatch?' do
    let(:request) { RestClient::Request.new(url: 'https://google.com', method: :get) }
    subject(:headers) { described_class.new(request) }
    let(:driver) { headers.instance_variable_get('@request') }

    context 'when request has X-Authorization-Content-SHA256 header' do
      it 'asks the driver' do
        allow(driver).to receive(:content_hash).and_return '1234'

        expect(driver).to receive(:content_hash_mismatch?).and_call_original
        headers.content_hash_mismatch?
      end
    end

    context 'when request has no content hash' do
      it "doesn't ask the driver" do
        allow(driver).to receive(:content_hash).and_return nil

        expect(driver).not_to receive(:content_hash_mismatch?).and_call_original
        headers.content_hash_mismatch?
      end

      it 'returns false' do
        allow(driver).to receive(:content_hash).and_return nil

        expect(headers.content_hash_mismatch?).to be false
      end
    end
  end
end
