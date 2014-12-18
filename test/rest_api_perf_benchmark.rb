require "test_helpers"
require "minitest/benchmark"

class RestApiPerformanceTest < Minitest::Benchmark
	include TestHelpers

	def setup
		app :rest_api do |r|
			r.resource :albums do |rsc|
				rsc.list   { |params| Album.find(params)  }
				rsc.one    { |params| Album[params[:id]] 	}
				rsc.save    { |atts| Album.create_or_update(atts) 	}
				rsc.routes :show, :create
			end
		end
	end

	def bench_show
		assert_performance_linear 0.99 do |n|
			n.times do
				body('/albums/12')
			end
		end
	end
	
	def bench_create
		assert_performance_linear 0.99 do |n|
			n.times do
				body('/albums',  {'REQUEST_METHOD' => 'POST', 'rack.input' => {name: 'foo'}.to_json})
			end
		end
	end
	

end
