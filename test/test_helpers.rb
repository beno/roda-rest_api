require "minitest/autorun"
require "roda"
require "json"
require "stringio"
require "rack/test"

module TestHelpers
	include Rack::Test::Methods
	
	
	def app(type=nil, opts={}, &block)
		case type
		when :new
			@app = _app{route(&block)}
		when :bare
			@app = _app(&block)
		when Symbol
			@app = _app do
				plugin type, opts
				route(&block)
			end
		else
			@app ||= _app{route(&block)}
		end
	end

	def request
		Rack::MockRequest.new(@app)
	end

	def _app(&block)
		c = Class.new(Roda)
		c.class_eval(&block)
		Rack::Lint.new c
	end
		
	class Mock
	
		attr_accessor :id, :name, :price
	
		def self.find(params)
			if params[:page] || params[:album_id]
				[new(1, 'filtered' + params[:album_id].to_s )]
			else
				[new(1, 'foo'), new(2, 'bar')]
			end
		end
	
		def self.create_or_update(atts)
			if id = atts.delete(:id)
				self[id].save(atts)
			else
				self.new(1, atts[:name], atts[:price])
			end
		end
	
		def self.[](id)
			if id
				if id.to_i > 12
					raise DBNotFoundError
				end
				id == 'new' ? new : new(id.to_i, name: 'foo')
			end
		end
	
		def initialize(id = nil, name = nil, price = nil)
			@id = id
			@name = name
			@price = price
		end
	
		def save(atts)
			self.name = atts[:name]
			self.price = atts[:price]
			self
		end
	
		def destroy
			''
		end
	
		def to_json(state = nil)
			{id: @id, name: @name, price: @price, class: self.class.name }.to_json(state)
		end
	
	end
	
	class Album < Mock ; end
	class Artist < Mock ; end
	
	class DBNotFoundError < StandardError ; end
	
end
