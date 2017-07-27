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

      if defined?(ActionDispatch)
        def self._routes
          ActionDispatch::Routing::RouteSet.new
        end
      end

      def index
        render plain: 'OK'
      end

      def public
        render plain: 'OK'
      end

      def rescue_action(e)
        raise(e)
      end
    end

    unless defined?(ActionDispatch)
      ActionController::Routing::Routes.draw { |map| map.resources :test }
    end

    def generated_response(request, action = :index)
      if defined?(ActionDispatch)
        response = ActionDispatch::TestResponse.new
        controller = TestController.new
        controller.request = request
        controller.response = response
        controller.process(action)
        response
      else
        request.action = action.to_s
        request.path = "/#{action}"
        TestController.new.process(request, ActionController::TestResponse.new)
      end
    end

    it 'should permit a request with properly signed headers' do
      request = if ActionController::TestRequest.respond_to?(:create)
                  ActionController::TestRequest.create(ApplicationController)
                else
                  ActionController::TestRequest.new
                end
      request.env['DATE'] = Time.now.utc.httpdate
      ApiAuth.sign!(request, '1044', API_KEY_STORE['1044'])
      response = generated_response(request, :index)
      expect(response.code).to eq('200')
    end

    it 'should forbid a request with properly signed headers but timestamp > 15 minutes ago' do
      request = if ActionController::TestRequest.respond_to?(:create)
                  ActionController::TestRequest.create(ApplicationController)
                else
                  ActionController::TestRequest.new
                end
      request.env['DATE'] = 'Mon, 23 Jan 1984 03:29:56 GMT'
      ApiAuth.sign!(request, '1044', API_KEY_STORE['1044'])
      response = generated_response(request, :index)
      expect(response.code).to eq('401')
    end

    it 'should forbid a request with properly signed headers but timestamp > 15 minutes in the future' do
      request = if ActionController::TestRequest.respond_to?(:create)
                  ActionController::TestRequest.create(ApplicationController)
                else
                  ActionController::TestRequest.new
                end
      request.env['DATE'] = 'Mon, 23 Jan 2100 03:29:56 GMT'
      ApiAuth.sign!(request, '1044', API_KEY_STORE['1044'])
      response = generated_response(request, :index)
      expect(response.code).to eq('401')
    end

    it "should insert a DATE header in the request when one hasn't been specified" do
      request = if ActionController::TestRequest.respond_to?(:create)
                  ActionController::TestRequest.create(ApplicationController)
                else
                  ActionController::TestRequest.new
                end
      ApiAuth.sign!(request, '1044', API_KEY_STORE['1044'])
      expect(request.headers['DATE']).not_to be_nil
    end

    it 'should forbid an unsigned request to a protected controller action' do
      request = if ActionController::TestRequest.respond_to?(:create)
                  ActionController::TestRequest.create(ApplicationController)
                else
                  ActionController::TestRequest.new
                end
      response = generated_response(request, :index)
      expect(response.code).to eq('401')
    end

    it 'should forbid a request with a bogus signature' do
      request = if ActionController::TestRequest.respond_to?(:create)
                  ActionController::TestRequest.create(ApplicationController)
                else
                  ActionController::TestRequest.new
                end
      request.env['Authorization'] = 'APIAuth bogus:bogus'
      response = generated_response(request, :index)
      expect(response.code).to eq('401')
    end

    it 'should allow non-protected controller actions to function as before' do
      request = if ActionController::TestRequest.respond_to?(:create)
                  ActionController::TestRequest.create(ApplicationController)
                else
                  ActionController::TestRequest.new
                end
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
