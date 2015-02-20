# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class PostmasterFiltersController < ApplicationController
  before_filter :authentication_check

=begin

Format:
JSON

Example:
{
  "id":1,
  "name":"some name",
  "type":"email",
  "match":{
    "From":"some@example.com"
  },
  "perform":{
    "x-zammad-ticket-priority":"3 high"
  },
  "note":"",
  "active":true,
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "updated_by_id":2,
  "created_by_id":2,
}

=end

=begin

Resource:
GET /api/v1/postmaster_filters.json

Response:
[
  {
    "id": 1,
    "name":"some name",
    ...
  },
  {
    "id": 2,
    "name":"some name",
    ...
  }
]

Test:
curl http://localhost/api/v1/postmaster_filters.json -v -u #{login}:#{password}

=end

  def index
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_index_render(PostmasterFilter, params)
  end

=begin

Resource:
GET /api/v1/postmaster_filters/#{id}.json

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/v1/postmaster_filters/#{id}.json -v -u #{login}:#{password}

=end

  def show
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_show_render(PostmasterFilter, params)
  end

=begin

Resource:
POST /api/v1/postmaster_filters.json

Payload:
{
  "name":"some name",
  "type":"email",
  "match":{
    "From":"some@example.com"
  },
  "perform":{
    "x-zammad-ticket-priority":"3 high"
  },
  "note":"",
  "active":true,
}

Response:
{
  "id": 1,
  "name":"some name",
  "type":"email",
  "match":{
    "From":"some@example.com"
  },
  "perform":{
    "x-zammad-ticket-priority":"3 high"
  },
  "note": "",
  "active":true,
  ...
}

Test:
curl http://localhost/api/v1/postmaster_filters.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def create
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_create_render(PostmasterFilter, params)
  end

=begin

Resource:
PUT /api/v1/postmaster_filters/{id}.json

Payload:
{
  "name":"some name",
  "match":{
    "From":"some@example.com"
  },
  "perform":{
    "x-zammad-ticket-priority":"3 high"
  },
  "note":"",
  "active":true,
}

Response:
{
  "id": 1,
  "name":"some name",
  "match":{
    "From":"some@example.com"
  },
  "perform":{
    "x-zammad-ticket-priority":"3 high"
  },
  "note":"",
  "active":true,
  ...
}

Test:
curl http://localhost/api/v1/postmaster_filters.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_update_render(PostmasterFilter, params)
  end

=begin

Resource:

Response:

Test:

=end

  def destroy
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_destory_render(PostmasterFilter, params)
  end
end
