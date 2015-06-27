require "test_helpers"

class RestApiResourceTest < Minitest::Test
	include TestHelpers

	def setup
		app :rest_api do |r|
			r.resource :albums do |rsc|
				rsc.list   { |params| Album.find(params)  }
				rsc.one    { |params| Album[params[:id]] }
				rsc.delete { |params| Album[params[:id]].destroy }
				rsc.save   { |atts| Album.create_or_update(atts)  }
				rsc.permit :name
			end
			r.resource :artists, primary_key: 'artist_id' do |rsc|
				rsc.list   { |params| Artist.find(params)  }
				rsc.one    { |params| Artist[params[:artist_id]]	 	}
				rsc.routes :index, :show, :create
				r.destroy do
					'destroy artist'
				end
			end
		end
	end

	def test_index
		assert_equal Album.find({}).to_json, request.get('/albums').body
	end
	
	def test_index_with_params
		albums = Album.find({:page => 3})
		assert_equal albums.to_json, request.get('/albums', {'QUERY_STRING' => 'page=3'}).body
		assert_equal albums.to_json, request.get('/albums', params:{page:'3'}).body
	end
	
	def test_show
		assert_equal Album[12].to_json, request.get('/albums/12').body
	end
	
	def test_notfound_id
		assert_equal 404, request.get('/albums/13').status
	end
	
	def test_create
		id, name = 1, 'bar'
		album = Album.new(id, name)
		response = request.post('/albums', input: {name: name}.to_json)
		assert_equal album.to_json, response.body
		assert_equal 201, response.status
	end
	
	def test_create_empty
		response = request.post('/albums', input: "")
		assert_equal 422, response.status
		assert_match /at least contain two octets/, response.body
	end

	def test_create_error
		response = request.post('/albums', input: "illegal")
		assert_match /unexpected token/, response.body
		assert_equal 422, response.status
	end
	
	def test_update_error
		assert_equal 422, request.put('/albums/12', input: "illegal").status
		assert_equal 422, request.patch('/albums/12', input: "illegal").status
	end
	
	def test_update_album
		id, name = 12, 'foo'
		album = Album.new(id, name)
		assert_equal album.to_json, request.patch('/albums/12', input: {id: id, name: name}.to_json).body
		assert_equal album.to_json, request.put('/albums/12', input: {id: id, name: name}.to_json).body
	end
	
	def test_destroy
		response = request.delete('/albums/12')
		assert_equal '', response.body
		assert_equal 204, response.status
	end
		
	def test_edit
		assert_equal Album[12].to_json, request.get('/albums/12/edit').body
	end
	
	def test_new
		assert_equal Album.new.to_json, request.get('/albums/new').body
	end
	
	def test_album_show_status
		assert_equal 200, request.get('/albums/12').status
	end
	
	def test_undefined_path
		assert_equal 404, request.get('/albums/--').status
	end
	
	def test_artist_index
		assert_equal Artist.find({}).to_json, request.get('/artists').body
	end
	
	def test_artist_show
		assert_equal Artist[12].to_json, request.get('/artists/12').body
	end
	
	def test_artist_show_status
		assert_equal 200, request.get('/artists/12').status
	end
	
	def test_artist_custom_destroy
		assert_equal '', request.delete('/artists/12').body
	end
	
	def test_artist_not_implemented
		assert_raises(NotImplementedError) { request.post('/artists', input: {'name' => 'foo'}.to_json).body }
	end
	
	def test_artist_method_not_defined
		assert_equal 404, request.put('/artists/12', input: {'name' => 'foo'}.to_json).status
	end
	
	def test_artist_not_found_path
		assert_equal 404, request.get('/artistss').status
	end
	
end

