require "test_helpers"

class RestApiNestedTest < Minitest::Unit::TestCase
	include TestHelpers
	
	def setup
		app :rest_api do |r|
			r.resource :albums do |albums|
				r.resource :songs do |songs|
					songs.list { |params| Song.find({ 'album_id' => params['parent_id']} ) }
					songs.one    { |params| Song[params['id']] 	}
					songs.routes :index, :show
				end
				r.resource :settings, singleton: true do |settings|
					settings.one    { |atts| Settings[3] 	}
					settings.save    { |atts| Settings[3].save(atts) 	}
					settings.routes :show, :update
				end
				r.resource :artwork, parent_key: 'album_id' do |artwork|
					artwork.list { |params| Artwork.find(params) }
					artwork.routes :index
				end
				r.resource :favorites, bare: true do |favorites|
					favorites.list   { |params| Favorite.find(params)  }
					favorites.one    { |params| Favorite[params['id']] 	}
					favorites.routes :index, :show
				end
			end

		end
	end
		
	def test_songs_index
		assert_equal Song.find({'album_id' => 12 }).to_json, body('/albums/12/songs')
	end
	
	def test_songs_show
		assert_equal Song[10].to_json, body('/albums/12/songs/10')
	end
	
	def test_singleton_update
		id, name = 3, 'bar'
		settings = Settings.new(id, name)
		assert_equal settings.to_json, body('/albums/12/settings', {'REQUEST_METHOD' => 'PATCH', 'rack.input' => {name: name}.to_json})
	end
	#
	def test_favorites_index
		assert_equal Favorite.find({}).to_json, body('/albums/favorites')
	end
	
	def test_favorites_show
		assert_equal Favorite[7].to_json, body('/albums/favorites/7')
	end
	
	def test_filtered_default
		assert_equal Song.find({'album_id' => 9 }).to_json, body('/albums/9/songs')
	end
	
	def test_filtered_custom
		assert_equal Artwork.find({'album_id' => 8 }).to_json, body('/albums/8/artwork')
	end

	
	class Song < Mock ; end
	class Settings < Mock ; end
	class Favorite < Mock ; end
	class Artwork < Mock ; end


end
