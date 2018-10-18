require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'Rails integration' do
  API_KEY_STORE = { '1044' => 'l16imAXie1sRMcJODpOG7UwC1VyoqvO13jejkfpKWX4Z09W8DC9IrU23DvCwMry7pgSFW6c5S1GIfV0OY6F/vUA==' }.freeze

  describe 'Rails controller integration' do
    class ApplicationController < ActionController::Base
      private

      def require_api_auth
        if (access_id = get_api_access_id_from_request)
          return true if api_authenticated?(API_KEY_STORE[access_id])
        end

        respond_to do |format|
          format.xml { render xml: 'You are unauthorized to perform this action.', status: 401 }
          format.json { render json: 'You are unauthorized to perform this action.', status: 401 }
          format.html { render plain: 'You are unauthorized to perform this action', status: 401 }
        end
      end
    end

    class TestController < ApplicationController
      before_action :require_api_auth, only: [:index]

      def self._routes
        ActionDispatch::Routing::RouteSet.new
      end

      def index
        render json: 'OK'
      end

      def public
        render json: 'OK'
      end

      def rescue_action(e)
        raise(e)
      end
    end

    def generated_response(request, action = :index)
      response = ActionDispatch::TestResponse.new
      controller = TestController.new
      controller.request = request
      controller.response = response
      controller.process(action)
      response
    end

    def generated_request
      request = if ActionController::TestRequest.respond_to?(:create)
                  if Gem.loaded_specs['actionpack'].version < Gem::Version.new('5.1.0')
                    ActionController::TestRequest.create
                  else
                    ActionController::TestRequest.create(TestController)
                  end
                else
                  ActionController::TestRequest.new
                end
      request.accept = ['application/json']
      request
    end

    it 'should permit a request with properly signed headers' do
      request = generated_request
      request.env['DATE'] = Time.now.utc.httpdate
      ApiAuth.sign!(request, '1044', API_KEY_STORE['1044'])
      response = generated_response(request, :index)
      expect(response.code).to eq('200')
    end

    it 'should forbid a request with properly signed headers but timestamp > 15 minutes ago' do
      request = generated_request
      request.env['DATE'] = 'Mon, 23 Jan 1984 03:29:56 GMT'
      ApiAuth.sign!(request, '1044', API_KEY_STORE['1044'])
      response = generated_response(request, :index)
      expect(response.code).to eq('401')
    end

    it 'should forbid a request with properly signed headers but timestamp > 15 minutes in the future' do
      request = generated_request
      request.env['DATE'] = 'Mon, 23 Jan 2100 03:29:56 GMT'
      ApiAuth.sign!(request, '1044', API_KEY_STORE['1044'])
      response = generated_response(request, :index)
      expect(response.code).to eq('401')
    end

    it "should insert a DATE header in the request when one hasn't been specified" do
      request = generated_request
      ApiAuth.sign!(request, '1044', API_KEY_STORE['1044'])
      expect(request.headers['DATE']).not_to be_nil
    end

    it 'should forbid an unsigned request to a protected controller action' do
      request = generated_request
      response = generated_response(request, :index)
      expect(response.code).to eq('401')
    end

    it 'should forbid a request with a bogus signature' do
      request = generated_request
      request.env['Authorization'] = 'APIAuth bogus:bogus'
      response = generated_response(request, :index)
      expect(response.code).to eq('401')
    end

    it 'should allow non-protected controller actions to function as before' do
      request = generated_request
      response = generated_response(request, :public)
      expect(response.code).to eq('200')
    end
  end

  describe 'Rails ActiveResource integration' do
    class TestResource < ActiveResource::Base
      with_api_auth '1044', API_KEY_STORE['1044']
      self.site = 'http://localhost/'
      self.format = :xml
    end

    it 'should send signed requests automagically' do
      timestamp = Time.parse('Mon, 23 Jan 1984 03:29:56 GMT')
      allow(Time).to receive(:now).at_least(1).times.and_return(timestamp)
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get '/test_resources/1.xml',
                 {
                   'Authorization' => 'APIAuth 1044:LZ1jujf3x1nnGR70/208WPXdUHw=',
                   'Accept' => 'application/xml',
                   'DATE' => 'Mon, 23 Jan 1984 03:29:56 GMT'
                 },
                 { id: '1' }.to_xml(root: 'test_resource')
      end
      expect(ApiAuth).to receive(:sign!).with(anything, '1044', API_KEY_STORE['1044'], {}).and_call_original
      TestResource.find(1)
    end
  end
end
