require "test_helpers"

class RestApiPermitTest < Minitest::Test
	include TestHelpers
	
	def setup
		app :rest_api do |r|
			r.resource :albums do |albums|
				albums.list { |params| Album.find({} ) }
				albums.one  { |params| Album[params[:id]] 	}
				albums.routes :create, :update
				# albums.permit :name
			end

		end
	end

	# def test_album_create
	# 	assert_equal Album.find({}).to_json, body('/albums')
	# end
	#
	# def test_album_show
	# 	assert_equal Album[10].to_json, body('/albums/10')
	# end

end
