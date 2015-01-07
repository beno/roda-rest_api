class Roda
	module RodaPlugins

		module RestApi

			APPLICATION_JSON = 'application/json'.freeze
			SINGLETON_ROUTES = %i{ show create update destroy edit new }.freeze

			def self.load_dependencies(app, _opts = {})
				app.plugin :all_verbs
				app.plugin :symbol_matchers
				app.plugin :header_matchers
				app.plugin :static_path_info
			end
			
			class Resource
				
				attr_reader :request, :path, :singleton, :content_type, :parent
				attr_accessor :captures
				
				def initialize(path, request, parent, options={})
					@request = request
					@path = path.to_s
					bare = options.delete(:bare) || false
					@singleton = options.delete(:singleton) || false
					@primary_key = options.delete(:primary_key) || "id"
					@parent_key = options.delete(:parent_key) || "parent_id"
					@content_type = options.delete(:content_type) || APPLICATION_JSON
					if parent
						@parent = parent
						@path = [':d', @path].join('/') unless bare
					end
				end
								
				def list(&block)
					@list = block if block
					@list || ->(_){raise NotImplementedError, "list"}
				end
				
				def one(&block)
					@one = block if block
					@one || ->(_){raise NotImplementedError, "one"}
				end
				
				def save(&block)
					@save = block if block
					@save || ->(_){raise NotImplementedError, "save"}
				end
				
				def delete(&block)
					@delete = block if block
					@content_type = nil
					@delete || ->(_){raise NotImplementedError, "delete"}
				end
				
				def serialize(&block)
					@serialize = block if block
					@serialize || ->(obj){obj.is_a?(String) ? obj : obj.send(:to_json)}
				end
				
				def routes(*routes)
					@routes = routes
				end
				
				def permit(*permitted)
					@permitted = permitted
				end
					
				def routes!
					unless @routes
						@routes = SINGLETON_ROUTES.dup
						@routes << :index unless @singleton
					end
					@routes.each { |route| @request.send(route) }
				end
				
				POST_BODY  = 'rack.input'.freeze
				FORM_INPUT = 'rack.request.form_input'.freeze
				FORM_HASH  = 'rack.request.form_hash'.freeze

				
				def perform(method, id = nil)
					begin
						args = self.arguments(method)
						args.merge!(@primary_key.to_sym => id) if id
						args.merge!(@parent_key.to_sym => @captures[0]) if @captures
						self.send(method).call(args)
					rescue StandardError => e
						raise if ENV['RACK_ENV'] == 'development'
						@request.response.status = method === :save ? 422 : 404
					end
				end
				
				protected
				
				def arguments(method)
					if method === :save
						args = if @request.media_type == "application/x-www-form-urlencoded"
							@request.POST
						else
							JSON.parse(@request.body.string)
						end
						permitted_args args
					else
						symbolize_keys @request.GET
					end
				end

				private
				
				def symbolize_keys(args)
					_args = {}
					args.each do |k,v|
						v = symbolize_keys(v) if v.is_a?(Hash)
						_args[k.to_sym] = v
					end
					_args
				end
				
				def permitted_args(args, keypath = [])
					permitted = nil
					case args
					when Hash
						permitted = Hash.new
						args.each_pair do |k,v|
							keypath << k.to_sym
							if permitted?(keypath)
								value = permitted_args(v, keypath)
								permitted[k.to_sym] = value if value
							end
							keypath.pop
						end
					else
						permitted = args if permitted?(keypath)
					end
					permitted
				end
				
				def permitted?(keypath)
					return false unless @permitted
					permitted = @permitted
					find_key = ->(items, key){
						items.find do |item|
							case item
							when Hash
								!!item.keys.index(key)
							when Symbol
								item === key
							end
						end
					}
					keypath.each do |key|
						found = find_key.call(permitted, key)
						permitted = found.is_a?(Hash) ? found.values.flatten : []
						return false unless found
					end
				end
			
			end
			
			module RequestMethods
				
				def api(options={}, &block)
					path = options.delete(:path) || 'api'
					subdomain = options.delete(:subdomain)
					options.merge!(host: /\A#{Regexp.escape(subdomain)}\./) if subdomain
					path = true if path.nil? or path.empty?
					on(path, options, &block)
				end

				def version(version, &block)
			  		on("v#{version}", &block)
				end

				def resource(path, options={})
					@resource = Resource.new(path, self, @resource, options)
					on(@resource.path, options) do
						@resource.captures = captures.dup unless captures.empty?
						yield @resource
					 	@resource.routes!
						response.status = 404
				  end
				 	@resource = @resource.parent
				end

			  def index(options={}, &block)
				  block ||= ->{ @resource.perform(:list) }
					get(['', true], options, &block)
			  end

			  def show(options={}, &block)
				  block ||= default_block(:one)
					get(_path, options, &block)
			  end

			  def create(options={}, &block)
				 	block ||= ->{@resource.perform(:save)}
					post(["", true], options) do
						response.status = 201
						block.call(*captures) if block
					end
			  end

			  def update(options={}, &block)
					block ||= default_block(:save)
				  options.merge!(method: [:put, :patch])
					is(_path, options, &block)
			  end

			  def destroy(options={}, &block)
					block ||= default_block(:delete)
					delete(_path, options) do
						response.status = 204
						block.call(*captures) if block
					end
			  end

			  def edit(options={}, &block)
					block ||= default_block(:one)
					get(_path("edit"), options, &block)
			  end

			  def new(options={}, &block)
				  block ||= ->{@resource.perform(:one, "new")}
					get("new", options, &block)
			  end
				
			  private
			  
			  def _path(path=nil)
				  if @resource and @resource.singleton
						path = ["", true] unless path
					else
						path = [":d", path].compact.join("/")
					end
					path
				end
				
				def default_block(method)
					if @resource.singleton
						->(){@resource.perform(method)}
					else
						->(id){@resource.perform(method, id)}
					end
				end
			  
			  CONTENT_TYPE = 'Content-Type'.freeze

			  def block_result_body(result)
				  if result && @resource
				  		response[CONTENT_TYPE] = @resource.content_type
				  		@resource.serialize.call(result)
				  	else
					  	super
					end
			  end
			  
			end
		end

		register_plugin(:rest_api, RestApi)

	end
end