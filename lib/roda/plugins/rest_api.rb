class Roda
	module RodaPlugins
		module RestApi
			def self.load_dependencies(app, _opts = {})
				app.plugin :all_verbs
				app.plugin :symbol_matchers
				app.plugin :pass
			end
			
			module RequestMethods
				
				def resource name
					on name.to_s do
						yield
					end
				end
				
				def index options:{}
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
				
				def show options:{}
					get ":d" do |id|
						yield id
					end
				end
				
				def create options:{}
					post do
						yield
					end
				end
								
				def update options:{}
					patch ":d" do |id|
						yield id
					end
					put ":d" do |id|
						yield id
					end
				end
				
				def destroy options:{}
					delete ":d" do |id|
						yield id
					end
				end
				
				def edit options:{}
					get ":d/_edit" do |id|
						yield id
					end
				end
				
				def new options:{}
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