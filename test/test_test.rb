require File.expand_path('test_helper', File.dirname(__FILE__))
require 'ap'

begin
  require 'differ'
  Differ.format = :color
  USE_DIFFER = true
rescue LoadError
  USE_DIFFER = false
end


STARS = "*"*80

class TestTest < Test::Unit::TestCase
  context "Output of should_contextually_test.rb" do
    should "match expected" do
      actual = `ruby #{File.join(File.dirname(__FILE__), "should_contextually_test.rb")}`.gsub(/(\033\[0;31m|\033\[0m|\033\[0;32m)/, '')
      expected = File.read(__FILE__).split(Base64.decode64("X19FTkRfXw==\n")).second.strip
      assert_match Regexp.new(Regexp.escape(expected)), actual, failed_match_message(actual, expected)
    end
  end

  private

  def failed_match_message(actual, expected)
    if USE_DIFFER
      differ_failure_message(actual, expected)
    else
      plain_failure_message(actual)
    end
  end

  def differ_failure_message(actual, expected)
    "\n#{ STARS }\nDIFF'D OUTPUT\n#{ STARS }\n\n#{Differ.diff_by_line(actual, expected)}\n#{ STARS }\n"
  end

  def plain_failure_message(actual)
    "\n#{ STARS }\nACTUAL OUTPUT\n#{ STARS }\n\n#{actual}\n#{ STARS }\n"
  end
end

__END__

With a group accessing :index as monkey:
Doing an Expensive Operation
[  OK  ] ==> should redirect to root

With a group accessing :index as user:
[  OK  ] ==> should respond with success

With a group accessing :index as visitor:
[  OK  ] ==> should redirect to log in

With a group allow_access_only_to accessing :index as monkey:
[  OK  ] ==> should redirect to root

With a group allow_access_only_to accessing :index as user:
[  OK  ] ==> should respond with success

With a group allow_access_only_to accessing :index as visitor:
[  OK  ] ==> should redirect to log in

With a single role accessing :index as monkey:
[  OK  ] ==> should redirect to root
[FAILED] ==> should respond with success (1)

With a single role accessing :index as user:
[FAILED] ==> should respond with forbidden (2)
[  OK  ] ==> should respond with success

With a single role accessing :index as visitor:
[  OK  ] ==> should redirect to log in

With a single role allow_access_only_to accessing :index as monkey:
[  OK  ] ==> should redirect to root

With a single role allow_access_only_to accessing :index as user:
[  OK  ] ==> should respond with success

With a single role allow_access_only_to accessing :index as visitor:
[  OK  ] ==> should redirect to log in

With mixed groups and roles accessing :foo as monkey:
[  OK  ] ==> should respond with success

With mixed groups and roles accessing :foo as user:
[  OK  ] ==> should respond with success

With mixed groups and roles accessing :foo as visitor:
[  OK  ] ==> should redirect to log in

With multiple roles accessing :foo as monkey:
[  OK  ] ==> should respond with success

With multiple roles accessing :foo as user:
[  OK  ] ==> should respond with success

With multiple roles accessing :foo as visitor:
[  OK  ] ==> should redirect to log in
