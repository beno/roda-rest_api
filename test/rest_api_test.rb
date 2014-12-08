require "test_helpers"

class RestApiTest < Minitest::Unit::TestCase
	include TestHelpers
	
  	def setup
  		@app = app :rest_api do |r|
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
		assert_equal 'album 12 edit', body('/albums/12/_edit')
	end

	def test_new
		assert_equal 'album new', body('/albums/_new')
	end
	
	

		# assert_equal 'object new', body('/objects/_new')
		# assert_equal 'object_12 edit', body('/objects/12/_edit')
  		  
  	# def test_that_it_will_not_blend
  	# 	refute_match /^no/i, @meme.will_it_blend?
  	# end
  	#
  	# def test_that_will_be_skipped
  	# 	skip "test this later"
  	# end
end
  
