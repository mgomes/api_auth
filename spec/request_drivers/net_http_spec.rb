require 'spec_helper'

describe ApiAuth::RequestDrivers::NetHttpRequest do

  let(:timestamp){ Time.now.utc.httpdate }

  let(:request_path){ "/resource.xml?foo=bar&bar=foo" }

  let(:request_headers){
    {
      'Authorization'  => 'APIAuth 1044:12345',
      'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg==',
      'content-type' => 'text/plain',
      'date' => timestamp
    }
  }

  let(:request) do
    net_http_request = Net::HTTP::Put.new(request_path, request_headers)
    net_http_request.body = "hello\nworld"
    net_http_request
  end

  subject(:driven_request){ ApiAuth::RequestDrivers::NetHttpRequest.new(request) }

  describe "getting headers correctly" do
    it "gets the content_type" do
      expect(driven_request.content_type).to eq('text/plain')
    end

    it "gets the content_md5" do
      expect(driven_request.content_md5).to eq('1B2M2Y8AsgTpgAmY7PhCfg==')
    end

    it "gets the request_uri" do
      expect(driven_request.request_uri).to eq('/resource.xml?foo=bar&bar=foo')
    end

    it "gets the timestamp" do
      expect(driven_request.timestamp).to eq(timestamp)
    end

    it "gets the authorization_header" do
      expect(driven_request.authorization_header).to eq('APIAuth 1044:12345')
    end

    it "calculates md5 from the body" do
      expect(driven_request.calculated_md5).to eq('kZXQvrKoieG+Be1rsZVINw==')
    end
  end

  describe "setting headers correctly" do
    let(:request_headers){
      {
        'content-type' => 'text/plain'
      }
    }

    let(:request) do
      Net::HTTP::Put.new(request_path, request_headers)
    end

    describe "#populate_content_md5" do
      context "when request type has no body" do
        let(:request) do
          Net::HTTP::Get.new(request_path, request_headers)
        end

        it "doesn't populate content-md5" do
          driven_request.populate_content_md5
          expect(request["Content-MD5"]).to be_nil
        end
      end

      context "when request type has a body" do
        let(:request) do
          net_http_request = Net::HTTP::Put.new(request_path, request_headers)
          net_http_request.body = "hello\nworld"
          net_http_request
        end

        it "populates content-md5" do
          driven_request.populate_content_md5
          expect(request["Content-MD5"]).to eq('kZXQvrKoieG+Be1rsZVINw==')
        end
      end
    end

    describe "#set_date" do
      it "sets the date" do
        allow(Time).to receive_message_chain(:now, :utc, :httpdate).and_return(timestamp)
        driven_request.set_date
        expect(request['DATE']).to eq(timestamp)
      end
    end

    describe "#set_auth_header" do
      it "sets the auth header" do
        driven_request.set_auth_header('APIAuth 1044:54321')
        expect(request['Authorization']).to eq('APIAuth 1044:54321')
      end
    end
  end

  describe "md5_mismatch?" do
    context "when request type has no body" do
      let(:request) do
        Net::HTTP::Get.new(request_path, request_headers)
      end


      it "is false" do
        expect(driven_request.md5_mismatch?).to be false
      end
    end

    context "when request type has a body" do
      let(:request) do
        net_http_request = Net::HTTP::Put.new(request_path, request_headers)
        net_http_request.body = "hello\nworld"
        net_http_request
      end

      context "when calculated matches sent" do
        before do
          request["Content-MD5"] = 'kZXQvrKoieG+Be1rsZVINw=='
        end

        it "is false" do
          expect(driven_request.md5_mismatch?).to be false
        end
      end

      context "when calculated doesn't match sent" do
        before do
          request["Content-MD5"] = "3"
        end

        it "is true" do
          expect(driven_request.md5_mismatch?).to be true
        end
      end
    end
  end
end
