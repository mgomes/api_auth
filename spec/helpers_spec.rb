require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ApiAuth::Helpers" do

  it "should strip the new line character on a Base64 encoding" do
    ApiAuth.b64_encode("some string").should_not match(/\n/)
  end

  it "should properly upcase a hash's keys" do
    hsh = { "JoE" => "rOOLz" }
    ApiAuth.capitalize_keys(hsh)["JOE"].should == "rOOLz"
  end

  it 'should prefere X_HMAC_DATE header over DATE header' do
    request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
      'content-type' => 'text/plain',
      'content-md5' => 'e59ff97941044f85df5297e1c302d260',
      'date' => "Wed, 20 Jan 1900 10:40:56 GMT",
      'x_hmac_date' => "Mon, 23 Jan 1984 03:29:56 GMT")
    headers = ApiAuth::Headers.new(request)
    headers.canonical_string == CANONICAL_STRING
  end

  it 'should prefere X_HMAC_CONTENT_MD5 header over CONTENT_MD5 header' do
    request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
      'content-type' => 'text/plain',
      'content-md5' => '12323112312asdasdqweqweqwe',
      'x_hmac_content-md5' => 'e59ff97941044f85df5297e1c302d260',
      'date' => "Wed, 20 Jan 1900 10:40:56 GMT",
      'x_hmac_date' => "Mon, 23 Jan 1984 03:29:56 GMT")
    headers = ApiAuth::Headers.new(request)
    headers.canonical_string == CANONICAL_STRING
  end

  it 'should prefere X_HMAC_CONTENT_TYPE header over CONTENT_TYPE header' do
    request = Net::HTTP::Put.new("/resource.xml?foo=bar&bar=foo",
      'content-type' => 'application/json',
      'x_hmac_content_type'=> 'text/plain',
      'content-md5' => 'e59ff97941044f85df5297e1c302d260',
      'date' => "Wed, 20 Jan 1900 10:40:56 GMT",
      'x_hmac_date' => "Mon, 23 Jan 1984 03:29:56 GMT")
    headers = ApiAuth::Headers.new(request)
    headers.canonical_string == CANONICAL_STRING
  end


end
