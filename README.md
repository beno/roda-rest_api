roda-rest-api
=============

Roda plugin for RESTful APIs

Run tests with

    bundle exec rake test
    
### Usage

    route do |r|
      r.api path:'', subdomain:'api' do #default path is 'api'
        r.version 1 do
          r.resource :albums do
      	      r.index do
      		      # list albums
      			  end
      			  r.create do
      			    # create album
            end
      			  r.show do |id|
      			    # show album
      			  end
      			  r.update do |id|
      			    # update album
      			  end
      			  r.destroy do |id|
      			    # delete album
      			  end
      			  r.edit do |id|
      			    # edit album
      			  end
      			  r.new do
      			    # new album
      			  end
      			end
      		end
      	end
    end
