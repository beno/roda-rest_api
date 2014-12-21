require "test_helpers"

class RestApiPermitTest < Minitest::Test
	include TestHelpers
	

	def test_index_permitted
		app :rest_api do |r|
			r.resource :albums do |albums|
				albums.list  { |params| Album.find(params) 	}
				albums.routes :index
				albums.permit :page
			end
		end
		params = {page: '2'}
		assert_equal Album.find(params).to_json, body('/albums', {'QUERY_STRING' => 'page=2'})
	end
	
	
	def test_index_not_permitted
		app :rest_api do |r|
			r.resource :albums do |albums|
				albums.list  { |params| Album.find(params) 	}
				albums.routes :index
				albums.permit :page
			end
		end
		params = {page_ct: '2'}
		assert_equal Album.find({}).to_json, body('/albums', {'QUERY_STRING' => 'page_ct=2'})
	end

	def test_create_permitted
		app :rest_api do |r|
			r.resource :albums do |albums|
				albums.save  { |params| Album.create_or_update(params) 	}
				albums.routes :create, :update
				albums.permit :name, :price
			end
		end

		atts = {name: 'name', price: 3}
		album = Album.new(1, atts[:name], atts[:price])
		assert_equal album.to_json, body('/albums', {'REQUEST_METHOD' => 'POST', 'rack.input' => post_args(atts)})
		assert_equal 201, status('/albums', {'REQUEST_METHOD' => 'POST', 'rack.input' => post_args(atts)})
	end
	
	def test_create_not_permitted
		app :rest_api do |r|
			r.resource :albums do |albums|
				albums.save  { |params| Album.create_or_update(params) 	}
				albums.routes :create, :update
				albums.permit :name
			end
		end
	
		atts = {name: 'name', price: 3}
		album = Album.new(1, atts[:name])
		assert_equal album.to_json, body('/albums', {'REQUEST_METHOD' => 'POST', 'rack.input' => post_args(atts)})
	end

	def test_create_nested_single
		app :rest_api do |r|
			r.resource :albums do |albums|
				albums.save  { |params| Album.create_or_update(params) 	}
				albums.routes :create, :update
				albums.permit :name, {price: :amount}
			end
		end
	
		atts = {name: 'name', price: {amount: 4}}
		album = Album.new(1, atts[:name], atts[:price])
		assert_equal album.to_json, body('/albums', {'REQUEST_METHOD' => 'POST', 'rack.input' => post_args(atts)})
	end
	
	def test_create_nested_array
		app :rest_api do |r|
			r.resource :albums do |albums|
				albums.save  { |params| Album.create_or_update(params) 	}
				albums.routes :create, :update
				albums.permit :name, {price: [:amount, :currency, :discount]}
			end
		end
	
		atts = {name: 'name', price: {amount: 4}}
		album = Album.new(1, atts[:name], atts[:price])
		assert_equal album.to_json, body('/albums', {'REQUEST_METHOD' => 'POST', 'rack.input' => post_args(atts)})
	end
	
	def test_create_nested_single_not_permitted
		app :rest_api do |r|
			r.resource :albums do |albums|
				albums.save  { |params| Album.create_or_update(params) 	}
				albums.routes :create, :update
				albums.permit :name, {price: :total}
			end
		end
	
		atts = {name: 'name', price: {amount: 4}}
		album = Album.new(1, atts[:name], {})
		assert_equal album.to_json, body('/albums', {'REQUEST_METHOD' => 'POST', 'rack.input' => post_args(atts)})
	end
	
	def test_create_nested_array_not_permitted
		app :rest_api do |r|
			r.resource :albums do |albums|
				albums.save  { |params| Album.create_or_update(params) 	}
				albums.routes :create, :update
				albums.permit :name, {price: [:total, :currency, :discount]}
			end
		end
	
		atts = {name: 'name', price: {amount: 4, currency:'foo'}}
		album = Album.new(1, atts[:name], {currency:'foo'})
		assert_equal album.to_json, body('/albums', {'REQUEST_METHOD' => 'POST', 'rack.input' => post_args(atts)})
	end


end
