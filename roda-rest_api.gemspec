Gem::Specification.new do |s|
	s.name        = 'roda-rest_api'
	s.version     = '1.3.1'
	s.date        = '2014-12-14'
	s.summary     = "REST APIs with Roda"
	s.description = "A Roda plugin for RESTful APIs"
	s.authors     = ["Michel Benevento"]
	s.email       = 'michelbenevento@yahoo.com'
	s.files       = ["lib/roda/rest_api.rb", "lib/roda/plugins/rest_api.rb"]
	s.homepage    = 'http://github.com/beno/roda-rest_api'
	s.license     = 'MIT'
	
	s.add_runtime_dependency 'roda', '~> 1.2'

	s.add_development_dependency 'rake', '~> 10'
	s.add_development_dependency 'minitest', '~> 5.5'
	s.add_development_dependency 'rack-test', '~> 0.6'

end