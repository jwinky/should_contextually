module ShouldContextually
  module TestCase
    def should_contextually(&block)
      yield
    end

    def allow_access_to(action, options, &request)
      roles = extract_roles!(options)
      roles.each do |role|
        context("accessing :#{action} as #{role}") do
          setup &ShouldContextually.before_setup_for(role)
          setup &request
          should_respond_with :success
        end
      end
    end

    def deny_access_to(action, options, &request)
      roles = extract_roles!(options)
      roles.each do |role|
        deny_test = ShouldContextually.deny_test_for(role)
        context "accessing :#{action} as #{role}" do
          setup &ShouldContextually.before_setup_for(role)
          setup &request
          instance_eval &deny_test
        end
      end
    end

    private

    def extract_roles!(options)
      Array options[:as]
    end
  end
end

ActionController::TestCase.send(:extend, ShouldContextually::TestCase)