require "test_helpers"

class RestApiSerializeTest < Minitest::Test
	include TestHelpers
	
	def setup
		app :rest_api do |r|
			r.resource :albums, content_type: 'text/xml' do |rsc|
				rsc.list   { |params| Album.find(params)  }
				rsc.one    { |params| Album[params['id']] 	}
				rsc.serialize { |result| result.is_a?(Enumerable) ? 'list xml' : 'one xml' }
				rsc.routes :index, :show
			end
		end
	end
	
	def test_index
		assert_equal 'list xml', body('/albums')
		assert_equal 'text/xml', header('Content-Type','/albums')
	end
		
	def test_show
		assert_equal 'one xml', body('/albums/12')
		assert_equal 'text/xml', header('Content-Type','/albums/12')
	end


end
