require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ApiAuth" do

  describe "generating secret keys" do

    it "should generate secret keys" do
      ApiAuth.generate_secret_key
    end

    it "should generate secret keys that are 89 characters" do
      ApiAuth.generate_secret_key.size.should be(89)
    end

    it "should generate keys that have a Hamming Distance of at least 65" do
      key1 = ApiAuth.generate_secret_key
      key2 = ApiAuth.generate_secret_key
      Amatch::Hamming.new(key1).match(key2).should be > 65
    end

  end

  describe "signing requests" do

    def hmac(secret_key, request)
      canonical_string = ApiAuth::Headers.new(request).canonical_string
      digest = OpenSSL::Digest::Digest.new('sha1')
      ApiAuth.b64_encode(OpenSSL::HMAC.digest(digest, secret_key, canonical_string))
    end

    before(:all) do
      @access_id = "1044"
      @secret_key = ApiAuth.generate_secret_key
    end

    describe "with Net::HTTP" do

      before(:each) do
        @request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
          'content-type' => 'text/plain',
          'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg==',
          'date' => Time.now.utc.httpdate)
        @signed_request = ApiAuth.sign!(@request, @access_id, @secret_key)
      end

      it "should return a Net::HTTP object after signing it" do
        ApiAuth.sign!(@request, @access_id, @secret_key).class.to_s.should match("Net::HTTP")
      end

      describe "md5 header" do
        context "not already provided" do
          it "should calculate for empty string" do
            request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
              'content-type' => 'text/plain',
              'date' => "Mon, 23 Jan 1984 03:29:56 GMT")
            signed_request = ApiAuth.sign!(request, @access_id, @secret_key)
            signed_request['Content-MD5'].should == Digest::MD5.base64digest('')
          end

          it "should calculate for real content" do
            request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
              'content-type' => 'text/plain',
              'date' => "Mon, 23 Jan 1984 03:29:56 GMT")
            request.body = "hello\nworld"
            signed_request = ApiAuth.sign!(request, @access_id, @secret_key)
            signed_request['Content-MD5'].should == Digest::MD5.base64digest("hello\nworld")
          end
        end

        it "should leave the content-md5 alone if provided" do
          @signed_request['Content-MD5'].should == '1B2M2Y8AsgTpgAmY7PhCfg=='
        end
      end

      it "should sign the request" do
        @signed_request['Authorization'].should == "APIAuth 1044:#{hmac(@secret_key, @request)}"
      end

      it "should authenticate a valid request" do
        ApiAuth.authentic?(@signed_request, @secret_key).should be_true
      end

      it "should NOT authenticate a non-valid request" do
        ApiAuth.authentic?(@signed_request, @secret_key+'j').should be_false
      end

      it "should NOT authenticate a mismatched content-md5 when body has changed" do
        request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
          'content-type' => 'text/plain',
          'date' => "Mon, 23 Jan 1984 03:29:56 GMT")
        request.body = "hello\nworld"
        signed_request = ApiAuth.sign!(request, @access_id, @secret_key)
        signed_request.body = "goodbye"
        ApiAuth.authentic?(signed_request, @secret_key).should be_false
      end

      it "should NOT authenticate an expired request" do
        @request['Date'] = 16.minutes.ago.utc.httpdate
        signed_request = ApiAuth.sign!(@request, @access_id, @secret_key)
        ApiAuth.authentic?(signed_request, @secret_key).should be_false
      end

      it "should retrieve the access_id" do
        ApiAuth.access_id(@signed_request).should == "1044"
      end

    end

    describe "with RestClient" do

      before(:each) do
        headers = { 'Content-MD5' => "1B2M2Y8AsgTpgAmY7PhCfg==",
                    'Content-Type' => "text/plain",
                    'Date' => Time.now.utc.httpdate }
        @request = RestClient::Request.new(:url => "/resource.xml?foo=bar&bar=foo",
          :headers => headers,
          :method => :put)
        @signed_request = ApiAuth.sign!(@request, @access_id, @secret_key)
      end

      it "should return a RestClient object after signing it" do
        ApiAuth.sign!(@request, @access_id, @secret_key).class.to_s.should match("RestClient")
      end

      describe "md5 header" do
        context "not already provided" do
          it "should calculate for empty string" do
            headers = { 'Content-Type' => "text/plain",
                        'Date' => "Mon, 23 Jan 1984 03:29:56 GMT" }
            request = RestClient::Request.new(:url => "/resource.xml?foo=bar&bar=foo",
              :headers => headers,
              :method => :put)
            signed_request = ApiAuth.sign!(request, @access_id, @secret_key)
            signed_request.headers['Content-MD5'].should == Digest::MD5.base64digest('')
          end

          it "should calculate for real content" do
            headers = { 'Content-Type' => "text/plain",
                        'Date' => "Mon, 23 Jan 1984 03:29:56 GMT" }
            request = RestClient::Request.new(:url => "/resource.xml?foo=bar&bar=foo",
              :headers => headers,
              :method => :put,
              :payload => "hellow\nworld")
            signed_request = ApiAuth.sign!(request, @access_id, @secret_key)
            signed_request.headers['Content-MD5'].should == Digest::MD5.base64digest("hellow\nworld")
          end
        end

        it "should leave the content-md5 alone if provided" do
          @signed_request.headers['Content-MD5'].should == "1B2M2Y8AsgTpgAmY7PhCfg=="
        end
      end

      it "should sign the request" do
        @signed_request.headers['Authorization'].should == "APIAuth 1044:#{hmac(@secret_key, @request)}"
      end

      it "should authenticate a valid request" do
        ApiAuth.authentic?(@signed_request, @secret_key).should be_true
      end

      it "should NOT authenticate a non-valid request" do
        ApiAuth.authentic?(@signed_request, @secret_key+'j').should be_false
      end

      it "should NOT authenticate a mismatched content-md5 when body has changed" do
        headers = { 'Content-Type' => "text/plain",
                    'Date' => "Mon, 23 Jan 1984 03:29:56 GMT" }
        request = RestClient::Request.new(:url => "/resource.xml?foo=bar&bar=foo",
          :headers => headers,
          :method => :put,
          :payload => "hello\nworld")
        signed_request = ApiAuth.sign!(request, @access_id, @secret_key)
        signed_request.instance_variable_set("@payload", RestClient::Payload.generate('goodbye'))
        ApiAuth.authentic?(signed_request, @secret_key).should be_false
      end

      it "should NOT authenticate an expired request" do
        @request.headers['Date'] = 16.minutes.ago.utc.httpdate
        signed_request = ApiAuth.sign!(@request, @access_id, @secret_key)
        ApiAuth.authentic?(signed_request, @secret_key).should be_false
      end

      it "should retrieve the access_id" do
        ApiAuth.access_id(@signed_request).should == "1044"
      end

    end

    describe "with Curb" do

      before(:each) do
        headers = { 'Content-MD5' => "e59ff97941044f85df5297e1c302d260",
                    'Content-Type' => "text/plain",
                    'Date' => Time.now.utc.httpdate }
        @request = Curl::Easy.new("/resource.xml?foo=bar&bar=foo") do |curl|
          curl.headers = headers
        end
        @signed_request = ApiAuth.sign!(@request, @access_id, @secret_key)
      end

      it "should return a Curl::Easy object after signing it" do
        ApiAuth.sign!(@request, @access_id, @secret_key).class.to_s.should match("Curl::Easy")
      end

      describe "md5 header" do
        it "should not calculate and add the content-md5 header if not provided" do
          headers = { 'Content-Type' => "text/plain",
                      'Date' => "Mon, 23 Jan 1984 03:29:56 GMT" }
          request = Curl::Easy.new("/resource.xml?foo=bar&bar=foo") do |curl|
            curl.headers = headers
          end
          signed_request = ApiAuth.sign!(request, @access_id, @secret_key)
          signed_request.headers['Content-MD5'].should == nil
        end

        it "should leave the content-md5 alone if provided" do
          @signed_request.headers['Content-MD5'].should == "e59ff97941044f85df5297e1c302d260"
        end
      end

      it "should sign the request" do
        @signed_request.headers['Authorization'].should == "APIAuth 1044:#{hmac(@secret_key, @request)}"
      end

      it "should authenticate a valid request" do
        ApiAuth.authentic?(@signed_request, @secret_key).should be_true
      end

      it "should NOT authenticate a non-valid request" do
        ApiAuth.authentic?(@signed_request, @secret_key+'j').should be_false
      end

      it "should NOT authenticate an expired request" do
        @request.headers['Date'] = 16.minutes.ago.utc.httpdate
        signed_request = ApiAuth.sign!(@request, @access_id, @secret_key)
        ApiAuth.authentic?(signed_request, @secret_key).should be_false
      end

      it "should retrieve the access_id" do
        ApiAuth.access_id(@signed_request).should == "1044"
      end

    end

    describe "with ActionController" do

      before(:each) do
        @request = ActionController::Request.new(
          'PATH_INFO' => '/resource.xml',
          'QUERY_STRING' => 'foo=bar&bar=foo',
          'REQUEST_METHOD' => 'PUT',
          'CONTENT_MD5' => '1B2M2Y8AsgTpgAmY7PhCfg==',
          'CONTENT_TYPE' => 'text/plain',
          'HTTP_DATE' => Time.now.utc.httpdate)
        @signed_request = ApiAuth.sign!(@request, @access_id, @secret_key)
      end

      it "should return a ActionController::Request object after signing it" do
        ApiAuth.sign!(@request, @access_id, @secret_key).class.to_s.should match("ActionController::Request")
      end

      describe "md5 header" do
        context "not already provided" do
          it "should calculate for empty string" do
            request = ActionController::Request.new(
              'PATH_INFO' => '/resource.xml',
              'QUERY_STRING' => 'foo=bar&bar=foo',
              'REQUEST_METHOD' => 'PUT',
              'CONTENT_TYPE' => 'text/plain',
              'HTTP_DATE' => 'Mon, 23 Jan 1984 03:29:56 GMT')
            signed_request = ApiAuth.sign!(request, @access_id, @secret_key)
            signed_request.env['Content-MD5'].should == Digest::MD5.base64digest('')
          end

          it "should calculate for real content" do
            request = ActionController::Request.new(
              'PATH_INFO' => '/resource.xml',
              'QUERY_STRING' => 'foo=bar&bar=foo',
              'REQUEST_METHOD' => 'PUT',
              'CONTENT_TYPE' => 'text/plain',
              'HTTP_DATE' => 'Mon, 23 Jan 1984 03:29:56 GMT',
              'rack.input' => StringIO.new("hello\nworld"))
            signed_request = ApiAuth.sign!(request, @access_id, @secret_key)
            signed_request.env['Content-MD5'].should == Digest::MD5.base64digest("hello\nworld")
          end

        end

        it "should leave the content-md5 alone if provided" do
          @signed_request.env['CONTENT_MD5'].should == '1B2M2Y8AsgTpgAmY7PhCfg=='
        end
      end

      it "should sign the request" do
        @signed_request.env['Authorization'].should == "APIAuth 1044:#{hmac(@secret_key, @request)}"
      end

      it "should authenticate a valid request" do
        ApiAuth.authentic?(@signed_request, @secret_key).should be_true
      end

      it "should NOT authenticate a non-valid request" do
        ApiAuth.authentic?(@signed_request, @secret_key+'j').should be_false
      end

      it "should NOT authenticate a mismatched content-md5 when body has changed" do
        request = ActionController::Request.new(
          'PATH_INFO' => '/resource.xml',
          'QUERY_STRING' => 'foo=bar&bar=foo',
          'REQUEST_METHOD' => 'PUT',
          'CONTENT_TYPE' => 'text/plain',
          'HTTP_DATE' => 'Mon, 23 Jan 1984 03:29:56 GMT',
          'rack.input' => StringIO.new("hello\nworld"))
        signed_request = ApiAuth.sign!(request, @access_id, @secret_key)
        signed_request.instance_variable_get("@env")["rack.input"] = StringIO.new("goodbye")
        ApiAuth.authentic?(signed_request, @secret_key).should be_false
      end

      it "should NOT authenticate an expired request" do
        @request.env['HTTP_DATE'] = 16.minutes.ago.utc.httpdate
        signed_request = ApiAuth.sign!(@request, @access_id, @secret_key)
        ApiAuth.authentic?(signed_request, @secret_key).should be_false
      end

      it "should retrieve the access_id" do
        ApiAuth.access_id(@signed_request).should == "1044"
      end

    end

    describe "with HTTPI" do

      before(:each) do
        @request = HTTPI::Request.new("http://localhost/resource.xml?foo=bar&bar=foo")
        @request.headers.merge!({
          'content-type' => 'text/plain',
          'content-md5'  => '1B2M2Y8AsgTpgAmY7PhCfg==',
          'date'         => Time.now.utc.httpdate
        })
        @headers = ApiAuth::Headers.new(@request)
        @signed_request = ApiAuth.sign!(@request, @access_id, @secret_key)
      end

      it "should return a HTTPI object after signing it" do
        ApiAuth.sign!(@request, @access_id, @secret_key).class.to_s.should match("HTTPI::Request")
      end

      describe "md5 header" do
        context "not already provided" do
          it "should calculate for empty string" do
            request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
              'content-type' => 'text/plain',
              'date' => "Mon, 23 Jan 1984 03:29:56 GMT")
            signed_request = ApiAuth.sign!(request, @access_id, @secret_key)
            signed_request['Content-MD5'].should == Digest::MD5.base64digest('')
          end

          it "should calculate for real content" do
            request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
              'content-type' => 'text/plain',
              'date' => "Mon, 23 Jan 1984 03:29:56 GMT")
            request.body = "hello\nworld"
            signed_request = ApiAuth.sign!(request, @access_id, @secret_key)
            signed_request['Content-MD5'].should == Digest::MD5.base64digest("hello\nworld")
          end
        end

        it "should leave the content-md5 alone if provided" do
          @signed_request.headers['Content-MD5'].should == '1B2M2Y8AsgTpgAmY7PhCfg=='
        end
      end

      it "should sign the request" do
        @signed_request.headers['Authorization'].should == "APIAuth 1044:#{hmac(@secret_key, @request)}"
      end

      it "should authenticate a valid request" do
        ApiAuth.authentic?(@signed_request, @secret_key).should be_true
      end

      it "should NOT authenticate a non-valid request" do
        ApiAuth.authentic?(@signed_request, @secret_key+'j').should be_false
      end

      it "should NOT authenticate a mismatched content-md5 when body has changed" do
        request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
          'content-type' => 'text/plain',
          'date' => "Mon, 23 Jan 1984 03:29:56 GMT")
        request.body = "hello\nworld"
        signed_request = ApiAuth.sign!(request, @access_id, @secret_key)
        signed_request.body = "goodbye"
        ApiAuth.authentic?(signed_request, @secret_key).should be_false
      end

      it "should NOT authenticate an expired request" do
        @request.headers['Date'] = 16.minutes.ago.utc.httpdate
        signed_request = ApiAuth.sign!(@request, @access_id, @secret_key)
        ApiAuth.authentic?(signed_request, @secret_key).should be_false
      end

      it "should retrieve the access_id" do
        ApiAuth.access_id(@signed_request).should == "1044"
      end

    end

  end

end
