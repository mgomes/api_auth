require 'spec_helper'

describe ApiAuth::RequestDrivers::GrapeRequest do
  let(:default_method) { 'PUT' }
  let(:default_params) do
    { 'message' => "hello\nworld" }
  end
  let(:default_options) do
    {
      method: method,
      params: params
    }
  end
  let(:default_env) do
    Rack::MockRequest.env_for('/', options)
  end
  let(:method) { default_method }
  let(:params) { default_params }
  let(:options) { default_options.merge(request_headers) }
  let(:env) { default_env }

  let(:request) do
    Grape::Request.new(env)
  end

  let(:timestamp) { Time.now.utc.httpdate }
  let(:request_headers) do
    {
      'HTTP_X_HMAC_AUTHORIZATION' => 'APIAuth 1044:12345',
      'HTTP_X_HMAC_CONTENT_MD5' => 'WEqCyXEuRBYZbohpZmUyAw==',
      'HTTP_X_HMAC_CONTENT_TYPE' => 'text/plain',
      'HTTP_X_HMAC_DATE' => timestamp
    }
  end

  subject(:driven_request) { ApiAuth::RequestDrivers::GrapeRequest.new(request) }

  describe 'getting headers correctly' do
    it 'gets the content_type' do
      expect(driven_request.content_type).to eq('text/plain')
    end

    it 'gets the content_md5' do
      expect(driven_request.content_md5).to eq('WEqCyXEuRBYZbohpZmUyAw==')
    end

    it 'gets the request_uri' do
      expect(driven_request.request_uri).to eq('http://example.org/')
    end

    it 'gets the timestamp' do
      expect(driven_request.timestamp).to eq(timestamp)
    end

    it 'gets the authorization_header' do
      expect(driven_request.authorization_header).to eq('APIAuth 1044:12345')
    end

    describe '#calculated_md5' do
      it 'calculates md5 from the body' do
        expect(driven_request.calculated_md5).to eq('WEqCyXEuRBYZbohpZmUyAw==')
      end

      context 'no body' do
        let(:params) { {} }

        it 'treats no body as empty string' do
          expect(driven_request.calculated_md5).to eq('1B2M2Y8AsgTpgAmY7PhCfg==')
        end
      end
    end

    describe 'http_method' do
      context 'when put request' do
        let(:method) { 'put' }

        it 'returns upcased put' do
          expect(driven_request.http_method).to eq('PUT')
        end
      end

      context 'when get request' do
        let(:method) { 'get' }

        it 'returns upcased get' do
          expect(driven_request.http_method).to eq('GET')
        end
      end
    end
  end

  describe 'setting headers correctly' do
    let(:request_headers) do
      {
        'HTTP_X_HMAC_CONTENT_TYPE' => 'text/plain'
      }
    end

    describe '#populate_content_md5' do
      context 'when getting' do
        let(:method) { 'get' }

        it "doesn't populate content-md5" do
          driven_request.populate_content_md5
          expect(request.headers['Content-Md5']).to be_nil
        end
      end

      context 'when posting' do
        let(:method) { 'post' }

        it 'populates content-md5' do
          driven_request.populate_content_md5
          expect(request.headers['Content-Md5']).to eq('WEqCyXEuRBYZbohpZmUyAw==')
        end

        it 'refreshes the cached headers' do
          driven_request.populate_content_md5
          expect(driven_request.content_md5).to eq('WEqCyXEuRBYZbohpZmUyAw==')
        end
      end

      context 'when putting' do
        let(:method) { 'put' }

        it 'populates content-md5' do
          driven_request.populate_content_md5
          expect(request.headers['Content-Md5']).to eq('WEqCyXEuRBYZbohpZmUyAw==')
        end

        it 'refreshes the cached headers' do
          driven_request.populate_content_md5
          expect(driven_request.content_md5).to eq('WEqCyXEuRBYZbohpZmUyAw==')
        end
      end

      context 'when deleting' do
        let(:method) { 'delete' }

        it "doesn't populate content-md5" do
          driven_request.populate_content_md5
          expect(request.headers['Content-Md5']).to be_nil
        end
      end
    end

    describe '#set_date' do
      before do
        allow(Time).to receive_message_chain(:now, :utc, :httpdate).and_return(timestamp)
      end

      it 'sets the date header of the request' do
        allow(Time).to receive_message_chain(:now, :utc, :httpdate).and_return(timestamp)
        driven_request.set_date
        expect(request.headers['Date']).to eq(timestamp)
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
      let(:method) { 'get' }

      it 'is false' do
        expect(driven_request.md5_mismatch?).to be false
      end
    end

    context 'when posting' do
      let(:method) { 'post' }

      context 'when calculated matches sent' do
        it 'is false' do
          expect(driven_request.md5_mismatch?).to be false
        end
      end

      context "when calculated doesn't match sent" do
        let(:params) { { 'message' => 'hello only' } }

        it 'is true' do
          expect(driven_request.md5_mismatch?).to be true
        end
      end
    end

    context 'when putting' do
      let(:method) { 'put' }

      context 'when calculated matches sent' do
        it 'is false' do
          expect(driven_request.md5_mismatch?).to be false
        end
      end

      context "when calculated doesn't match sent" do
        let(:params) { { 'message' => 'hello only' } }
        it 'is true' do
          expect(driven_request.md5_mismatch?).to be true
        end
      end
    end

    context 'when deleting' do
      let(:method) { 'delete' }

      it 'is false' do
        expect(driven_request.md5_mismatch?).to be false
      end
    end
  end

  describe 'authentics?' do
    let(:request_headers) { {} }
    let(:signed_request) do
      ApiAuth.sign!(request, '1044', '123')
    end

    context 'when getting' do
      let(:method) { 'get' }

      it 'validates that the signature in the request header matches the way we sign it' do
        expect(ApiAuth.authentic?(signed_request, '123')).to eq true
      end
    end

    context 'when posting' do
      let(:method) { 'post' }

      it 'validates that the signature in the request header matches the way we sign it' do
        expect(ApiAuth.authentic?(signed_request, '123')).to eq true
      end
    end

    context 'when putting' do
      let(:method) { 'put' }

      let(:signed_request) do
        ApiAuth.sign!(request, '1044', '123')
      end

      it 'validates that the signature in the request header matches the way we sign it' do
        expect(ApiAuth.authentic?(signed_request, '123')).to eq true
      end
    end

    context 'when deleting' do
      let(:method) { 'delete' }

      let(:signed_request) do
        ApiAuth.sign!(request, '1044', '123')
      end

      it 'validates that the signature in the request header matches the way we sign it' do
        expect(ApiAuth.authentic?(signed_request, '123')).to eq true
      end
    end
  end

  describe 'fetch_headers' do
    it 'returns request headers' do
      expect(driven_request.fetch_headers).to include(
        'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
      )
    end
  end
end
