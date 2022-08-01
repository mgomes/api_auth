require 'spec_helper'

describe ApiAuth::RequestDrivers::FaradayEnv do
  let(:timestamp) { Time.now.utc.httpdate }

  let(:request) do
    Faraday::Env.new(verb, body, URI(uri), {}, Faraday::Utils::Headers.new(headers))
  end

  let(:verb) { :put }
  let(:uri) { 'https://localhost/resource.xml?foo=bar&bar=foo' }
  let(:body) { "hello\nworld" }

  let(:headers) do
    {
      'Authorization' => 'APIAuth 1044:12345',
      'X-Authorization-Content-SHA256' => '47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=',
      'content-type' => 'text/plain',
      'date' => timestamp
    }
  end

  subject(:driven_request) { described_class.new(request) }

  describe 'getting headers correctly' do
    it 'gets the content_type' do
      expect(driven_request.content_type).to eq('text/plain')
    end

    context 'without Content-Type' do
      let(:headers) { {} }

      it 'defaults to url-encoded' do
        expect(driven_request.content_type).to eq 'application/x-www-form-urlencoded'
      end
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
        expect(driven_request.body.bytesize).to eq(11)
      end

      context 'no body' do
        let(:body) { nil }

        it 'treats no body as empty string' do
          expect(driven_request.calculated_hash).to eq('47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=')
          expect(driven_request.body.bytesize).to eq(0)
        end
      end

      context 'multipart content' do
        let(:body) { File.new('spec/fixtures/upload.png') }

        it 'calculates correctly for multipart content' do
          expect(driven_request.calculated_hash).to eq('AlKDe7kjMQhuKgKuNG8I7GA93MasHcaVJkJLaUT7+dY=')
          expect(driven_request.body.bytesize).to eq(5112)
        end
      end
    end

    describe 'http_method' do
      context 'when put request' do
        let(:verb) { :put }

        it 'returns upcased put' do
          expect(driven_request.http_method).to eq('PUT')
        end
      end

      context 'when get request' do
        let(:verb) { :get }

        it 'returns upcased get' do
          expect(driven_request.http_method).to eq('GET')
        end
      end
    end
  end

  describe 'setting headers correctly' do
    let(:headers) do
      {
        'content-type' => 'text/plain'
      }
    end

    describe '#populate_content_hash' do
      context 'when request type has no body' do
        let(:verb) { :get }

        it "doesn't populate content hash" do
          driven_request.populate_content_hash
          expect(request.request_headers['X-Authorization-Content-SHA256']).to be_nil
        end
      end

      context 'when request type has a body' do
        let(:verb) { :put }

        it 'populates content hash' do
          driven_request.populate_content_hash
          expect(request.request_headers['X-Authorization-Content-SHA256']).to eq('JsYKYdAdtYNspw/v1EpqAWYgQTyO9fJZpsVhLU9507g=')
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
        expect(request.request_headers['DATE']).to eq(timestamp)
      end
    end

    describe '#set_auth_header' do
      it 'sets the auth header' do
        driven_request.set_auth_header('APIAuth 1044:54321')
        expect(request.request_headers['Authorization']).to eq('APIAuth 1044:54321')
      end
    end
  end

  describe 'content_hash_mismatch?' do
    context 'when request type has no body' do
      let(:verb) { :get }

      it 'is false' do
        expect(driven_request.content_hash_mismatch?).to be false
      end
    end

    context 'when request type has a body' do
      let(:verb) { :put }

      context 'when calculated matches sent' do
        before do
          request.request_headers['X-Authorization-Content-SHA256'] = 'JsYKYdAdtYNspw/v1EpqAWYgQTyO9fJZpsVhLU9507g='
        end

        it 'is false' do
          expect(driven_request.content_hash_mismatch?).to be false
        end
      end

      context "when calculated doesn't match sent" do
        before do
          request['X-Authorization-Content-SHA256'] = '3'
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
