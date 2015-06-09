require "test_helpers"

class RestApiApiTest < Minitest::Test
	include TestHelpers

	def setup
	end

	def test_api_version
		app :rest_api do |r|
			r.api do
				r.version 1 do
					'api version 1'
				end
			end
		end
		assert_equal 'api version 1', request.get('/api/v1').body
	end

	def test_api_version_no_path
		app :rest_api do |r|
			r.api(path: '') do
				r.version 1 do
					'api version 1'
				end
			end
		end
		assert_equal 'api version 1', request.get('/v1').body
	end

	def test_api_version_subdomain
		app :rest_api do |r|
			r.api(subdomain: 'api') do
				r.version 1 do
					'api version 1'
				end
			end
		end
		assert_equal 'api version 1', request.get('/api/v1', "HTTP_HOST" => "api.example.com").body
	end

	def test_api_host_fail
		app :rest_api do |r|
			r.api(subdomain: 'api') do
				r.version 1 do
					'api version 1'
				end
			end
		end
		assert_equal 404, request.get('/api/v1', "HTTP_HOST" => "www.example.com").status
	end

	def test_api_path_fail
		app :rest_api do |r|
			r.api do
				r.version 1 do
					'api version 1'
				end
			end
		end
		assert_equal 404, request.get('/v1').status
	end
	
	def test_api_path_fail2
		app :rest_api do |r|
			r.api do
				r.resource :foo do |foo|
					foo.list {[]}
				end
			end
		end
		assert_equal 404, request.get('/foo').status
	end

end

