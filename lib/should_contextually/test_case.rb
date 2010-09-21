module ShouldContextually
  module TestCase

    def self.included(test_case)
      test_case.send(:include, InstanceMethods)
      test_case.send(:extend, ClassMethods)
    end

    module InstanceMethods

      private

      def should_contextually_setup_before_all_cache
        cache_instance_variables
        restore_cached_state
        start_db_transaction
      end

      def should_contextually_teardown_before_all_cache
        rollback_db_changes
      end

      def restore_cached_state
        ShouldContextually.cached_ivars.each do |name, value|
          instance_variable_set(name, value.dup) rescue instance_variable_set(name, value)
        end
      end

      def start_db_transaction
        if ActiveRecord::Base.connected?
          ActiveRecord::Base.connection.increment_open_transactions
          ActiveRecord::Base.connection.transaction_joinable = false
          ActiveRecord::Base.connection.begin_db_transaction
        end
      end

      def rollback_db_changes
        return unless ActiveRecord::Base.connected?
        if ActiveRecord::Base.connection.open_transactions != 0
          ActiveRecord::Base.connection.rollback_db_transaction
          ActiveRecord::Base.connection.decrement_open_transactions
        end
        ActiveRecord::Base.clear_active_connections!
      end

      def cache_instance_variables
        if ShouldContextually.cached_before_all_block && !ShouldContextually.caching_done
          original_ivars = instance_variables
          instance_eval &ShouldContextually.cached_before_all_block
          new_ivars = instance_variables - original_ivars
          ShouldContextually.cached_ivars = new_ivars.inject({}) { |ivars, var_name| ivars[var_name] = instance_variable_get(var_name); ivars }
          ShouldContextually.caching_done = true
        end
      end

    end

    module ClassMethods
      def should_contextually(&block)
        context "" do
          setup { should_contextually_setup_before_all_cache }
          setup &ShouldContextually.before_all_roles_block if ShouldContextually.before_all_roles_block
          teardown { should_contextually_teardown_before_all_cache }
          instance_eval &block
        end
      end

      def allow_access_only_to(action, options, &request)
        allow_roles = extract_roles!(options)
        deny_roles = ShouldContextually.roles - allow_roles
        allow_access_to action, options, &request
        deny_access_to action, :as => deny_roles, &request
      end

      def allow_access_to(action, options, &request)
        roles = extract_roles!(options)
        roles.each do |role|
          allow_test = ShouldContextually.allow_access_block
          access_test_for(action, role, request, allow_test)
        end
      end

      def deny_access_to(action, options, &request)
        roles = extract_roles!(options)
        roles.each do |role|
          deny_test = ShouldContextually.deny_test_for(role)
          access_test_for(action, role, request, deny_test)
        end
      end

      private

      def extract_roles!(options)
        Array(options[:as]).inject([]) do |roles, role_or_group|
          roles.unshift(*ShouldContextually.groups[role_or_group] || role_or_group)
        end
      end

      def access_test_for(action, role, request, assertions)
        context "accessing :#{action} as #{role}" do
          setup &ShouldContextually.role_setup_blocks[role]
          setup &request
          instance_eval &assertions
        end
      end
    end
  end
end

ActionController::TestCase.send(:include, ShouldContextually::TestCase)