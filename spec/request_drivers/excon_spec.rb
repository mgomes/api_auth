require 'spec_helper'
require 'api_auth/middleware/excon'
require 'stringio'

describe ApiAuth::RequestDrivers::ExconRequest do
  let(:timestamp) { Time.now.utc.httpdate }
  let(:body) { "hello\nworld" }
  let(:method) { :get }
  let(:headers) do
    {
      'Authorization' => 'APIAuth 1044:12345',
      'X-Authorization-Content-SHA256' => '47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=',
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

    it 'gets the content_hash' do
      expect(driven_request.content_hash).to eq('47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=')
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

    describe '#calculated_hash' do
      it 'calculates hash from the body' do
        expect(driven_request.calculated_hash).to eq('JsYKYdAdtYNspw/v1EpqAWYgQTyO9fJZpsVhLU9507g=')
      end

      context 'no body' do
        let(:body) { nil }

        it 'is treated as empty string' do
          expect(driven_request.calculated_hash).to eq('47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=')
        end
      end

      context 'IO body' do
        let(:body) { StringIO.new("hello\nworld") }

        it 'reads the body and rewinds the stream' do
          result = driven_request.calculated_hash

          expect(result).to eq('JsYKYdAdtYNspw/v1EpqAWYgQTyO9fJZpsVhLU9507g=')
          expect(body.pos).to eq(0)
        end
      end
    end

    describe 'http_method' do
      context 'when put request' do
        let(:method) { :put }

        it 'returns upcased put' do
          expect(driven_request.http_method).to eq('PUT')
        end
      end

      context 'when get request' do
        let(:method) { :get }

        it 'returns upcased get' do
          expect(driven_request.http_method).to eq('GET')
        end
      end
    end
  end

  describe 'setting headers correctly' do
    let(:headers) { { 'content-type' => 'text/plain' } }

    describe '#populate_content_hash' do
      context 'when request type has no body' do
        let(:method) { :get }

        it "doesn't populate content hash" do
          driven_request.populate_content_hash
          expect(request.headers['X-Authorization-Content-SHA256']).to be_nil
        end
      end

      context 'when request type has a body' do
        let(:method) { :put }
        let(:body) { "hello\nworld" }

        it 'populates content hash' do
          driven_request.populate_content_hash
          expect(request.headers['X-Authorization-Content-SHA256']).to eq('JsYKYdAdtYNspw/v1EpqAWYgQTyO9fJZpsVhLU9507g=')
        end

        it 'refreshes the cached headers' do
          driven_request.populate_content_hash
          expect(driven_request.content_hash).to eq('JsYKYdAdtYNspw/v1EpqAWYgQTyO9fJZpsVhLU9507g=')
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

  describe 'content_hash_mismatch?' do
    context 'when request type has no body' do
      let(:method) { :get }

      it 'is false' do
        expect(driven_request.content_hash_mismatch?).to be false
      end
    end

    context 'when request type has a body' do
      let(:method) { :put }
      let(:body) { "hello\nworld" }

      context 'when calculated matches sent' do
        before do
          request.headers['X-Authorization-Content-SHA256'] = 'JsYKYdAdtYNspw/v1EpqAWYgQTyO9fJZpsVhLU9507g='
        end

        it 'is false' do
          expect(driven_request.content_hash_mismatch?).to be false
        end
      end

      context "when calculated doesn't match sent" do
        before do
          request.headers['X-Authorization-Content-SHA256'] = '3'
        end

        it 'is true' do
          expect(driven_request.content_hash_mismatch?).to be true
        end
      end
    end
  end

  describe 'fetch_headers' do
    it 'returns request headers' do
      expect(driven_request.fetch_headers).to include('CONTENT-TYPE' => 'text/plain')
    end
  end
end
