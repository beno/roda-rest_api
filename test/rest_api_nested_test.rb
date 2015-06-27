require "test_helpers"

class RestApiNestedTest < Minitest::Test
	include TestHelpers
	
	def setup
		app :rest_api do |r|
			r.resource :albums do |albums|
					albums.list { |params| Album.find({} ) }
					albums.one    { |params| Album[params[:id]] 	}
					albums.routes :index, :show
				r.resource :songs do |songs|
					songs.list { |params| Song.find({ :album_id => params[:parent_id]} ) }
					songs.one    { |params| Song[params[:id]] 	}
					songs.routes :index, :show
				end
				r.resource :settings, singleton: true do |settings|
					settings.one    { |params| Settings[3] 	}
					settings.save    { |atts| Settings[3].save(atts) 	}
					settings.routes :show, :update
					settings.permit :name
				end
				r.resource :artwork, parent_key: :album_id do |artwork|
					artwork.list { |params| Artwork.find(params) }
					artwork.routes :index
				end
				r.resource :favorites, bare: true do |favorites|
					favorites.list   { |params| Favorite.find(params)  }
					favorites.one    { |params| Favorite[params[:id]] 	}
					favorites.routes :index, :show
					r.resource :things do |things|
						things.list   { |params| Thing.find(params)  }
						things.one    { |params| Thing[params[:id]] 	}
						things.routes :index, :edit
					end

				end
			end

		end
	end

	def test_album_index
		assert_equal Album.find({}).to_json, request.get('/albums').body
	end
	
	def test_album_show
		assert_equal Album[10].to_json, request.get('/albums/10').body
	end

	def test_album_fail
		assert_equal 404, request.get('/albums/--').status
	end
	
	def test_songs_index
		assert_equal Song.find({:album_id => 12 }).to_json, request.get('/albums/12/songs').body
	end
	
	def test_songs_show
		assert_equal Song[10].to_json, request.get('/albums/12/songs/10').body
	end

	def test_songs_fail
		assert_equal 404, request.get('/albums/12/songs/--').status
	end
	
	def test_singleton_update
		id, name = 3, 'bar'
		settings = Settings.new(id, name)
		assert_equal settings.to_json, request.patch('/albums/12/settings', input: {name: name}.to_json).body
	end
	#
	def test_favorites_index
		assert_equal Favorite.find({}).to_json, request.get('/albums/favorites').body
	end
	
	def test_favorites_show
		assert_equal Favorite[7].to_json, request.get('/albums/favorites/7').body
	end
	
	def test_filtered_default
		assert_equal Song.find({:album_id => 9 }).to_json, request.get('/albums/9/songs').body
	end
	
	def test_filtered_custom
		assert_equal Artwork.find({:album_id => 8 }).to_json, request.get('/albums/8/artwork').body
	end

	def test_deep_nest_fail
		assert_equal 404, request.get('/albums/favorites/4/things/3').status
	end

	def test_deep_nest
		assert_equal Thing[3].to_json, request.get('/albums/favorites/4/things/3/edit').body
	end

	
	class Song < Mock ; end
	class Settings < Mock ; end
	class Favorite < Mock ; end
	class Artwork < Mock ; end
	class Thing < Mock ; end


end
