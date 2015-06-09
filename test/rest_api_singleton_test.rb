require "test_helpers"

class RestApiSingletonTest < Minitest::Test
	include TestHelpers
	
	def setup
		app :rest_api do |r|
			r.resource :profile, singleton: true do |rsc|
				rsc.one { |params| Profile[params[:id] || 12]}
				rsc.save { |atts| Profile.create_or_update(atts) }
				rsc.delete { |params| Profile[12].destroy	}
				rsc.permit :name
			end
		end
	end

	def test_singleton_show
		assert_equal Profile[12].to_json, request.get('/profile').body
	end

	def test_singleton_create
		name = 'bar'
		album = Profile.new(1, name)
		assert_equal album.to_json, request.post('/profile', input: {name: name}.to_json).body
	end
	
	def test_singleton_update
		name = 'bar'
		album = Profile.new(1, name)
		assert_equal album.to_json, request.patch('/profile', input: {name: name}.to_json).body
		assert_equal album.to_json, request.put('/profile', input: {name: name}.to_json).body
	end
	
	def test_singleton_destroy
		response = request.delete('/profile')
		assert_equal '', response.body
		assert_equal 204, response.status
	end
	
	def test_singleton_edit
		assert_equal Profile[12].to_json, request.get('/profile/edit').body
	end
	
	def test_singleton_new
		assert_equal Profile.new.to_json, request.get('/profile/new').body
	end


	class Profile < Mock; end
end


