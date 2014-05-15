require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Rails integration" do

  API_KEY_STORE = { "1044" => "l16imAXie1sRMcJODpOG7UwC1VyoqvO13jejkfpKWX4Z09W8DC9IrU23DvCwMry7pgSFW6c5S1GIfV0OY6F/vUA==" }

  describe "Rails controller integration" do

    class ApplicationController < ActionController::Base

    private

      def require_api_auth
        if (access_id = get_api_access_id_from_request)
          return true if api_authenticated?(API_KEY_STORE[access_id])
        end

        respond_to do |format|
          format.xml { render :xml => "You are unauthorized to perform this action.", :status => 401 }
          format.json { render :json => "You are unauthorized to perform this action.", :status => 401 }
    			format.html { render :text => "You are unauthorized to perform this action", :status => 401 }
        end
      end

    end

    class TestController < ApplicationController
      before_filter :require_api_auth, :only => [:index]

      if defined?(ActionDispatch)
        def self._routes
          ActionDispatch::Routing::RouteSet.new
        end
      end

      def index
        render :text => "OK"
      end

      def public
        render :text => "OK"
      end

      def rescue_action(e); raise(e); end
    end

    unless defined?(ActionDispatch)
      ActionController::Routing::Routes.draw {|map| map.resources :test }
    end

    def generated_response(request, action = :index)
      if defined?(ActionDispatch)
        TestController.action(action).call(request.env).last
      else
        request.action = action.to_s
        request.path = "/#{action.to_s}"
        TestController.new.process(request, ActionController::TestResponse.new)
      end
    end

    it "should permit a request with properly signed headers" do
      request = ActionController::TestRequest.new
      request.env['DATE'] = Time.now.utc.httpdate
      ApiAuth.sign!(request, "1044", API_KEY_STORE["1044"])
      response = generated_response(request, :index)
      response.code.should == "200"
    end

    it "should forbid a request with properly signed headers but timestamp > 15 minutes" do
      request = ActionController::TestRequest.new
      request.env['DATE'] = "Mon, 23 Jan 1984 03:29:56 GMT"
      ApiAuth.sign!(request, "1044", API_KEY_STORE["1044"])
      response = generated_response(request, :index)
      response.code.should == "401"
    end

    it "should insert a DATE header in the request when one hasn't been specified" do
      request = ActionController::TestRequest.new
      ApiAuth.sign!(request, "1044", API_KEY_STORE["1044"])
      request.headers['DATE'].should_not be_nil
    end

    it "should forbid an unsigned request to a protected controller action" do
      request = ActionController::TestRequest.new
      response = generated_response(request, :index)
      response.code.should == "401"
    end

    it "should forbid a request with a bogus signature" do
      request = ActionController::TestRequest.new
      request.env['Authorization'] = "APIAuth bogus:bogus"
      response = generated_response(request, :index)
      response.code.should == "401"
    end

    it "should allow non-protected controller actions to function as before" do
      request = ActionController::TestRequest.new
      response = generated_response(request, :public)
      response.code.should == "200"
    end

  end

  describe "Rails ActiveResource integration" do

    class TestResource < ActiveResource::Base
      with_api_auth "1044", API_KEY_STORE["1044"]
      self.site = "http://localhost/"
      self.format = :xml
    end

    it "should send signed requests automagically" do
      timestamp = Time.parse("Mon, 23 Jan 1984 03:29:56 GMT")
      Time.should_receive(:now).at_least(1).times.and_return(timestamp)
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/test_resources/1.xml",
          {
            'Authorization' => 'APIAuth 1044:IbTx7VzSOGU55HNbV4y2jZDnVis=',
            'Accept' => 'application/xml',
            'DATE' => "Mon, 23 Jan 1984 03:29:56 GMT"
          },
          { :id => "1" }.to_xml(:root => 'test_resource')
      end
      TestResource.find(1)
    end

  end

end
