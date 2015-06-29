class Roda
  module RodaPlugins

    module RestApi
      
      class DefaultSerializer
        def serialize(result)
          result.is_a?(String) ? result : result.to_json
        end
      end


      APPLICATION_JSON = 'application/json'.freeze
      SINGLETON_ROUTES = %i{ create new update show destroy edit }.freeze
      
      def self.load_dependencies(app, _opts = OPTS)
        app.plugin :all_verbs
        app.plugin :symbol_matchers
        app.plugin :header_matchers
        app.plugin :drop_body
      end
      
      def self.configure(app, opts = OPTS)
        all_keys = Resource::OPTIONS.keys << :serialize
        if (opts.keys & all_keys).any?
          raise "For version 2.0 all options [#{Resource::OPTIONS.keys.join(' ')}] must be set at the api, version or resource level."
        end
      end
            
      class Resource
        
        attr_reader :request, :path, :singleton, :parent, :id_pattern, :content_type
        attr_accessor :captures
        
        OPTIONS = { singleton: false,
          primary_key: "id",
          parent_key: "parent_id",
          id_pattern: /(\d+)/,
          content_type: APPLICATION_JSON,
          bare: false,
          serializer: RestApi::DefaultSerializer,
          wrapper: nil }.freeze
                
        def initialize(path, request, parent, options={})
          @request = request
          @path = path.to_s
          extract_options options
          if parent
            @parent = parent
            @path = ":id/#{@path}" unless @bare
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
          @delete || ->(_){raise NotImplementedError, "delete"}
        end
        
        def serialize(&block)
          @serialize = block if block
          @serialize || ->(_){raise NotImplementedError, "serialize"}
        end
        
        def routes(*routes)
          routes! if @routes
          yield if block_given?
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
          @request.roda_class.symbol_matcher(:id, @id_pattern)
          @routes.each { |route| @request.send(route) }
        end
        
        POST_BODY  = 'rack.input'.freeze
        FORM_INPUT = 'rack.request.form_input'.freeze
        FORM_HASH  = 'rack.request.form_hash'.freeze

        def perform_wrapped(method, args, &blk)
          if respond_to? :"around_#{method}"
            send :"around_#{method}", args, &blk
          else
            blk.call(args)
          end
        end
        
        def perform(method, id = nil)
          begin
            args = self.arguments(method, id)
            perform_wrapped(method, args) do |args|
              r = self.send(method).call(args)
            end
          rescue StandardError => e
            raise if ENV['RACK_ENV'] == 'development'
            @request.response.status = method === :save ? 422 : 404
            @request.response.write e
          end
        end
        
        protected
        
        def arguments(method, id)
          args = if method === :save
            form = Rack::Request::FORM_DATA_MEDIA_TYPES.include?(@request.media_type)
            permitted_args(form ? @request.POST : JSON.parse(@request.body.read))
          else
            symbolize_keys @request.GET
          end
          args.merge!(@primary_key.to_sym => id) if id
          args.merge!(@parent_key.to_sym => @captures[0]) if @captures
          args
        end

        private
        
        def extract_options(options)
          OPTIONS.each_pair do |key, default|
            ivar = "@#{key}"
            value = options.delete(key) || (@parent && @parent.instance_variable_get(ivar)) || default
            self.instance_variable_set(ivar, value) if value
          end
          if @wrapper
            raise ":wrapper should be a module" unless @wrapper.is_a? Module
            self.extend @wrapper
          end
          if @serializer
            raise ":serializer should be a class" unless @serializer.is_a? Class
            @serialize = ->(res){@serializer.new.serialize(res)}
          end
          p @request.path_info, @id_pattern
        end
        
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
          extract_options options
          path = options.delete(:path) || 'api'
          subdomain = options.delete(:subdomain)
          options.merge!(host: /\A#{Regexp.escape(subdomain)}\./) if subdomain
          path = true if path.nil? or path.empty?
          on(path, options, &block)
        end

        def version(version, options={}, &block)
          extract_options options
          on("v#{version}", options, &block)
        end

        def resource(path, options={})
          extract_options options
          @resource = Resource.new(path, self, @resource, @resource_options.last)
          on(@resource.path, options) do
            @resource.captures = captures.dup unless captures.empty?
            yield @resource
            @resource.routes!
            response.status = 404
          end
          @resource_options.pop
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
          block ||= ->(){@resource.perform(:save)}
          post(['', true], options) do
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
          get(_path('edit'), options, &block)
        end

        def new(options={}, &block)
          block ||= ->{@resource.perform(:one, "new")}
          get('new', options, &block)
        end
        
        private
        
        def extract_options(options)
          @resource_options ||= []
          opts = @resource_options.last || {}
          (Resource::OPTIONS.keys & options.keys).each do |key|
            opts[key] = options.delete(key)
          end
          @resource_options << opts
        end
        
        def _path(path=nil)
          if @resource and @resource.singleton
            path = ['', true] unless path
          else
            path = [':id', path].compact.join("/")
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