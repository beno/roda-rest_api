require "test_helpers"

class RestApiSerializeTest < Minitest::Test
	include TestHelpers
	
	def setup
		app :rest_api do |r|
			r.resource :albums, content_type: 'text/xml' do |rsc|
				rsc.list   { |params| Album.find(params)  }
				rsc.one    { |params| Album[params[:id]] 	}
				rsc.serialize { |result| result.is_a?(Enumerable) ?  "<xml>#{result.map(&:id).join(',')}</xml>" : "<xml>#{result.id}</xml>" }
				rsc.routes :index, :show
			end
		end
	end
	
	def test_index
		response = request.get('/albums')
		assert_equal "<xml>1,2</xml>", response.body
		assert_equal 'text/xml', response.headers['Content-Type']
	end
		
	def test_show
		response = request.get('/albums/12')
		assert_equal "<xml>12</xml>", response.body
		assert_equal 'text/xml', response.headers['Content-Type']
	end


end
