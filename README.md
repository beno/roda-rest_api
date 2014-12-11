roda-rest-api
=============

Roda plugin for RESTful APIs

Run tests with

    bundle exec rake test

### Usage

```ruby
route do |r|
  r.api path:'', subdomain:'api' do   # 'mount' API on api.example.com/v1/..., default is /api/v1/...
    r.version 1 do

      r.resource :songs do
  			self.class.json_result_classes << Song
  			list   { |params| Song.find(params) }
  			one    { |params| Song[params['id']]	}
  			delete { |params| Song[params['id']].destroy }
  			save   { |attrs|  Song.create_or_update(attrs) }
  			r.routes :all
    	end

  		r.resource :artists do
  		  self.class.json_result_classes << Artist
  		  list   { |params| Artist.where(params) }
  		  one    { |params| Artist.find(params['id'].to_i)	}
  		  r.routes :index, :show
  		  r.create do
  		    # create artist
  		  end
        r.update do
  		    # update artist
  		  end
  		end

  		r.resource :albums do
  		  r.index do          # GET /v1/albums
  		    # list albums
  		  end
  		  r.create do         # POST /v1/albums
  		    # create album
  		  end
  		  r.show do |id|      # GET /v1/albums/:id
  		    # show album
  		  end
  		  r.update do |id|    # PATCH | PUT /v1/albums/:id
  		    # update album
  		  end
  		  r.destroy do |id|   # DELETE /v1/albums/:id
  		    # delete album
  		  end
  		  r.edit do |id|      # GET /v1/albums/:id/_edit
  		    # edit album
  		  end
  		  r.new do            # GET /v1/albums/_new
  		    # new album
  		  end
  		end

    end
  end
end
```
