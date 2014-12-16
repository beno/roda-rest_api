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
  
  plugin :rest_api
  
  route do |r|
    r.api do
      r.version 3 do
        r.resource :things do |things|
          things.list {|param| ['foo', 'bar']}
          things.routes :index
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

    curl http://127.0.0.1:9292/api/v3/things


### Usage

```ruby
route do |r|
  r.api path:'', subdomain:'api' do   # 'mount' on api.example.com/v1/...
    r.version 1 do

      #define all 7 routes:
      # index   - GET /v1/songs
      # show    - GET /v1/songs/:id
      # create  - POST /v1/songs
      # update  - PUT | PATCH /v1/songs/:id
      # destroy - DELETE /v1/songs/:id
      # edit    - GET /v1/songs/:id/edit
      # new     - GET /v1/songs/new
      
      r.resource :songs do |songs|
        songs.list   { |params| Song.where(params).all }            #index
        songs.one    { |params| Song[params['id']]  }          #show, edit, new
        songs.delete { |params| Song[params['id']].destroy }   #destroy
        songs.save   { |atts|  Song.create_or_update(atts) }  #create, update
      end

      #define 2 routes and custom serializer, custom primary key:
      # index   - GET /v1/artists
      # show    - GET /v1/artists/:id

      r.resource :artists, content_type: 'application/xml', primary_key: 'artist_id' do |artists|
        artists.list      { |params| Artist.where(params).all }
        artists.one       { |params| Artist.find(params['artist_id'])  }
        artists.serialize { |result| ArtistSerializer.xml(result) }
        artists.routes :index, :show
      end
      
      #define 6 singleton routes:
      # show    - GET /v1/profile
      # create  - POST /v1/profile
      # update  - PUT | PATCH /v1/profile
      # destroy - DELETE /v1/profile
      # edit    - GET /v1/profile/edit
      # new     - GET /v1/profile/new
      
      r.resource :profile, singleton: true do |profile|
        profile.one     { |params| current_user.profile  }                      #show, edit, new
        profile.save    { |atts| current_user.profile.create_or_update(atts)  } #create, update
        profile.delete  { |params| current_user.profile.destroy  }              #destroy
      end

      #nested routes
      # index   - GET /v1/albums/:parent_id/songs
      # show    - GET /v1/albums/:parent_id/songs/:id
      # index   - GET /v1/albums/:album_id/artwork
      # index   - GET /v1/albums/favorites
      # show    - GET /v1/albums/favorites/:id
      
      r.resource :albums do |albums|
        r.resource :songs do |songs|
          songs.list { |params| Song.where({ 'album_id' => params['parent_id'] }) }
          songs.one  { |params| Song[params['id']] 	}
          songs.routes :index, :show
        end
        r.resource :artwork, parent_key: 'album_id' do |artwork|
          artwork.list { |params| Artwork.where({ 'album_id' => params['album_id'] }).all }
          artwork.routes :index
        end
        r.resource :favorites, bare: true do |favorites|
          favorites.list  { |params| Favorite.where(params).all  }
          favorites.one   { |params| Favorite[params['id'] )  }
          favorites.routes :index, :show
        end
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

### Caveat

This plugin catches StandardError when performing the data access methods (list, one, save, delete) and will return a 404 or 422 response code when an error is thrown. This can be cumbersome in development, therefore you should develop and test your data access methods in isolation. This is good practice anyway.