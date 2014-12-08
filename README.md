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
            r.update do |id|    # PATCH /v1/albums/:id or PUT /albums/:id
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