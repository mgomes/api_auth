require 'spec_helper'

describe ApiAuth::RequestDrivers::FaradayRequest do
  let(:timestamp) { Time.now.utc.httpdate }

  let(:faraday_stubs) do
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.put('/resource.xml?foo=bar&bar=foo') { [200, {}, ''] }
      stub.get('/resource.xml?foo=bar&bar=foo') { [200, {}, ''] }
      stub.put('/resource.xml') { [200, {}, ''] }
    end
  end

  let(:faraday_conn) do
    Faraday.new do |builder|
      builder.adapter :test, faraday_stubs
    end
  end

  let(:request_headers) do
    {
      'Authorization' => 'APIAuth 1044:12345',
      'Content-MD5' => '1B2M2Y8AsgTpgAmY7PhCfg==',
      'content-type' => 'text/plain',
      'DATE' => timestamp
    }
  end

  let(:request) do
    faraday_request = nil

    faraday_conn.put '/resource.xml?foo=bar&bar=foo', "hello\nworld" do |request|
      faraday_request = request
      faraday_request.headers.merge!(request_headers)
    end

    faraday_request
  end

  subject(:driven_request) { ApiAuth::RequestDrivers::FaradayRequest.new(request) }

  describe 'getting headers correctly' do
    it 'gets the content_type' do
      expect(driven_request.content_type).to eq('text/plain')
    end

    it 'gets the content_md5' do
      expect(driven_request.content_md5).to eq('1B2M2Y8AsgTpgAmY7PhCfg==')
    end

    it 'gets the request_uri' do
      expect(driven_request.request_uri).to eq('/resource.xml?bar=foo&foo=bar')
    end

    it 'gets the timestamp' do
      expect(driven_request.timestamp).to eq(timestamp)
    end

    it 'gets the authorization_header' do
      expect(driven_request.authorization_header).to eq('APIAuth 1044:12345')
    end

    describe '#calculated_md5' do
      it 'calculates md5 from the body' do
        expect(driven_request.calculated_md5).to eq('kZXQvrKoieG+Be1rsZVINw==')
      end

      it 'treats no body as empty string' do
        request.body = nil
        expect(driven_request.calculated_md5).to eq('1B2M2Y8AsgTpgAmY7PhCfg==')
      end
    end

    describe 'http_method' do
      context 'when put request' do
        let(:request) do
          faraday_request = nil

          faraday_conn.put '/resource.xml?foo=bar&bar=foo', "hello\nworld" do |request|
            faraday_request = request
            faraday_request.headers.merge!(request_headers)
          end

          faraday_request
        end

        it 'returns upcased put' do
          expect(driven_request.http_method).to eq('PUT')
        end
      end

      context 'when get request' do
        let(:request) do
          faraday_request = nil

          faraday_conn.get '/resource.xml?foo=bar&bar=foo' do |request|
            faraday_request = request
            faraday_request.headers.merge!(request_headers)
          end

          faraday_request
        end

        it 'returns upcased get' do
          expect(driven_request.http_method).to eq('GET')
        end
      end
    end
  end

  describe 'setting headers correctly' do
    let(:request_headers) do
      {
        'content-type' => 'text/plain'
      }
    end

    describe '#populate_content_md5' do
      context 'when getting' do
        it "doesn't populate content-md5" do
          request.method = :get
          driven_request.populate_content_md5
          expect(request.headers['Content-MD5']).to be_nil
        end
      end

      context 'when posting' do
        it 'populates content-md5' do
          request.method = :post
          driven_request.populate_content_md5
          expect(request.headers['Content-MD5']).to eq('kZXQvrKoieG+Be1rsZVINw==')
        end

        it 'refreshes the cached headers' do
          driven_request.populate_content_md5
          expect(driven_request.content_md5).to eq('kZXQvrKoieG+Be1rsZVINw==')
        end
      end

      context 'when putting' do
        it 'populates content-md5' do
          request.method = :put
          driven_request.populate_content_md5
          expect(request.headers['Content-MD5']).to eq('kZXQvrKoieG+Be1rsZVINw==')
        end

        it 'refreshes the cached headers' do
          driven_request.populate_content_md5
          expect(driven_request.content_md5).to eq('kZXQvrKoieG+Be1rsZVINw==')
        end
      end

      context 'when patching' do
        it 'populates content-md5' do
          request.method = :patch
          driven_request.populate_content_md5
          expect(request.headers['Content-MD5']).to eq('kZXQvrKoieG+Be1rsZVINw==')
        end

        it 'refreshes the cached headers' do
          driven_request.populate_content_md5
          expect(driven_request.content_md5).to eq('kZXQvrKoieG+Be1rsZVINw==')
        end
      end

      context 'when deleting' do
        it "doesn't populate content-md5" do
          request.method = :delete
          driven_request.populate_content_md5
          expect(request.headers['Content-MD5']).to be_nil
        end
      end
    end

    describe '#set_date' do
      before do
        allow(Time).to receive_message_chain(:now, :utc, :httpdate).and_return(timestamp)
      end

      it 'sets the date header of the request' do
        driven_request.set_date
        expect(request.headers['DATE']).to eq(timestamp)
      end

      it 'refreshes the cached headers' do
        driven_request.set_date
        expect(driven_request.timestamp).to eq(timestamp)
      end
    end

    describe '#set_auth_header' do
      it 'sets the auth header' do
        driven_request.set_auth_header('APIAuth 1044:54321')
        expect(request.headers['Authorization']).to eq('APIAuth 1044:54321')
      end
    end
  end

  describe 'md5_mismatch?' do
    context 'when getting' do
      before do
        request.method = :get
      end

      it 'is false' do
        expect(driven_request.md5_mismatch?).to be false
      end
    end

    context 'when posting' do
      before do
        request.method = :post
      end

      context 'when calculated matches sent' do
        before do
          request.headers['Content-MD5'] = 'kZXQvrKoieG+Be1rsZVINw=='
        end

        it 'is false' do
          expect(driven_request.md5_mismatch?).to be false
        end
      end

      context "when calculated doesn't match sent" do
        before do
          request.headers['Content-MD5'] = '3'
        end

        it 'is true' do
          expect(driven_request.md5_mismatch?).to be true
        end
      end
    end

    context 'when putting' do
      before do
        request.method = :put
      end

      context 'when calculated matches sent' do
        before do
          request.headers['Content-MD5'] = 'kZXQvrKoieG+Be1rsZVINw=='
        end

        it 'is false' do
          expect(driven_request.md5_mismatch?).to be false
        end
      end

      context "when calculated doesn't match sent" do
        before do
          request.headers['Content-MD5'] = '3'
        end

        it 'is true' do
          expect(driven_request.md5_mismatch?).to be true
        end
      end
    end

    context 'when patching' do
      before do
        request.method = :patch
      end

      context 'when calculated matches sent' do
        before do
          request.headers['Content-MD5'] = 'kZXQvrKoieG+Be1rsZVINw=='
        end

        it 'is false' do
          expect(driven_request.md5_mismatch?).to be false
        end
      end

      context "when calculated doesn't match sent" do
        before do
          request.headers['Content-MD5'] = '3'
        end

        it 'is true' do
          expect(driven_request.md5_mismatch?).to be true
        end
      end
    end

    context 'when deleting' do
      before do
        request.method = :delete
      end

      it 'is false' do
        expect(driven_request.md5_mismatch?).to be false
      end
    end
  end
end
