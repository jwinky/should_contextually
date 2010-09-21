require 'should_contextually/test_case'

module ShouldContextually
  class ConfigurationError < StandardError; end
  
  class << self
    attr_accessor :deny_tests, :default_deny_test, :role_setup_blocks,
                  :before_all_roles_block, :allow_access_block, :roles

    def define(&configuation_block)
      Configurator.run(configuation_block)
    end

    def deny_test_for(role)
      deny_tests[role] || default_deny_test
    end

    def deny_tests
      @deny_tests ||= {}
    end

    def role_setup_blocks
      @role_setup_blocks ||= {}
    end

    def roles
      @roles || raise(ConfigurationError, "No roles defined.")
    end
  end

  class Configurator
    def self.run(configuration_block)
      new.instance_eval(&configuration_block)
    end

    def roles(*roles)
      ShouldContextually.roles = roles
    end

    def before_all(&block)
      ShouldContextually.before_all_roles_block = block
    end

    def before(role, &role_setup_block)
      ShouldContextually.role_setup_blocks[role] = role_setup_block
    end

    def deny_access(&block)
      ShouldContextually.default_deny_test = block
    end

    def deny_access_to(role, &block)
      ShouldContextually.deny_tests[role] = block
    end

    def allow_access(&block)
      ShouldContextually.allow_access_block = block
    end

#    def roles(*roles)
#
#    end
  end

end


__END__

module ShouldContextually
  Role = Struct.new(:name, :before, :deny_access)

  class Definition
    def self.define(&block)
      self.new.instance_eval(&block)
    end

    def roles(*roles)
      ShouldContextually.roles = roles.inject({}) { |hash, role| hash[role] = ShouldContextually::Role.new(role); hash }
    end

    def group(*roles)
      as = roles.pop[:as]
      ShouldContextually.groups[as] = roles
    end

    def before(name, &block)
      ShouldContextually.roles[name].before = block
    end

    def before_all(&block)
      ShouldContextually.before_all = block
    end

    def deny_access_to(name, &block)
      ShouldContextually.roles[name].deny_access = block
    end

    def deny_access(&block)
      ShouldContextually.deny_access_to_all = block
    end

    def allow_access(&block)
      ShouldContextually.allow_access_to_all = block
    end
  end

  class << self
    attr_accessor :roles, :deny_access_to_all, :allow_access_to_all, :before_all, :before_all_loaded, :fixture_instance_vars
#    attr_accessor :setup_transactional_before_all, :teardown_transactional_before_all

    def groups
      @groups ||= {}
    end

    def role(role)
      unless roles and roles.has_key?(role)
        raise "no role called #{role.inspect} exists"
      end
      roles[role]
    end

    def before(role)
      role(role).before
    end

    def deny_access(role)
      role(role).deny_access || deny_access_to_all
    end

    def allow_access
      allow_access_to_all
    end

    def define(&block)
      ShouldContextually::Definition.define(&block)
    end
  end

  module TestCaseMethods
    def should_contextually(when_description=nil, &blk)
      name = when_description.blank? ? "Accessing" : "When #{when_description}, accessing"
      context name do
         setup(&ShouldContextually.before_all)
#        setup &ShouldContextually.setup_transactional_before_all
#        teardown &ShouldContextually.teardown_transactional_before_all
        instance_eval(&blk)
      end
    end

    def deny_access_to(action, options, &request)
      extract_roles(options).each do |role|
        test_proc = ShouldContextually.deny_access(role)
        access_test action, role, request, &test_proc
      end
    end

    def allow_access_to(action, options, &request)
      extract_roles(options).each do |role|
        access_test action, role, request, &ShouldContextually.allow_access
      end
    end

    def allow_access_only_to(action, options, &request)
      allow_access_to(action, options, &request)
      deny_to_roles = ShouldContextually.roles.keys - extract_roles(options)
      deny_access_to(action, :as => deny_to_roles, &request)
    end

    private

    def extract_roles(options)
      raise ArgumentError, "The :as option is required" if options[:as].blank?
      Array(options[:as] || []).inject([]) { |array, role| array.push(*ShouldContextually.groups[role] || role); array }
    end

    def access_test(action, role, request, &test_proc)
      context ":#{action.to_s} as #{role}" do
        setup(&ShouldContextually.before(role))
        setup(&request)
        instance_eval &test_proc
      end
    end
  end
end

#ShouldContextually.setup_transactional_before_all = lambda do
#  if ShouldContextually.before_all && !ShouldContextually.before_all_loaded
#    orig_instance_vars = instance_variables
#    instance_eval &ShouldContextually.before_all
#    new_instance_vars = instance_variables - orig_instance_vars
#    ShouldContextually.fixture_instance_vars = new_instance_vars.inject({}) { |h, v| h[v] = instance_variable_get(v); h }
#    ShouldContextually.before_all_loaded = true
#  end
#
#  ShouldContextually.fixture_instance_vars.each do |name, value|
#    instance_variable_set(name, value.dup)
#  end
#
#  ActiveRecord::Base.transaction
#
#  ActiveRecord::Base.connection.increment_open_transactions
#  ActiveRecord::Base.connection.transaction_joinable = false
#  ActiveRecord::Base.connection.begin_db_transaction
#end
#
#ShouldContextually.teardown_transactional_before_all = lambda do
#  # Rollback changes if a transaction is active.
#  if ActiveRecord::Base.connection.open_transactions != 0
#    ActiveRecord::Base.connection.rollback_db_transaction
#    ActiveRecord::Base.connection.decrement_open_transactions
#  end
#  ActiveRecord::Base.clear_active_connections!
#end

ActionController::TestCase.send(:extend, ShouldContextually::TestCaseMethods)

