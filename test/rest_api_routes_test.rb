require "test_helpers"

class RestApiRoutesTest < Minitest::Test
	include TestHelpers

	def setup
		app :rest_api do |r|
			r.resource :albums do
				r.index {"album index"}
				r.new {"album new"}
				r.show {|id| "album #{id} show"}
				r.update {|id| "album #{id} update"}
				r.destroy {|id| "album #{id} destroy"}
				r.create {"album create"}
				r.edit {|id| "album #{id} edit"}
			end
		end
	end

	def test_index_no_slash
		assert_equal 'album index', request.get('/albums').body
	end

	def test_index_slash
		assert_equal 'album index', request.get('/albums/').body
	end

	def test_show
		assert_equal 'album 12 show', request.get('/albums/12').body
	end

	def test_create_no_slash
		assert_equal 'album create', request.post('/albums').body
	end

	def test_create_slash
		assert_equal 'album create', request.post('/albums/').body
	end

	def test_update_patch
		assert_equal 'album 12 update', request.patch('/albums/12').body
	end

	def test_update_put
		assert_equal 'album 12 update', request.put('/albums/12').body
	end

	def test_edit
		assert_equal 'album 12 edit', request.get('/albums/12/edit').body
	end

	def test_new
		assert_equal 'album new', request.get('/albums/new').body
	end

	def test_fail
		assert_equal 404, request.get('/albumss').status
	end

end

