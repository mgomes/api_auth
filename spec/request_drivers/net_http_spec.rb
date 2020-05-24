require 'spec_helper'

describe ApiAuth::RequestDrivers::NetHttpRequest do
  let(:timestamp) { Time.now.utc.httpdate }

  let(:request_path) { '/resource.xml?foo=bar&bar=foo' }

  let(:request_headers) do
    {
      'Authorization' => 'APIAuth 1044:12345',
      'X-Authorization-Content-SHA256' => '47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=',
      'content-type' => 'text/plain',
      'date' => timestamp
    }
  end

  let(:request) do
    net_http_request = Net::HTTP::Put.new(request_path, request_headers)
    net_http_request.body = "hello\nworld"
    net_http_request
  end

  subject(:driven_request) { ApiAuth::RequestDrivers::NetHttpRequest.new(request) }

  describe 'getting headers correctly' do
    describe '#content_type' do
      it 'gets the content_type' do
        expect(driven_request.content_type).to eq('text/plain')
      end

      it 'gets multipart content_type' do
        request = Net::HTTP::Put::Multipart.new('/resource.xml?foo=bar&bar=foo',
                                                'file' => UploadIO.new(File.new('spec/fixtures/upload.png'), 'image/png', 'upload.png'))
        driven_request = ApiAuth::RequestDrivers::NetHttpRequest.new(request)
        expect(driven_request.content_type).to match 'multipart/form-data; boundary='
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
      it 'calculate content hash from the body' do
        expect(driven_request.calculated_hash).to eq('JsYKYdAdtYNspw/v1EpqAWYgQTyO9fJZpsVhLU9507g=')
      end

      it 'treats no body as empty string' do
        request.body = nil
        expect(driven_request.calculated_hash).to eq('47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=')
      end

      it 'calculates correctly for multipart content' do
        request.body = nil
        request.body_stream = File.new('spec/fixtures/upload.png')
        expect(driven_request.calculated_hash).to eq('AlKDe7kjMQhuKgKuNG8I7GA93MasHcaVJkJLaUT7+dY=')
      end
    end

    describe 'http_method' do
      context 'when put request' do
        let(:request) { Net::HTTP::Put.new(request_path, request_headers) }

        it 'returns upcased put' do
          expect(driven_request.http_method).to eq('PUT')
        end
      end

      context 'when get request' do
        let(:request) { Net::HTTP::Get.new(request_path, request_headers) }

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

    let(:request) do
      Net::HTTP::Put.new(request_path, request_headers)
    end

    describe '#populate_content_hash' do
      context 'when request type has no body' do
        let(:request) do
          Net::HTTP::Get.new(request_path, request_headers)
        end

        it "doesn't populate content hash" do
          driven_request.populate_content_hash
          expect(request['X-Authorization-Content-SHA256']).to be_nil
        end
      end

      context 'when request type has a body' do
        let(:request) do
          net_http_request = Net::HTTP::Put.new(request_path, request_headers)
          net_http_request.body = "hello\nworld"
          net_http_request
        end

        it 'populates content hash' do
          driven_request.populate_content_hash
          expect(request['X-Authorization-Content-SHA256']).to eq('JsYKYdAdtYNspw/v1EpqAWYgQTyO9fJZpsVhLU9507g=')
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
        expect(request['DATE']).to eq(timestamp)
      end

      it 'refreshes the cached headers' do
        driven_request.set_date
        expect(driven_request.timestamp).to eq(timestamp)
      end
    end

    describe '#set_auth_header' do
      it 'sets the auth header' do
        driven_request.set_auth_header('APIAuth 1044:54321')
        expect(request['Authorization']).to eq('APIAuth 1044:54321')
      end
    end
  end

  describe 'content_hash_mismatch?' do
    context 'when request type has no body' do
      let(:request) do
        Net::HTTP::Get.new(request_path, request_headers)
      end

      it 'is false' do
        expect(driven_request.content_hash_mismatch?).to be false
      end
    end

    context 'when request type has a body' do
      let(:request) do
        net_http_request = Net::HTTP::Put.new(request_path, request_headers)
        net_http_request.body = "hello\nworld"
        net_http_request
      end

      context 'when calculated matches sent' do
        before do
          request['X-Authorization-Content-SHA256'] = 'JsYKYdAdtYNspw/v1EpqAWYgQTyO9fJZpsVhLU9507g='
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
      expect(driven_request.fetch_headers).to include('content-type' => ['text/plain'])
    end
  end
end
