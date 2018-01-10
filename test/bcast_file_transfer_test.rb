require 'test_helper'

class BcastFileTransferTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::BcastFileTransfer::VERSION
  end
end
