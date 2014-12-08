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
				app.plugin :pass
				app.plugin :header_matchers
			end

			module RequestMethods
				
				def api(options={})
					api_path = options.delete(:path) || 'api'
					if api_path.length > 0
						on api_path, options do
							yield
						end
					else
						on options do
							yield
						end
					end
				end
				
				def version version
					on "v#{version}" do
						yield
					end
				end

				def resource name
					on name.to_s do
						yield
					end
				end
				
				def index(options={})
					is do
						pass if is_post?
						get do
							yield
						end
					end
					get "" do
						yield
					end
				end
				
				def show(options={})
					get ":d" do |id|
						yield id
					end
				end
				
				def create(options={})
					post do
						yield
					end
				end
								
				def update(options={})
					patch ":d" do |id|
						yield id
					end
					put ":d" do |id|
						yield id
					end
				end
				
				def destroy(options={})
					delete ":d" do |id|
						yield id
					end
				end
				
				def edit(options={})
					get ":d/_edit" do |id|
						yield id
					end
				end
				
				def new(options={})
					get "_new" do
						yield
					end
				end
				
				private
				
				def is_post?
					env['REQUEST_METHOD'] == 'POST'
				end
				
			end

		end
		
		register_plugin(:rest_api, RestApi)

	end
end