Roda plugin for RESTful APIs
=============

### Quick start

Install gem with

    gem 'roda-rest_api'          #Gemfile

or

    gem install roda-rest_api    #Manual

Create rack app 

```ruby
#api.ru

require 'roda/rest_api'
require 'json'

class App < Roda
  route do |r|
    r.api do
      r.version 3 do
        r.resource :things do |rsc|
          rsc.list {|param| ['foo', 'bar']}
          rsc.routes :index
        end
      end
    end
  end
end

run App
```
    
And run with

    bundle exec rackup api.ru

Try it out on:

    curl http://localhost:9292/api/v3/things


### Usage

```ruby
route do |r|
  r.api path:'', subdomain:'api' do   # 'mount' API on api.example.com/v1/..., default is /api/v1/...
    r.version 1 do

      #define all 7 routes
      
      r.resource :songs do |rsc|
        rsc.list   { |params| Song.find(params) }            #index
        rsc.one    { |params| Song[params['id']]  }          #show, edit, new
        rsc.delete { |params| Song[params['id']].destroy }   #destroy
        rsc.save   { |attrs|  Song.create_or_update(attrs) } #create, update
      end

      #define 2 routes and custom serializer, custom primary key

      r.resource :artists, content_type: 'application/xml', primary_key: 'artist_id' do |rsc|
        rsc.list   { |params| Artist.where(params) }
        rsc.one    { |params| Artist.find(params['artist_id'])  }
        rsc.serialize { |result| ArtistSerializer.xml(result) }
        rsc.routes :index, :show
      end
      
      #define 6 singleton routes
      
      r.resource :profile, singleton: true do |rsc|
        rsc.one     { |params| current_user.profile  }                      #show, edit, new
        rsc.save    { |atts| current_user.profile.create_or_update(atts)  } #create, update
        rsc.delete  { |params| current_user.profile.destroy  }              #destroy
      end
      
      #define custom routes
      
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
        r.edit do |id|      # GET /v1/albums/:id/edit
          # edit album
        end
        r.new do            # GET /v1/albums/new
          # new album
        end
      end

    end
  end
end
```
