require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ApiAuth::Headers do

  describe '#canonical_string' do
    context "uri edge cases" do
      let(:request) { RestClient::Request.new(:url => uri, :method => :get) }
      subject(:headers) { described_class.new(request) }
      let(:uri) { '' }

      context 'empty uri' do
        let(:uri) { ''.freeze }

        it 'adds / to canonical string' do
          expect(subject.canonical_string).to eq(',,/,')
        end
      end

      context 'uri with just host without /' do
        let(:uri) { 'http://google.com'.freeze }

        it 'return / as canonical string path' do
          expect(subject.canonical_string).to eq(',,/,')
        end

        it 'does not change request url (by removing host)' do
          expect(request.url).to eq(uri)
        end
      end

      context 'uri with host and /' do
        let(:uri) { 'http://google.com/'.freeze }

        it 'return / as canonical string path' do
          expect(subject.canonical_string).to eq(',,/,')
        end

        it 'does not change request url (by removing host)' do
          expect(request.url).to eq(uri)
        end
      end
    end

    context "string construction" do
      let(:request){ RestClient::Request.new(:url => "http://google.com", :method => :get) }
      subject(:headers) { described_class.new(request) }
      let(:driver){ headers.instance_variable_get("@request")}

      it "puts the canonical string together correctly" do
        allow(driver).to receive(:content_type).and_return "text/html"
        allow(driver).to receive(:content_md5).and_return "12345"
        allow(driver).to receive(:request_uri).and_return "/foo"
        allow(driver).to receive(:timestamp).and_return "Mon, 23 Jan 1984 03:29:56 GMT"
        expect(headers.canonical_string).to eq "text/html,12345,/foo,Mon, 23 Jan 1984 03:29:56 GMT"
      end
    end
  end

  describe '#calculate_md5' do
    subject(:headers){ described_class.new(request) }
    let(:driver){ headers.instance_variable_get("@request")}

    context "no md5 already calculated" do
      let(:request) {
        RestClient::Request.new(
          :url => 'http://google.com',
          :method => :post,
          :payload => "hello\nworld"
        )
      }

      it "populates the md5 header" do
        expect(driver).to receive(:populate_content_md5)
        headers.calculate_md5
      end
    end

    context "md5 already calculated" do
      let(:request) {
        RestClient::Request.new(
          :url => 'http://google.com',
          :method => :post,
          :payload => "hello\nworld",
          :headers => {:content_md5 => "abcd"}
        )
      }

      it "doesn't populate the md5 header" do
        expect(driver).not_to receive(:populate_content_md5)
        headers.calculate_md5
      end
    end
  end

  describe "#md5_mismatch?" do
    let(:request){ RestClient::Request.new(:url => "http://google.com", :method => :get) }
    subject(:headers){ described_class.new(request) }
    let(:driver){ headers.instance_variable_get("@request") }

    context "when request has md5 header" do
      it "asks the driver" do
        allow(driver).to receive(:content_md5).and_return "1234"

        expect(driver).to receive(:md5_mismatch?).and_call_original
        headers.md5_mismatch?
      end
    end

    context "when request has no md5" do
      it "doesn't ask the driver" do
        allow(driver).to receive(:content_md5).and_return ""

        expect(driver).not_to receive(:md5_mismatch?).and_call_original
        headers.md5_mismatch?
      end

      it "returns false" do
        allow(driver).to receive(:content_md5).and_return ""

        expect(headers.md5_mismatch?).to be false
      end
    end
  end
end
