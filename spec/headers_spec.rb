require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ApiAuth::Headers" do
  
  CANONICAL_STRING = "text/plain,e59ff97941044f85df5297e1c302d260,/resource.xml?foo=bar&bar=foo,Mon, 23 Jan 1984 03:29:56 GMT"

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
  
  end
  
  describe "with ActionController" do

    before(:each) do
      @request = ActionController::Request.new(
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
      @request = ActionController::Request.new(
        'PATH_INFO' => '/resource.xml',
        'QUERY_STRING' => 'foo=bar&bar=foo',
        'REQUEST_METHOD' => 'PUT',
        'CONTENT_MD5' => 'e59ff97941044f85df5297e1c302d260',
        'CONTENT_TYPE' => 'text/plain')
      ApiAuth.sign!(@request, "some access id", "some secret key")
      @request.headers['DATE'].should_not be_nil
    end

  end

end
