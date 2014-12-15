require "test_helpers"

class RestApiSingletonTest < Minitest::Unit::TestCase
	include TestHelpers
	
	def setup
		app :rest_api do |r|
			r.resource :profile, singleton: true do |rsc|
				rsc.one { |params| Profile[params['id'] || 12]}
				rsc.save { |atts| Profile.create_or_update(atts) }
				rsc.delete { |params| Profile[12].destroy	}
			end
		end
	end

	def test_singleton_show
		assert_equal Profile[12].to_json, body('/profile')
	end

	def test_singleton_create
		name = 'bar'
		album = Profile.new(1, name)
		assert_equal album.to_json, body('/profile', {'REQUEST_METHOD' => 'POST', 'rack.input' => {name: name}.to_json})
	end
	
	def test_singleton_update
		name = 'bar'
		album = Profile.new(1, name)
		assert_equal album.to_json, body('/profile', {'REQUEST_METHOD' => 'PATCH', 'rack.input' => {name: name}.to_json})
		assert_equal album.to_json, body('/profile', {'REQUEST_METHOD' => 'PUT', 'rack.input' => {name: name}.to_json})
	end
	
	def test_singleton_destroy
		assert_equal '', body('/profile', {'REQUEST_METHOD' => 'DELETE'})
		assert_equal 204, status('/profile', {'REQUEST_METHOD' => 'DELETE'})
	end
	
	def test_singleton_edit
		assert_equal Profile[12].to_json, body('/profile/edit')
	end
	
	def test_singleton_new
		assert_equal Profile.new.to_json, body('/profile/new')
	end


	class Profile < Mock; end
end


