# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class GroupsController < ApplicationController
  before_action :authentication_check

=begin

Format:
JSON

Example:
{
  "id":1,
  "name":"some group",
  "assignment_timeout": null,
  "follow_up_assignment": true,
  "follow_up_possible": "yes",
  "note":"",
  "active":true,
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "created_by_id":2,
}

=end

=begin

Resource:
GET /api/v1/groups.json

Response:
[
  {
    "id": 1,
    "name": "some_name1",
    ...
  },
  {
    "id": 2,
    "name": "some_name2",
    ...
  }
]

Test:
curl http://localhost/api/v1/groups.json -v -u #{login}:#{password}

=end

  def index
    model_index_render(Group, params)
  end

=begin

Resource:
GET /api/v1/groups/#{id}.json

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/v1/groups/#{id}.json -v -u #{login}:#{password}

=end

  def show
    model_show_render(Group, params)
  end

=begin

Resource:
POST /api/v1/groups.json

Payload:
{
  "name": "some name",
  "assignment_timeout": null,
  "follow_up_assignment": true,
  "follow_up_possible": "yes",
  "note":"",
  "active":true,
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/groups.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def create
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_create_render(Group, params)
  end

=begin

Resource:
PUT /api/v1/groups/{id}.json

Payload:
{
  "name": "some name",
  "assignment_timeout": null,
  "follow_up_assignment": true,
  "follow_up_possible": "yes",
  "note":"",
  "active":true,
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/groups.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_update_render(Group, params)
  end

=begin

Resource:

Response:

Test:

=end

  def destroy
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_destory_render(Group, params)
  end
end
