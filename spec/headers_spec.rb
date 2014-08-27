require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ApiAuth::Headers" do

  CANONICAL_STRING = "text/plain,e59ff97941044f85df5297e1c302d260,/resource.xml?foo=bar&bar=foo,Mon, 23 Jan 1984 03:29:56 GMT"

  describe "with Net::HTTP::Put::Multipart" do

    before(:each) do
      request = Net::HTTP::Put::Multipart.new("/resource.xml?foo=bar&bar=foo",
        'file' => UploadIO.new(File.new('spec/fixtures/upload.png'), 'image/png', 'upload.png'))
      ApiAuth.sign!(request, "some access id", "some secret key")
      @headers = ApiAuth::Headers.new(request)
    end

    it "should set the content-type" do
      @headers.canonical_string.split(',')[0].should match 'multipart/form-data; boundary='
    end

    it "should generate the proper content-md5" do
      @headers.canonical_string.split(',')[1].should match 'zap0d6zuh6wRBSrsvO2bcw=='
    end

  end

  describe "with Net::HTTP" do

    before(:each) do
      @request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
        'content-type' => 'text/plain',
        'content-md5' => 'e59ff97941044f85df5297e1c302d260',
        'date' => "Mon, 23 Jan 1984 03:29:56 GMT")
      @headers = ApiAuth::Headers.new(@request)
    end

    it "should generate the proper canonical string" do
      @headers.canonical_string.should == CANONICAL_STRING
    end

    it "should set the authorization header" do
      @headers.sign_header("alpha")
      @headers.authorization_header.should == "alpha"
    end

    it "should set the DATE header if one is not already present" do
      @request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
        'content-type' => 'text/plain',
        'content-md5' => 'e59ff97941044f85df5297e1c302d260')
      ApiAuth.sign!(@request, "some access id", "some secret key")
      @request['DATE'].should_not be_nil
    end

    it "should not set the DATE header just by asking for the canonical_string" do
      request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
        'content-type' => 'text/plain',
        'content-md5' => 'e59ff97941044f85df5297e1c302d260')
      headers = ApiAuth::Headers.new(request)
      headers.canonical_string
      request['DATE'].should be_nil
    end

    context "md5_mismatch?" do
      it "is false if no md5 header is present" do
        request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
        'content-type' => 'text/plain')
        headers = ApiAuth::Headers.new(request)
        headers.md5_mismatch?.should be_false
      end
    end
  end

  describe "with RestClient" do

    before(:each) do
      headers = { 'Content-MD5' => "e59ff97941044f85df5297e1c302d260",
                  'Content-Type' => "text/plain",
                  'Date' => "Mon, 23 Jan 1984 03:29:56 GMT" }
      @request = RestClient::Request.new(:url => "/resource.xml?foo=bar&bar=foo",
        :headers => headers,
        :method => :put)
      @headers = ApiAuth::Headers.new(@request)
    end

    it "should generate the proper canonical string" do
      @headers.canonical_string.should == CANONICAL_STRING
    end

    it "should set the authorization header" do
      @headers.sign_header("alpha")
      @headers.authorization_header.should == "alpha"
    end

    it "should set the DATE header if one is not already present" do
      headers = { 'Content-MD5' => "e59ff97941044f85df5297e1c302d260",
                  'Content-Type' => "text/plain" }
      @request = RestClient::Request.new(:url => "/resource.xml?foo=bar&bar=foo",
        :headers => headers,
        :method => :put)
      ApiAuth.sign!(@request, "some access id", "some secret key")
      @request.headers['DATE'].should_not be_nil
    end

    it "should not set the DATE header just by asking for the canonical_string" do
      headers = { 'Content-MD5' => "e59ff97941044f85df5297e1c302d260",
                  'Content-Type' => "text/plain" }
      request = RestClient::Request.new(:url => "/resource.xml?foo=bar&bar=foo",
        :headers => headers,
        :method => :put)
      headers = ApiAuth::Headers.new(request)
      headers.canonical_string
      request.headers['DATE'].should be_nil
    end

    it "doesn't mess up symbol based headers" do
      headers = { 'Content-MD5' => "e59ff97941044f85df5297e1c302d260",
                  :content_type => "text/plain",
                  'Date' => "Mon, 23 Jan 1984 03:29:56 GMT" }
      @request = RestClient::Request.new(:url => "/resource.xml?foo=bar&bar=foo",
        :headers => headers,
        :method => :put)
      @headers = ApiAuth::Headers.new(@request)
      ApiAuth.sign!(@request, "some access id", "some secret key")
      @request.processed_headers.should have_key('Content-Type')
    end
  end

  describe "with Curb" do

    before(:each) do
      headers = { 'Content-MD5' => "e59ff97941044f85df5297e1c302d260",
                  'Content-Type' => "text/plain",
                  'Date' => "Mon, 23 Jan 1984 03:29:56 GMT" }
      @request = Curl::Easy.new("/resource.xml?foo=bar&bar=foo") do |curl|
        curl.headers = headers
      end
      @headers = ApiAuth::Headers.new(@request)
    end

    it "should generate the proper canonical string" do
      @headers.canonical_string.should == CANONICAL_STRING
    end

    it "should set the authorization header" do
      @headers.sign_header("alpha")
      @headers.authorization_header.should == "alpha"
    end

    it "should set the DATE header if one is not already present" do
      headers = { 'Content-MD5' => "e59ff97941044f85df5297e1c302d260",
                  'Content-Type' => "text/plain" }
      @request = Curl::Easy.new("/resource.xml?foo=bar&bar=foo") do |curl|
        curl.headers = headers
      end
      ApiAuth.sign!(@request, "some access id", "some secret key")
      @request.headers['DATE'].should_not be_nil
    end

    it "should not set the DATE header just by asking for the canonical_string" do
      headers = { 'Content-MD5' => "e59ff97941044f85df5297e1c302d260",
                  'Content-Type' => "text/plain" }
      request = Curl::Easy.new("/resource.xml?foo=bar&bar=foo") do |curl|
        curl.headers = headers
      end
      headers = ApiAuth::Headers.new(request)
      headers.canonical_string
      request.headers['DATE'].should be_nil
    end
  end

  describe "with ActionController" do

    let(:request_klass){ ActionDispatch::Request rescue ActionController::Request }

    before(:each) do
      @request = request_klass.new(
        'PATH_INFO' => '/resource.xml',
        'QUERY_STRING' => 'foo=bar&bar=foo',
        'REQUEST_METHOD' => 'PUT',
        'CONTENT_MD5' => 'e59ff97941044f85df5297e1c302d260',
        'CONTENT_TYPE' => 'text/plain',
        'HTTP_DATE' => 'Mon, 23 Jan 1984 03:29:56 GMT')
      @headers = ApiAuth::Headers.new(@request)
    end

    it "should generate the proper canonical string" do
      @headers.canonical_string.should == CANONICAL_STRING
    end

    it "should set the authorization header" do
      @headers.sign_header("alpha")
      @headers.authorization_header.should == "alpha"
    end

    it "should set the DATE header if one is not already present" do
      @request = request_klass.new(
        'PATH_INFO' => '/resource.xml',
        'QUERY_STRING' => 'foo=bar&bar=foo',
        'REQUEST_METHOD' => 'PUT',
        'CONTENT_MD5' => 'e59ff97941044f85df5297e1c302d260',
        'CONTENT_TYPE' => 'text/plain')
      ApiAuth.sign!(@request, "some access id", "some secret key")
      @request.headers['DATE'].should_not be_nil
    end

    it "should not set the DATE header just by asking for the canonical_string" do
      request = request_klass.new(
        'PATH_INFO' => '/resource.xml',
        'QUERY_STRING' => 'foo=bar&bar=foo',
        'REQUEST_METHOD' => 'PUT',
        'CONTENT_MD5' => 'e59ff97941044f85df5297e1c302d260',
        'CONTENT_TYPE' => 'text/plain')
      headers = ApiAuth::Headers.new(request)
      headers.canonical_string
      request.headers['DATE'].should be_nil
    end
  end

  describe "with Rack::Request" do

    before(:each) do
      headers = { 'Content-MD5' => "e59ff97941044f85df5297e1c302d260",
                  'Content-Type' => "text/plain",
                  'Date' => "Mon, 23 Jan 1984 03:29:56 GMT"
                  }
      @request = Rack::Request.new(Rack::MockRequest.env_for("/resource.xml?foo=bar&bar=foo", :method => :put).merge!(headers))
      @headers = ApiAuth::Headers.new(@request)
    end

    it "should generate the proper canonical string" do
      @headers.canonical_string.should == CANONICAL_STRING
    end

    it "should set the authorization header" do
      @headers.sign_header("alpha")
      @headers.authorization_header.should == "alpha"
    end

    it "should set the DATE header if one is not already present" do
      headers = { 'Content-MD5' => "e59ff97941044f85df5297e1c302d260",
                  'Content-Type' => "text/plain" }
      @request = Rack::Request.new(Rack::MockRequest.env_for("/resource.xml?foo=bar&bar=foo", :method => :put).merge!(headers))
      ApiAuth.sign!(@request, "some access id", "some secret key")
      @request.env['DATE'].should_not be_nil
    end

    it "should not set the DATE header just by asking for the canonical_string" do
      headers = { 'Content-MD5' => "e59ff97941044f85df5297e1c302d260",
                  'Content-Type' => "text/plain" }
      request = Rack::Request.new(Rack::MockRequest.env_for("/resource.xml?foo=bar&bar=foo", :method => :put).merge!(headers))
      headers = ApiAuth::Headers.new(request)
      headers.canonical_string
      request.env['DATE'].should be_nil
    end
  end

  describe "with HTTPI" do
     before(:each) do
       @request = HTTPI::Request.new("http://localhost/resource.xml?foo=bar&bar=foo")
       @request.headers.merge!({
         'content-type' => 'text/plain',
         'content-md5'  => 'e59ff97941044f85df5297e1c302d260',
         'date'         => "Mon, 23 Jan 1984 03:29:56 GMT"
       })
       @headers = ApiAuth::Headers.new(@request)
     end

     it "should generate the proper canonical string" do
       @headers.canonical_string.should == CANONICAL_STRING
     end

     it "should set the authorization header" do
       @headers.sign_header("alpha")
       @headers.authorization_header.should == "alpha"
     end

     it "should set the DATE header if one is not already present" do
       @request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
         'content-type' => 'text/plain',
         'content-md5' => 'e59ff97941044f85df5297e1c302d260')
       ApiAuth.sign!(@request, "some access id", "some secret key")
       @request['DATE'].should_not be_nil
     end

     it "should not set the DATE header just by asking for the canonical_string" do
       request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
         'content-type' => 'text/plain',
         'content-md5' => 'e59ff97941044f85df5297e1c302d260')
       headers = ApiAuth::Headers.new(request)
       headers.canonical_string
       request['DATE'].should be_nil
     end

     context "md5_mismatch?" do
       it "is false if no md5 header is present" do
         request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
         'content-type' => 'text/plain')
         headers = ApiAuth::Headers.new(request)
         headers.md5_mismatch?.should be_false
       end
     end
   end

end
