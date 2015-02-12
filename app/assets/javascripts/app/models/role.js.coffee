class App.Role extends App.Model
  @configure 'Role', 'name', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/roles'
  @configure_attributes = [
    { name: 'name',           display: 'Name',        tag: 'input',   type: 'text', limit: 100, null: false },
    { name: 'note',           display: 'Note',        tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, null: true },
    { name: 'active',         display: 'Active',      tag: 'active',  default: true },
    { name: 'created_by_id',  display: 'Created by',  relation: 'User', readonly: 1 },
    { name: 'created_at',     display: 'Created',     tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',  display: 'Updated by',  relation: 'User', readonly: 1 },
    { name: 'updated_at',     display: 'Updated',     tag: 'datetime', readonly: 1 },
  ]
  @configure_overview = [
    'name',
  ]
