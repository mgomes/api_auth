require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'ApiAuth::Helpers' do
  it 'should strip the new line character on a Base64 encoding' do
    expect(ApiAuth.b64_encode('some string')).not_to match(/\n/)
  end

  it "should properly upcase a hash's keys" do
    hsh = { 'JoE' => 'rOOLz' }
    expect(ApiAuth.capitalize_keys(hsh)['JOE']).to eq('rOOLz')
  end
end
