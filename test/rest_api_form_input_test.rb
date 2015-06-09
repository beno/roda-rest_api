require "test_helpers"

class RestApiFormInputTest < Minitest::Test
	include TestHelpers

	def setup
		app :rest_api do |r|
			r.resource :albums do |rsc|
				rsc.save   { |atts| Album.create_or_update(atts)  }
				rsc.permit :name
			end
		end
	end

	def test_create
		id, name = 1, 'bar'
		album = Album.new(id, name)
		response = request.post('/albums', params: {name: name})
		assert_equal album.to_json, response.body
		assert_equal 201, response.status
	end

	def test_update
		id, name = 12, 'foo'
		album = Album.new(id, name)
		assert_equal album.to_json, request.patch('/albums/12', params: {id: id, name: name}).body
		assert_equal album.to_json, request.put('/albums/12', params: {id: id, name: name}).body
	end

end

