require "test_helpers"

class RestApiIdPatternTest < Minitest::Test
  include TestHelpers
  
  def setup
    app :rest_api, id_pattern: /id([\d]+)/ do |r|
      r.resource :albums do |rsc|
        rsc.save { |atts| "SAVE_#{atts[:id]}" }
      end
      r.resource :artists, id_pattern: /@([\d]+)/  do |rsc|
        rsc.one { |atts| "SHOW_#{atts[:id]}" }
        rsc.routes :show
        r.resource :songs do |rsc|
          rsc.one { |atts| "SONG_#{atts[:id]}" }
        end
      end

    end
  end

  def test_complex_pattern
    assert_equal "SAVE_12", request.put('/albums/id12', params:{foo:'bar'}).body
  end
  
  def test_failing_pattern
    assert_equal 404, request.get('/albums/12').status
  end
  
  def test_pattern_override
    assert_equal "SHOW_12", request.get('/artists/@12').body
  end
  
  def test_nested
    assert_equal "SONG_4", request.get('/artists/@12/songs/id4').body
  end



end