require 'spec_helper'
require 'stringio'
require 'digest'

describe ApiAuth::RequestDrivers::TyphoeusRequest do
  let(:timestamp) { Time.now.utc.httpdate }
  let(:request_url) { 'https://example.com/resource.xml?foo=bar&bar=foo' }
  let(:method) { :put }
  let(:body) { "hello\nworld" }

  let(:request_headers) do
    {
      'Authorization' => 'APIAuth 1044:12345',
      'X-Authorization-Content-SHA256' => 'JsYKYdAdtYNspw/v1EpqAWYgQTyO9fJZpsVhLU9507g=',
      'content-type' => 'text/plain',
      'date' => timestamp
    }
  end

  let(:typhoeus_request) do
    Typhoeus::Request.new(
      request_url,
      method: method,
      headers: request_headers,
      body: body
    )
  end

  subject(:driven_request) { described_class.new(typhoeus_request) }

  describe 'getting headers correctly' do
    it 'gets the content_type' do
      expect(driven_request.content_type).to eq('text/plain')
    end

    it 'gets the content_hash' do
      expect(driven_request.content_hash).to eq('JsYKYdAdtYNspw/v1EpqAWYgQTyO9fJZpsVhLU9507g=')
    end

    it 'gets the request_uri' do
      expect(driven_request.request_uri).to eq('/resource.xml?foo=bar&bar=foo')
    end

    context 'when the URL cannot be parsed' do
      let(:typhoeus_request) do
        Typhoeus::Request.new(
          'https://example.com/resource with spaces',
          method: method,
          headers: request_headers,
          body: body
        )
      end

      it 'falls back to a safe default path' do
        expect(driven_request.request_uri).to eq('/')
      end
    end

    context 'when query params are provided separately' do
      let(:request_url) { 'https://example.com/resource.xml' }
      let(:typhoeus_request) do
        Typhoeus::Request.new(
          request_url,
          method: method,
          headers: request_headers,
          params: { foo: 'bar', baz: 'qux' }
        )
      end

      it 'matches the Typhoeus URL request path' do
        expected = URI.parse(typhoeus_request.url).request_uri

        expect(driven_request.request_uri).to eq(expected)
      end
    end

    context 'when params are given as a string' do
      let(:request_url) { 'https://example.com/resource.xml' }
      let(:typhoeus_request) do
        Typhoeus::Request.new(
          request_url,
          method: method,
          headers: request_headers,
          params: 'foo=bar&baz=qux'
        )
      end

      it 'appends the provided query string' do
        expect(driven_request.request_uri).to eq('/resource.xml?foo=bar&baz=qux')
      end
    end

    context 'when base URL already contains a query' do
      let(:request_url) { 'https://example.com/resource.xml?existing=1' }
      let(:typhoeus_request) do
        Typhoeus::Request.new(
          request_url,
          method: method,
          headers: request_headers,
          params: { foo: 'bar' }
        )
      end

      it 'merges params with existing query string' do
        expect(driven_request.request_uri).to eq('/resource.xml?existing=1&foo=bar')
      end
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

        it 'treats it as empty string' do
          expect(driven_request.calculated_hash).to eq('47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=')
        end
      end

      context 'IO body' do
        let(:body_io) { StringIO.new("hello\nworld") }
        let(:body) { body_io }

        it 'reads the body and rewinds the stream' do
          result = driven_request.calculated_hash

          expect(result).to eq('JsYKYdAdtYNspw/v1EpqAWYgQTyO9fJZpsVhLU9507g=')
          expect(body_io.pos).to eq(0)
        end
      end

      context 'file body' do
        let(:body_file) { File.open('spec/fixtures/upload.png', 'rb') }
        let(:body) { body_file }

        after do
          body_file.close unless body_file.closed?
        end

        it 'calculates hash from the file contents and rewinds the stream' do
          expect(driven_request.calculated_hash).to eq('AlKDe7kjMQhuKgKuNG8I7GA93MasHcaVJkJLaUT7+dY=')
          expect(body_file.pos).to eq(0)
        end
      end

      context 'multipart upload body' do
        let(:upload_file) { File.open('spec/fixtures/upload.png', 'rb') }
        let(:typhoeus_request) do
          Typhoeus::Request.new(
            request_url,
            method: :put,
            headers: request_headers,
            body: { file: upload_file }
          )
        end

        after do
          upload_file.close unless upload_file.closed?
        end

        it 'uses the encoded multipart body' do
          expected = Digest::SHA256.base64digest(typhoeus_request.encoded_body)

          expect(driven_request.calculated_hash).to eq(expected)
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
    let(:request_headers) { { 'content-type' => 'text/plain' } }

    describe '#populate_content_hash' do
      context 'when request type has no body' do
        let(:method) { :get }
        let(:body) { nil }

        it "doesn't populate content hash" do
          driven_request.populate_content_hash
          expect(typhoeus_request.options[:headers]['X-Authorization-Content-SHA256']).to be_nil
        end
      end

      context 'when request type has a body' do
        let(:body) { "hello\nworld" }

        it 'populates content hash' do
          driven_request.populate_content_hash
          expect(typhoeus_request.options[:headers]['X-Authorization-Content-SHA256']).to eq('JsYKYdAdtYNspw/v1EpqAWYgQTyO9fJZpsVhLU9507g=')
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
        expect(typhoeus_request.options[:headers]['DATE']).to eq(timestamp)
      end

      it 'refreshes the cached headers' do
        driven_request.set_date
        expect(driven_request.timestamp).to eq(timestamp)
      end
    end

    describe '#set_auth_header' do
      it 'sets the auth header' do
        driven_request.set_auth_header('APIAuth 1044:54321')
        expect(typhoeus_request.options[:headers]['Authorization']).to eq('APIAuth 1044:54321')
      end
    end
  end

  describe 'content_hash_mismatch?' do
    context 'when request type has no body' do
      let(:method) { :get }
      let(:body) { nil }

      it 'is false' do
        expect(driven_request.content_hash_mismatch?).to be false
      end
    end

    context 'when request type has a body' do
      let(:method) { :put }

      context 'when calculated matches sent' do
        before do
          typhoeus_request.options[:headers]['X-Authorization-Content-SHA256'] = 'JsYKYdAdtYNspw/v1EpqAWYgQTyO9fJZpsVhLU9507g='
        end

        it 'is false' do
          expect(driven_request.content_hash_mismatch?).to be false
        end
      end

      context "when calculated doesn't match sent" do
        before do
          typhoeus_request.options[:headers]['X-Authorization-Content-SHA256'] = '3'
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
