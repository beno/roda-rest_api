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
      
      # call permit to whitelist allowed parameters for save callback
      
      r.resource :songs do |songs|
        songs.list   { |params| Song.where(params).all }      #index
        songs.one    { |params| Song[params[:id]]  }          #show, edit, new
        songs.delete { |params| Song[params[:id]].destroy }   #destroy
        songs.save   { |atts|  Song.create_or_update(atts) }  #create, update
        songs.permit :title, author: [:name, :address]
      end

      #define 2 routes and custom serializer, custom primary key:
      # index   - GET /v1/artists
      # show    - GET /v1/artists/:id

      r.resource :artists, content_type: 'application/xml', primary_key: :artist_id do |artists|
        artists.list      { |params| Artist.where(params).all }
        artists.one       { |params| Artist[params[:artist_id]]  }
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
        profile.permit :name, :address
      end

      #define nested routes
      # index   - GET /v1/albums/:parent_id/songs
      # show    - GET /v1/albums/:parent_id/songs/:id
      # index   - GET /v1/albums/:album_id/artwork
      # index   - GET /v1/albums/favorites
      # show    - GET /v1/albums/favorites/:id
      
      r.resource :albums do |albums|
        r.resource :songs do |songs|
          songs.list { |params| Song.where({ :album_id => params[:parent_id] }) }
          songs.one  { |params| Song[params[:id]] 	}
          songs.routes :index, :show
        end
        r.resource :artwork, parent_key: :album_id do |artwork|
          artwork.list { |params| Artwork.where({ :album_id => params[:album_id] }).all }
          artwork.routes :index
        end
        r.resource :favorites, bare: true do |favorites|
          favorites.list  { |params| Favorite.where(params).all  }
          favorites.one   { |params| Favorite[params[:id]] )  }
          favorites.routes :index, :show
        end
      end
      
      #call block before route is called
      
      r.resource :user, singleton: true do |user|
        user.save {|atts| User.create_or_update(atts) }
        user.routes :create    # public
        user.routes :update do # private
          authenticate!
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

###Option

The plugin supports the options serialize, content_type, wrapper and id_pattern to modify processing of the request. Besides these, any number of custom options can be passed, which can be handy for the wrapper option.
Each option can be specified and overridden at the api, version or resource level.

####Serialization and content type

A serialization block is called with the query result and is supposed to return a string. The content type can be specified accordingly.

```
class App < Roda
    
  plugin :rest_api

  route do |r|
    r.api serialize: ->(result){ result.to_xml }, content_type: 'text/xml'
      r.resource :things do |things|
        things.list {|param| ['foo', 'bar']}
        things.routes :index
      end
      r.resource :objects, serialize: ->(result){ result.to_json }, content_type: 'application/json' do |objects|
        objects.one {|param| Object.find(param) }
        objects.routes :show
      end
      r.resource :items do |items|
        items.list {|param| Item.where(param) }
        items.routes :index
        items.serialize content_type: 'text/plain' do |result| #inline specification
          result.to_s
        end
      end

    end
  end
end
```

####Wrapper

A wrapper module can be specified, containing one or more 'around_*' methods. These methods should yield with the passed arguments. Wrappers can be used for cleaning up parameters, database transactions, authorization checking or serialization. It is often useful to set a custom option like model_class on a resource when using wrappers.

```

module Wrapper

  def around_save(atts)
    # actions before save
    result = yield(atts)
    #actions after save
    result
  end
  
  # around_one, around_list, around_delete
end

module SpecialWrapper

  def around_delete(atts)
    model_class = opts[:model_class]
    if request.current_user.can_delete(model_class[atts[:id]])
      yield(atts)
    else
      #not allowed
    end
  end

end

class App < Roda

  plugin :rest_api

  route do |r|
    r.api wrapper: Wrapper
      r.resource :things do |things|
        things.one {|params| Thing.find(params) }          # will be called inside the 'Wrapper#around_one' method
        things.list {|params| Thing.where(params) }        # will be called inside the 'Wrapper#around_list' method
        things.save {|atts| Thing.create_or_update(atts) } # will be called inside the 'Wrapper#around_save' method
        things.delete {|params| Thing.destroy(params) }    # will be called inside the 'Wrapper#around_delete' method
      end
      r.resource :items, wrapper: SpecialWrapper, model_class: Item do |items|
        items.delete {|params| Item.destroy(params) }    # will be called inside the 'SpecialWrapper#around_delete' method
      end

    end
  end
end
```

####ID pattern

To support various id formats, one of the symbol_matcher symbols or a regex can be specified to match custom id formats.
The plugin adds the :uuid symbol for 8-4-4-4-12 formatted UUIDs.

```
  r.api id_pattern: :uuid
    r.resource :things do |things|
      things.one {|params| Thing.find(params) }
      r.resource :parts, id_pattern: /part(\d+)/ do |parts|
        parts.one {|params| Part.find(params) }
      end

    end
  end
  
  # responds to /things/7e554915-210b-4dxe-a88b-3a09a5e790ge/parts/part123



### Caveat

This plugin catches StandardError when performing the data access methods (list, one, save, delete) and will return a 404 or 422 response code when an error is thrown. When ENV['RACK_ENV'] is set to 'development' the error will be raised, but in all other cases it will fail silently. Be aware that ENV['RACK_ENV'] may be blank, so you won't see any errors even in development. A better approach is to develop and test the data access methods in isolation.