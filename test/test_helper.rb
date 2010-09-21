$:.unshift(File.expand_path('../lib', File.dirname(__FILE__)))
$:.unshift(File.dirname(__FILE__))

RAILS_ROOT = File.dirname(__FILE__)

require 'test/unit'
require 'rubygems'

require 'action_pack'
require 'action_controller'
require 'active_support'
require 'active_record'
require 'initializer'

require 'shoulda'
require 'monkeyspecdoc'
require 'should_contextually'
