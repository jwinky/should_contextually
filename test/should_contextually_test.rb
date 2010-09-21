require File.expand_path('test_helper', File.dirname(__FILE__))

ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'monkey'
  map.login 'session', :controller => 'session'
  map.index 'tests', :controller => 'tests', :action => 'index'
#  map.index 'test', :controller => 'tests', :action => 'show'
#  map.index 'foo', :controller => 'tests', :action => 'foo'
end


class TestsController < ActionController::Base
  attr_accessor :current_user, :global_before

  before_filter :ensure_before_all_ran

  def index
    if not current_user
      redirect_to login_path
    elsif not current_user == :user
      redirect_to root_url
    else
      render :text => "hello, world"
    end
  end

#  def foo
#    if not current_user
#      redirect_to new_session_url
#    end
#  end
#
#  def show
#
#  end

  private

  def ensure_before_all_ran
    raise "global before not run" unless global_before
  end
end


ShouldContextually.define do
#  roles :user, :visitor, :monkey

  before_all { @controller.global_before = true }

  before(:user) { @controller.current_user = :user }
  before(:visitor) { @controller.current_user = nil }
  before(:monkey) { @controller.current_user = :monkey }

  allow_access do
    should_respond_with :success
  end

  deny_access do
    should("deny access") { assert false }
  end

  deny_access_to :visitor do
    should_redirect_to("log in") { login_path }
  end

  deny_access_to :monkey do
    should_redirect_to("root") { root_path }
  end
end

class TestsControllerTest < ActionController::TestCase

  should_contextually do
    context "With a single role" do
      allow_access_to(:index, :as => :user) { get :index }
      deny_access_to(:index, :as => :visitor) { get :index }
      deny_access_to(:index, :as => :monkey) { get :index }
      allow_access_to(:index, :as => :monkey) { get :index }

      deny_access_to(:index, :as => :user) { get :index }
      # This should fail
    end

    context "With multiple roles" do
      # something
    end
  end

  context "True" do
    should("be false") { assert_equal false, true }
  end

  context "False" do
    should("be false") { assert_not_equal false, true }
  end

end
