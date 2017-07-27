require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ApiAuth::Headers do
  describe '#canonical_string' do
    context 'uri edge cases' do
      let(:request) { RestClient::Request.new(url: uri, method: :get) }
      subject(:headers) { described_class.new(request) }
      let(:uri) { '' }

      context 'empty uri' do
        let(:uri) { 'foo.com'.freeze }

        it 'adds / to canonical string' do
          expect(subject.canonical_string).to eq('GET,,,/,')
        end
      end

      context 'uri with just host without /' do
        let(:uri) { 'http://google.com'.freeze }

        it 'return / as canonical string path' do
          expect(subject.canonical_string).to eq('GET,,,/,')
        end

        it 'does not change request url (by removing host)' do
          expect(request.url).to eq(uri)
        end
      end

      context 'uri with host and /' do
        let(:uri) { 'http://google.com/'.freeze }

        it 'return / as canonical string path' do
          expect(subject.canonical_string).to eq('GET,,,/,')
        end

        it 'does not change request url (by removing host)' do
          expect(request.url).to eq(uri)
        end
      end
    end

    context 'string construction' do
      context 'with a driver that supplies http_method' do
        let(:request) { RestClient::Request.new(url: 'http://google.com', method: :get) }
        subject(:headers) { described_class.new(request) }
        let(:driver) { headers.instance_variable_get('@request') }

        before do
          allow(driver).to receive(:http_method).and_return 'GET'
          allow(driver).to receive(:content_type).and_return 'text/html'
          allow(driver).to receive(:content_md5).and_return '12345'
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
          allow(driver).to receive(:content_md5).and_return '12345'
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
          allow(driver).to receive(:content_md5).and_return '12345'
          allow(driver).to receive(:timestamp).and_return 'Mon, 23 Jan 1984 03:29:56 GMT'
        end

        context 'the driver uses the original_uri' do
          it 'constructs the canonical_string with the original_uri' do
            expect(headers.canonical_string).to eq 'GET,text/html,12345,/api/resource.xml?foo=bar&bar=foo,Mon, 23 Jan 1984 03:29:56 GMT'
          end
        end
      end
    end
  end

  describe '#calculate_md5' do
    subject(:headers) { described_class.new(request) }
    let(:driver) { headers.instance_variable_get('@request') }

    context 'no md5 already calculated' do
      let(:request) do
        RestClient::Request.new(
          url: 'http://google.com',
          method: :post,
          payload: "hello\nworld"
        )
      end

      it 'populates the md5 header' do
        expect(driver).to receive(:populate_content_md5)
        headers.calculate_md5
      end
    end

    context 'md5 already calculated' do
      let(:request) do
        RestClient::Request.new(
          url: 'http://google.com',
          method: :post,
          payload: "hello\nworld",
          headers: { content_md5: 'abcd' }
        )
      end

      it "doesn't populate the md5 header" do
        expect(driver).not_to receive(:populate_content_md5)
        headers.calculate_md5
      end
    end
  end

  describe '#md5_mismatch?' do
    let(:request) { RestClient::Request.new(url: 'http://google.com', method: :get) }
    subject(:headers) { described_class.new(request) }
    let(:driver) { headers.instance_variable_get('@request') }

    context 'when request has md5 header' do
      it 'asks the driver' do
        allow(driver).to receive(:content_md5).and_return '1234'

        expect(driver).to receive(:md5_mismatch?).and_call_original
        headers.md5_mismatch?
      end
    end

    context 'when request has no md5' do
      it "doesn't ask the driver" do
        allow(driver).to receive(:content_md5).and_return ''

        expect(driver).not_to receive(:md5_mismatch?).and_call_original
        headers.md5_mismatch?
      end

      it 'returns false' do
        allow(driver).to receive(:content_md5).and_return ''

        expect(headers.md5_mismatch?).to be false
      end
    end
  end
end
