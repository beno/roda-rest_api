class Roda
	module RodaPlugins

		module HeaderMatchers
			module RequestMethods

				private

				def match_subdomain(subdomain)
					host.match /^#{subdomain}\./
				end
			end
		end

		module RestApi

			def self.load_dependencies(app, _opts = {})
				app.plugin :all_verbs
				app.plugin :symbol_matchers
				app.plugin :header_matchers
				app.plugin :not_found
				app.plugin :json
			end

			module InstanceMethods

				def list(&block)
					@list = block if block
					@list || ->(_){raise NotImplementedError, "scope.list"}
				end

				def one(&block)
					@one = block if block
					@one || ->(_){raise NotImplementedError, "scope.one"}
				end

				def save(&block)
					@save = block if block
					@save || ->(_){raise NotImplementedError, "scope.save"}
				end

				def delete(&block)
					@delete = block if block
					@delete || ->(_){raise NotImplementedError, "scope.delete"}
				end

			end


			module RequestMethods

				def api(options={}, &block)
					api_path = options.delete(:path) || 'api'
					on([api_path, true], options, &block)
				end

				def version(version, &block)
			  		on("v#{version}", &block)
			  end

			  def resource name
			  		on name.to_s do
				  		yield
				  		response.status = 404
				  	end
			  end

			  def index(options={}, &block)
				  block ||= ->{ scope.list.call(self.GET) }
					get(['', true], options, &block)
			  end

			  def show(options={}, &block)
				  block ||= ->(id){scope.one.call(self.GET.merge('id' => id))}
				  	get(':d', options, &block)
			  end

			  def create(options={}, &block)
				  block ||= ->{scope.save.call(JSON.parse(body))}
			  		post(['', true], options, &block)
			  end

			  def update(options={}, &block)
				  block ||= ->(id){scope.save.call(JSON.parse(body).merge('id' => id))}
			  		is(":d", :method=>[:put, :patch], &block)
			  end

			  def destroy(options={}, &block)
				  block ||= ->(id){scope.delete.call(self.GET.merge({'id' => id}))}
			  		delete(":d", options, &block)
			  end

			  def edit(options={}, &block)
				  block ||= ->(id){scope.one.call(self.GET.merge({'id' => id}))}
			  		get(":d/edit", options, &block)
			  end

			  def new(options={}, &block)
				  block ||= ->{scope.one.call(self.GET.merge({'id' => 'new'}))}
			  		get("new", options, &block)
			  end

				def routes(*routes)
					routes = %w{ index show create update destroy edit new } if routes == [:all]
					routes.each { |route| self.send(route) }
				end
			end

		end

		register_plugin(:rest_api, RestApi)

	end
end