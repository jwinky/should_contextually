require File.expand_path('test_helper', File.dirname(__FILE__))

ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'monkey'
  map.login 'session', :controller => 'session'
  map.index 'tests', :controller => 'tests', :action => 'index'
  map.index 'foo', :controller => 'tests', :action => 'foo'
end


class TestsController < ActionController::Base
  attr_accessor :current_user, :global_before, :overridden_in_setup

  before_filter :ensure_before_all_ran
  before_filter :ensure_overridden_in_setup_set_to_true

  def index
    if not current_user
      redirect_to login_path
    elsif not current_user == :user
      redirect_to root_url
    else
      render :text => "hello, world"
    end
  end

  def foo
    if current_user
      render :text => "bar"
    else
      redirect_to login_path
    end
  end

  private

  def ensure_before_all_ran
    raise "global before not run" unless global_before
  end

  def ensure_overridden_in_setup_set_to_true
    raise "variable not properly set in setup block" unless @overridden_in_setup
  end
end

CACHED_OBJECT = { :timestamp => Time.now.to_i, :changed => false }
$expensive_operation_counter = 0

ShouldContextually.define do
  roles :user, :visitor, :monkey

  cached_before_all do
    puts "Doing an Expensive Operation"
    $expensive_operation_counter += 1
    @cached_object = CACHED_OBJECT
  end

  before_all do
    @controller.global_before = true
    @controller.overridden_in_setup = false
  end

  before(:user) { @controller.current_user = :user }
  before(:visitor) { @controller.current_user = nil }
  before(:monkey) { @controller.current_user = :monkey }

  group :user, :as => :group_of_roles_with_access_to_index
  group :visitor, :monkey, :as => :group_without_access_to_index

  allow_access do
    should_respond_with :success
  end

  deny_access do
    should_respond_with :forbidden
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
    setup do
      @controller.overridden_in_setup = true

      # Every test gets a dup of cached objects
      assert_equal 1, $expensive_operation_counter
      assert_equal CACHED_OBJECT[:timestamp], @cached_object[:timestamp]
      assert_equal false, @cached_object[:changed]
      assert_not_equal CACHED_OBJECT.object_id, @cached_object.object_id
      @cached_object[:changed] = true
    end

    context "With a single role" do
      allow_access_to(:index, :as => :user) { get :index }
      deny_access_to(:index, :as => :visitor) { get :index }
      deny_access_to(:index, :as => :monkey) { get :index }

      # This should fail
      allow_access_to(:index, :as => :monkey) { get :index }
      deny_access_to(:index, :as => :user) { get :index }

      context "allow_access_only_to" do
        allow_access_only_to(:index, :as => :user) { get :index }
      end
    end

    context "With multiple roles" do
      allow_access_only_to(:foo, :as => [:user, :monkey]) { get :foo }
    end

    context "With a group" do
      allow_access_to(:index, :as => :group_of_roles_with_access_to_index) { get :index }
      deny_access_to(:index, :as => :group_without_access_to_index) { get :index }

      context "allow_access_only_to" do
        allow_access_only_to(:index, :as => :group_of_roles_with_access_to_index) { get :index }
      end
    end

    context "With mixed groups and roles" do
      allow_access_only_to(:foo, :as => [:group_of_roles_with_access_to_index, :monkey]) { get :foo }
    end
  end


end
