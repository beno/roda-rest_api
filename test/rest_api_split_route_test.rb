require "test_helpers"

class RestApiSplitRoutesTest < Minitest::Test
	include TestHelpers
	
	

	def setup
		app :rest_api do |r|
			def anything
				nil
			end

			r.resource :things do |u|
				u.one { |params| "one" }
				u.list { |params| "list" }
				u.routes :show
				anything
				u.routes :index
			end
		end
	end
	
	def test_split_routes
		assert_equal "one", body("/things/1")
		assert_equal "list", body("/things")
	end
		
end
