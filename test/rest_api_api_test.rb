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
		assert_equal 'api version 1', body('/api/v1')
	end

	def test_api_version_no_path
		app :rest_api do |r|
			r.api(path: '') do
				r.version 1 do
					'api version 1'
				end
			end
		end
		assert_equal 'api version 1', body('/v1')
	end

	def test_api_version_subdomain
		app :rest_api do |r|
			r.api(subdomain: 'api') do
				r.version 1 do
					'api version 1'
				end
			end
		end
		assert_equal 'api version 1', body('/api/v1', "HTTP_HOST" => "api.example.com")
	end

	def test_api_host_fail
		app :rest_api do |r|
			r.api(subdomain: 'api') do
				r.version 1 do
					'api version 1'
				end
			end
		end
		assert_equal 404, status('/api/v1', "HTTP_HOST" => "www.example.com")
	end

	def test_api_path_fail
		app :rest_api do |r|
			r.api do
				r.version 1 do
					'api version 1'
				end
			end
		end
		assert_equal 404, status('/v1')
	end
	
	def test_api_path_fail2
		app :rest_api do |r|
			r.api do
				r.resource :foo do |foo|
					foo.list {[]}
				end
			end
		end
		assert_equal 404, status('/foo')
	end

end

