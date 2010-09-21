module ShouldContextually
  module TestCase
    def should_contextually(&block)
      yield
    end

    def allow_access_to(action, options, &request)
      roles = extract_roles!(options)
      roles.each do |role|
        context("accessing :#{action} as #{role}") do
          should("respond with success") do
            assert true
          end
        end
      end
    end

    def deny_access_to(action, options, &request)
      roles = extract_roles!(options)
      roles.each do |role|
        context "accessing :#{action} as #{role}" do
          if role == :monkey
            should("redirect to root") { assert true }
          elsif role == :visitor
            should("redirect to log in") { assert true }
          else
            should("deny access") { assert false }
          end
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