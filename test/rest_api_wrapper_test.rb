require "test_helpers"

class RestApiWrapperTest < Minitest::Test
  include TestHelpers

  
  module Wrapper
    def around_save(args)
      "WRAP-#{yield(args)}-WRAP"
    	end
  end
  
  module FailingWrapper
    def around_save(args)
      raise "Not Allowed"
    end
  end

  module ModifyingWrapper
    def around_save(args)
      args[:foo] = 'baz'
      yield(args)
    end
  end
  
  
  def test_default_wrapper
    app :rest_api, wrapper: Wrapper do |r|
      r.resource :albums do |rsc|
        rsc.save { |atts| 'ALBUM' }
        rsc.list { |atts| 'LIST' }
      end
    end
    assert_equal "WRAP-ALBUM-WRAP", request.post('/albums', params:{foo:'bar'}).body
    assert_equal 'LIST', request.get('/albums').body
  end
  
  def test_failing_wrapper
    app :rest_api, wrapper: FailingWrapper do |r|
      r.resource :albums do |rsc|
        rsc.save { |atts| 'ALBUM' }
        rsc.list { |atts| 'LIST' }
      end
    end
    # assert_equal 422, request.post('/albums', params:{foo:'bar'}).status
    assert_equal 'LIST', request.get('/albums').body
  end
  
  def test_faulty_wrapper
    assert_raises RuntimeError do
      app(:rest_api, wrapper: :wrap) do |r|
        r.resource :albums do |rsc|
          rsc.list { |atts| 'LIST' }
        end
      end
    end
  end

  
  def test_modifying_wrapper
    app :rest_api, wrapper: ModifyingWrapper do |r|
      r.resource :albums do |rsc|
        rsc.save { |atts| atts[:foo] }
      end
    end
    assert_equal 'baz', request.post('/albums', params:{foo:'bar'}).body
  end


end