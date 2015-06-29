require "test_helpers"

class RestApiUpgradeTest < Minitest::Test
  include TestHelpers

  def test_raise_serialize
    assert_raises RuntimeError do
      app(:rest_api, serialize: 1)
    end
  end
  
  def test_raise_content_type
    assert_raises RuntimeError do
      app(:rest_api, content_type: 1)
    end
  end
  
  def test_not_raise_other
    assert app(:rest_api, other: 1)
  end
  
end