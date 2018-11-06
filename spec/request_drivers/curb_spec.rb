require 'spec_helper'

describe ApiAuth::RequestDrivers::CurbRequest do
  let(:timestamp) { Time.now.utc.httpdate }

  let(:request) do
    headers = {
      'Authorization' => 'APIAuth 1044:12345',
      'Content-MD5' => '1B2M2Y8AsgTpgAmY7PhCfg==',
      'Content-Type' => 'text/plain',
      'Date' => timestamp
    }
    Curl::Easy.new('/resource.xml?foo=bar&bar=foo') do |curl|
      curl.headers = headers
    end
  end

  subject(:driven_request) { ApiAuth::RequestDrivers::CurbRequest.new(request) }

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

    describe 'http_method' do
      it 'is always nil' do
        expect(driven_request.http_method).to be_nil
      end
    end
  end

  describe 'setting headers correctly' do
    let(:request) do
      headers = {
        'Content-Type' => 'text/plain'
      }
      Curl::Easy.new('/resource.xml?foo=bar&bar=foo') do |curl|
        curl.headers = headers
      end
    end

    describe '#populate_content_md5' do
      it 'is a no-op' do
        expect(driven_request.populate_content_md5).to be_nil
        expect(request.headers['Content-MD5']).to be_nil
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
    it 'is always false' do
      expect(driven_request.md5_mismatch?).to be false
    end
  end

  describe 'fetch_headers' do
    it 'returns request headers' do
      expect(driven_request.fetch_headers).to include('CONTENT-TYPE' => 'text/plain')
    end
  end
end
