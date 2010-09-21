require File.expand_path('test_helper', File.dirname(__FILE__))
require 'ap'

class TestTest < Test::Unit::TestCase
  context "Output of should_contextually_test.rb" do
    should "match expected" do
      actual = `ruby #{File.join(File.dirname(__FILE__), "should_contextually_test.rb")}`.gsub(/(\033\[0;31m|\033\[0m|\033\[0;32m)/, '')
      expected = File.read(__FILE__).split(Base64.decode64("X19FTkRfXw==\n")).second.strip
      stars = "*"*80
      assert_match Regexp.new(Regexp.escape(expected)), actual, "\n#{ stars }\nACTUAL OUTPUT\n#{ stars }\n\n#{actual}\n#{ stars }\n"
    end
  end
end

__END__

TestsController with simple contexts as user responding to #GET index:
[  OK  ] ==> should respond with success

False:
[  OK  ] ==> should be false

True:
[FAILED] ==> should be false (1)

