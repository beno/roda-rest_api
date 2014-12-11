require "test_helpers"

class RestApiResourceTest < Minitest::Unit::TestCase
	include TestHelpers

	def setup
		app :rest_api do |r|
			r.resource :albums do
				r.index {"album index"}
				r.show {|id| "album #{id} show"}
				r.update {|id| "album #{id} update"}
				r.destroy {|id| "album #{id} destroy"}
				r.create {"album create"}
				r.edit {|id| "album #{id} edit"}
				r.new {"album new"}
			end
		end
	end

	def test_index_no_slash
		assert_equal 'album index', body('/albums')
	end

	def test_index_slash
		assert_equal 'album index', body('/albums/')
	end

	def test_show
		assert_equal 'album 12 show', body('/albums/12')
	end

	def test_create_no_slash
		assert_equal 'album create', body('/albums', {'REQUEST_METHOD' => 'POST'})
	end

	def test_create_slash
		assert_equal 'album create', body('/albums/', {'REQUEST_METHOD' => 'POST'})
	end

	def test_update_patch
		assert_equal 'album 12 update', body('/albums/12', {'REQUEST_METHOD' => 'PATCH'})
	end

	def test_update_put
		assert_equal 'album 12 update', body('/albums/12', {'REQUEST_METHOD' => 'PUT'})
	end

	def test_edit
		assert_equal 'album 12 edit', body('/albums/12/edit')
	end

	def test_new
		assert_equal 'album new', body('/albums/new')
	end

	def test_fail
		assert_equal 404, status('/albumss')
	end

end

