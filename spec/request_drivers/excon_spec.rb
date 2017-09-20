require 'spec_helper'
require 'api_auth/middleware/excon'

describe ApiAuth::RequestDrivers::ExconRequest do
  let(:timestamp) { Time.now.utc.httpdate }
  let(:body) { "hello\nworld" }
  let(:method) { 'GET' }
  let(:headers) do
    {
      'Authorization' => 'APIAuth 1044:12345',
      'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg==',
      'content-type' => 'text/plain',
      'date' => timestamp
    }
  end

  let(:request) do
    datum = { path: '/resource.xml',
              method: method,
              headers: headers,
              body: body }
    query_string = '?foo=bar&bar=foo'

    ApiAuth::Middleware::ExconRequestWrapper.new(datum, query_string)
  end

  subject(:driven_request) { described_class.new(request) }

  describe 'getting headers correctly' do
    it 'gets the content_type' do
      expect(driven_request.content_type).to eq('text/plain')
    end

    it 'gets the content_md5' do
      expect(driven_request.content_md5).to eq('1B2M2Y8AsgTpgAmY7PhCfg==')
    end

    it 'gets the request_uri' do
      expect(driven_request.request_uri).to eq('/resource.xml?foo=bar&bar=foo')
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

      context 'no body' do
        let(:body) { nil }

        it 'is treated as empty string' do
          expect(driven_request.calculated_md5).to eq('1B2M2Y8AsgTpgAmY7PhCfg==')
        end
      end
    end

    describe 'http_method' do
      let(:method) { 'PUT' }

      it 'is as passed' do
        expect(driven_request.http_method).to eq(method)
      end
    end
  end

  describe 'setting headers correctly' do
    let(:headers) { { 'content-type' => 'text/plain' } }

    describe '#populate_content_md5' do
      context 'when there is no content body' do
        let(:body) { nil }

        it "doesn't populate content-md5" do
          driven_request.populate_content_md5
          expect(request.headers['Content-MD5']).to be_nil
        end
      end

      context 'when there is a content body' do
        let(:body) { "hello\nworld" }

        it 'populates content-md5' do
          driven_request.populate_content_md5
          expect(request.headers['Content-MD5']).to eq('kZXQvrKoieG+Be1rsZVINw==')
        end

        it 'refreshes the cached headers' do
          driven_request.populate_content_md5
          expect(driven_request.content_md5).to eq('kZXQvrKoieG+Be1rsZVINw==')
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
    context 'when there is no content body' do
      let(:body) { nil }

      it 'is false' do
        expect(driven_request.md5_mismatch?).to be false
      end
    end

    context 'when there is a content body' do
      let(:body) { "hello\nworld" }

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
  end
end
