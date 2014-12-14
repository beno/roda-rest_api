require "test_helpers"
require "minitest/benchmark"

class RestApiPerformanceTest < MiniTest::Unit::TestCase
	include TestHelpers



	def bench_test_block
		app :rest_api do |r|
			r.resource :albums do |rsc|
				rsc.list   { |params| Album.find(params)  }
				rsc.one    { |params| Album[params['id']] 	}
				rsc.routes :show
			end
		end

		assert_performance_linear 0.99 do |n|
			n.times do
				body('/albums/12')
			end
		end
	end
	

	

end
