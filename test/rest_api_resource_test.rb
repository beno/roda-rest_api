require "test_helpers"

class RestApiResourceTest < Minitest::Unit::TestCase
	include TestHelpers

	def setup
		app :rest_api do |r|
			r.resource :albums do |rsc|
				rsc.list   { |params| Album.find(params)  }
				rsc.one    { |params| Album[params['id']] 	}
				rsc.delete { |params| Album[params['id']].destroy }
				rsc.save   { |atts| Album.create_or_update(atts)  }
			end
			r.resource :artists, primary_key: 'artist_id' do |rsc|
				rsc.list   { |params| Artist.find(params)  }
				rsc.one    { |params| Artist[params['artist_id']]	 	}
				rsc.routes :index, :show
				r.destroy do
					'destroy artist'
				end
			end
		end
	end

	def test_index
		assert_equal Album.find({}).to_json, body('/albums')
	end

	def test_index_with_params
		assert_equal Album.find({'page' => 3}).to_json, body('/albums', {'QUERY_STRING' => 'page=3'})
	end

	def test_show
		assert_equal Album[12].to_json, body('/albums/12')
	end
	
	def test_notfound
		assert_equal 404, status('/albums/13')
	end
	
	
	def test_create
		name = 'bar'
		album = Album.new(1, name)
		assert_equal album.to_json, body('/albums', {'REQUEST_METHOD' => 'POST', 'rack.input' => {name: name}.to_json})
	end

	def test_update_patch
		id, name = 12, 'foo'
		album = Album.new(id, name)
		assert_equal album.to_json, body('/albums/12', {'REQUEST_METHOD' => 'PATCH', 'rack.input' => {id: id, name: name}.to_json})
		assert_equal album.to_json, body('/albums/12', {'REQUEST_METHOD' => 'PUT', 'rack.input' => {id: id, name: name}.to_json})
	end
	
	def test_destroy
		assert_equal '', body('/albums/12', {'REQUEST_METHOD' => 'DELETE'})
		assert_equal 204, status('/albums/12', {'REQUEST_METHOD' => 'DELETE'})
	end
	
	def test_edit
		assert_equal Album[12].to_json, body('/albums/12/edit')
	end

	def test_new
		assert_equal Album.new.to_json, body('/albums/new')
	end
	
	def test_album_show_status
		assert_equal 200, status('/albums/12')
	end

	def test_undefined_path
		assert_equal 404, status('/albums/list')
	end


	def test_artist_index
		assert_equal Artist.find({}).to_json, body('/artists')
	end
	
	def test_artist_show
		assert_equal Artist[12].to_json, body('/artists/12')
	end

	def test_artist_show_status
		assert_equal 200, status('/artists/12')
	end
	
	def test_artist_custom_destroy
		assert_equal 'destroy artist', body('/artists/12', {'REQUEST_METHOD' => 'DELETE'})
	end

	
	def test_artist_not_found_method
		assert_equal 404, status('/artists/12', {'REQUEST_METHOD' => 'FOO'})
	end

	def test_artist_not_found_path
		assert_equal 404, status('/artistss')
	end

end

