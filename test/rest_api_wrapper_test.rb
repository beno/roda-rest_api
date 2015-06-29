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
    app :rest_api do |r|
      r.api wrapper: Wrapper do
        r.resource :albums do |rsc|
          rsc.save { |atts| 'ALBUM' }
          rsc.list { |atts| 'LIST' }
        end
      end
    end
    assert_equal "WRAP-ALBUM-WRAP", request.post('api/albums', params:{foo:'bar'}).body
    assert_equal 'LIST', request.get('api/albums').body
  end
  
  def test_failing_wrapper
    app :rest_api do |r|
      r.resource :albums, wrapper: FailingWrapper do |rsc|
        rsc.save { |atts| 'ALBUM' }
        rsc.list { |atts| 'LIST' }
      end
    end
    # assert_equal 422, request.post('/albums', params:{foo:'bar'}).status
    assert_equal 'LIST', request.get('/albums').body
  end
  
  def test_faulty_wrapper
      app(:rest_api) do |r|
        r.resource :albums, wrapper: :invalid do |rsc|
          rsc.list { |atts| 'LIST' }
        end
      end
      assert_raises RuntimeError do
        request.get('/albums').body
      end
  end

  
  def test_modifying_wrapper
    app :rest_api do |r|
      r.version 3, wrapper: ModifyingWrapper do
        r.resource :albums do |rsc|
          rsc.save { |atts| atts[:foo] }
        end
      end
    end
    assert_equal 'baz', request.post('v3/albums', params:{foo:'bar'}).body
  end


end