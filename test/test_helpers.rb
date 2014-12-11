require "minitest/autorun"
require "roda"
require "json"

module TestHelpers
	def app(type=nil, &block)
		case type
		when :new
			@app = _app{route(&block)}
		when :bare
			@app = _app(&block)
		when Symbol
			@app = _app do
				plugin type
				route(&block)
			end
		else
			@app ||= _app{route(&block)}
		end
	end

	def req(path='/', env={})
		if path.is_a?(Hash)
			env = path
		else
			env['PATH_INFO'] = path
		end

		env = {"REQUEST_METHOD" => "GET", "PATH_INFO" => "/", "SCRIPT_NAME" => ""}.merge(env)
		@app.call(env)
	end

	def status(path='/', env={})
		req(path, env)[0]
	end

	def header(name, path='/', env={})
		req(path, env)[1][name]
	end

	def body(path='/', env={})
		req(path, env)[2].join
	end

	def _app(&block)
		c = Class.new(Roda)
		c.class_eval(&block)
		c
	end
end
