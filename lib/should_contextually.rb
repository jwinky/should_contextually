require 'should_contextually/test_case'

module ShouldContextually
  class ConfigurationError < StandardError;
  end

  class << self
    attr_accessor :deny_tests, :default_deny_test, :role_setup_blocks,
                  :cached_before_all_block, :before_all_roles_block, :allow_access_block,
                  :roles, :groups

    attr_accessor :setup_before_all_cache, :teardown_before_all_cache, :cached_ivars, :caching_done

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

    def groups
      @groups ||= {}
    end

    def cached_ivars
      @cached_ivars ||= {}
    end

  end

  class Configurator
    def self.run(configuration_block)
      new.instance_eval(&configuration_block)
    end

    def roles(*roles)
      ShouldContextually.roles = roles
    end

    def group(*roles)
      group_name = roles.extract_options![:as]
      ShouldContextually.groups[group_name] = roles
    end

    def cached_before_all(&block)
      ShouldContextually.cached_before_all_block = block
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
  end

end



