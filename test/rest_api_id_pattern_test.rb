require "test_helpers"

class RestApiIdPatternTest < Minitest::Test
  include TestHelpers
  
  def setup
    app :rest_api do |r|
      r.api id_pattern: /id([\d]+)/ do
        r.resource :artists, id_pattern: /@([\d]+)/  do |rsc|
          rsc.one { |atts| "ARTIST_#{atts[:id]}" }
          r.resource :songs, id_pattern: /id([\d]+)/  do |rsc|
            rsc.one { |atts| "SONG_#{atts[:id]}" }
          end
          r.resource :concerts  do |rsc|
            rsc.one { |atts| "CONCERT_#{atts[:id]}" }
          end
        end
        r.resource :albums do |rsc|
          rsc.save { |atts| "SAVE_ALBUM_#{atts[:id]}" }
          rsc.routes :create, :update
        end
        r.resource :venues do |rsc|
          rsc.one { |atts| "VENUE_#{atts[:id]}" }
        end

      end
    end
  end

  def test_complex_pattern
    assert_equal "SAVE_ALBUM_12", request.put('api/albums/id12', params:{foo:'bar'}).body
  end
  
  def test_failing_pattern
    assert_equal 404, request.get('api/albums/12').status
  end
  
  def test_pattern_override
    assert_equal "ARTIST_12", request.get('api/artists/@12').body
  end
  
  def test_nested
    assert_equal "SONG_4", request.get('api/artists/@12/songs/id4').body
  end

  def test_nested_fallback
    assert_equal "CONCERT_3", request.get('api/artists/@12/concerts/@3').body
  end
  
  # def test_fallback
  #   assert_equal "CONCERT_3", request.get('api/artists/@12/concerts/id3').body
  # end



end