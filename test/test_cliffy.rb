require 'helper'

class TestCliffy < Minitest::Test
  def test_version
    refute_nil Cliffy::VERSION
  end
end
