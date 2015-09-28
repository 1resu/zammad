class App.User extends App.Model
  @configure 'User', 'login', 'firstname', 'lastname', 'email', 'web', 'password', 'phone', 'fax', 'mobile', 'street', 'zip', 'city', 'country', 'organization_id', 'department', 'note', 'role_ids', 'group_ids', 'active', 'invite', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/users'

#  @hasMany 'roles', 'App.Role'
  @configure_attributes = [
    { name: 'login',            display: 'Login',         tag: 'input',    type: 'text',     limit: 100, null: false, autocapitalize: false, signup: false, quick: false },
    { name: 'firstname',        display: 'Firstname',     tag: 'input',    type: 'text',     limit: 100, null: false, signup: true, info: true, invite_agent: true },
    { name: 'lastname',         display: 'Lastname',      tag: 'input',    type: 'text',     limit: 100, null: false, signup: true, info: true, invite_agent: true },
    { name: 'email',            display: 'Email',         tag: 'input',    type: 'email',    limit: 100, null: false, signup: true, info: true, invite_agent: true },
    { name: 'organization_id',  display: 'Organization',  tag: 'select',   multiple: false, nulloption: true, null: true, relation: 'Organization', signup: false, info: true },
    { name: 'password',         display: 'Password',      tag: 'input',    type: 'password', limit: 50,  null: true, autocomplete: 'off', signup: true, },
    { name: 'note',             display: 'Note',          tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, null: true, info: true },
    { name: 'role_ids',         display: 'Roles',         tag: 'checkbox', multiple: true, null: false, relation: 'Role' },
    { name: 'group_ids',        display: 'Groups',        tag: 'checkbox', multiple: true, null: true, relation: 'Group', invite_agent: true },
    { name: 'active',           display: 'Active',        tag: 'active',   default: true },
    { name: 'created_at',       display: 'Created',       tag: 'datetime', readonly: 1 },
    { name: 'updated_at',       display: 'Updated',       tag: 'datetime', readonly: 1 },
  ]
  @configure_overview = [
#    'login', 'firstname', 'lastname', 'email', 'updated_at',
    'login', 'firstname', 'lastname',
  ]

  uiUrl: ->
    '#user/profile/' + @id

  icon: ->
    'user'

  initials: ->
    if @firstname && @lastname && @firstname[0] && @lastname[0]
      return @firstname[0] + @lastname[0]
    else if @firstname && @firstname[0] && !@lastname
      if @firstname[1]
        return @firstname[0] + @firstname[1]
      return @firstname[0]
    else if !@firstname && @lastname && @lastname[0]
      if @lastname[1]
        return @lastname[0] + @lastname[1]
      return @lastname[0]
    else if @email
      return @email[0] + @email[1]
    else
      return '??'

  avatar: (size = 40, placement = '', cssClass = '', unique = false, avatar, type = undefined) ->
    cssClass += " size-#{size}"

    if placement
      placement = "data-placement=\"#{placement}\""

    # use generated avatar
    if !@image || @image is 'none' || unique
      return @uniqueAvatar(size, placement, cssClass, avatar, type)

    # use image as avatar
    image = @imageUrl()
    vip = @vip
    if type is 'personal'
      vip = false
    else
      cssClass += ' user-popover'

    if vip
      return "<span class=\"avatar #{cssClass}\" data-id=\"#{@id}\" style=\"background-image: url(#{image})\" #{placement}><svg class='icon icon-crown'><use xlink:href='#icon-crown'></svg></span>"
    "<span class=\"avatar #{cssClass}\" data-id=\"#{@id}\" style=\"background-image: url(#{image})\" #{placement}></span>"

  uniqueAvatar: (size, placement = '', cssClass = '', avatar, type) ->
    width  = 300
    height = 226
    size   = parseInt(size, 10)
    vip    = @vip

    rng = new Math.seedrandom(@id)
    x   = rng() * (width - size)
    y   = rng() * (height - size)

    if !avatar
      if type is 'personal'
        vip = false
        data = "data-id=\"#{@id}\""
      else
        cssClass += ' user-popover'
        data      = "data-id=\"#{@id}\""
    else
      vip = false
      data = "data-avatar-id=\"#{avatar.id}\""

    if vip
      return "<span class=\"avatar unique #{cssClass}\" #{data} style=\"background-position: -#{ x }px -#{ y }px;\" #{placement}><svg class='icon icon-crown'><use xlink:href='#icon-crown'></svg>#{ @initials() }</span>"
    "<span class=\"avatar unique #{cssClass}\" #{data} style=\"background-position: -#{ x }px -#{ y }px;\" #{placement}>#{ @initials() }</span>"

  imageUrl: ->
    return if !@image
    # set image url
    @constructor.apiPath + '/users/image/' + @image

  @_fillUp: (data) ->

    # set socal media links
    if data['accounts']
      for account of data['accounts']
        if account == 'twitter'
          data['accounts'][account]['link'] = 'http://twitter.com/' + data['accounts'][account]['username']
        if account == 'facebook'
          data['accounts'][account]['link'] = 'https://www.facebook.com/profile.php?id=' + data['accounts'][account]['uid']

    if data.organization_id
      data.organization = App.Organization.find(data.organization_id)

    if data['role_ids']
      data['roles'] = []
      for role_id in data['role_ids']
        if App.Role.exists( role_id )
          role = App.Role.find( role_id )
          data['roles'].push role

    if data['group_ids']
      data['groups'] = []
      for group_id in data['group_ids']
        if App.Group.exists( group_id )
          group = App.Group.find( group_id )
          data['groups'].push group

    data

  searchResultAttributes: ->
    display:    "#{@displayName()}"
    id:         @id
    class:      'user user-popover'
    url:        @uiUrl()
    iconClass:  'user'
