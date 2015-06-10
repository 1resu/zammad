class Index extends App.Controller
  elements:
    '.js-search' : 'searchInput'
  events:
    'click [data-type="new"]':  'new'

  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    # set title
    @title 'Users', true

    @render()

  render: ->
    @html App.view('user')(
      head: 'Users'
      buttons: [
        { name: 'New User', 'data-type': 'new', class: 'btn--success' }
      ]
      roles: App.Role.all()
    )

    @$('.tab').on(
      'click'
      (e) =>
        e.preventDefault()
        $(e.target).toggleClass('active')
        term = @searchInput.val().trim()
        if term
          @delay( @search, 220, 'search' )
          return
        @recent()
    )

    # start search
    @searchInput.bind( 'keyup', (e) =>
      term = @searchInput.val().trim()
      return if !term
      return if term is @term
      @term = term
      @delay( @search, 220, 'search' )
    )

    # show last 20 users
    @recent()

  renderResult: (user_ids = []) ->

    callbackHeader = (header) ->
      attribute =
        name:       'switch_to'
        display:    'Action'
        translation: true
      header.push attribute
      header

    callbackAttributes = (value, object, attribute, header, refObject) ->
      text                  = App.i18n.translateInline("View from user's perspective")
      value                 = ' '
      attribute.raw         = ' <span class="btn btn--primary btn--table switchView"><svg class="icon icon-switchView"><use xlink:href="#icon-switchView" /></svg> ' + text + '</span>'
      attribute.class       = ''
      attribute.parentClass = 'no-padding'
      attribute.link        = ''
      attribute.title       = App.i18n.translateInline('Switch to')
      value

    switchTo = (id,e) =>
      e.preventDefault()
      @disconnectClient()
      $('#app').hide().attr('style', 'display: none!important')
      App.Auth._logout()
      window.location = App.Config.get('api_path') + '/sessions/switch/' + id

    edit = (id, e) =>
      e.preventDefault()
      item = App.User.find(id)

      rerender = =>
        @renderResult(user_ids)

      new App.ControllerGenericEdit(
        id:       item.id
        pageData:
          title:     'Users'
          home:      'users'
          object:    'User'
          objects:   'Users'
          navupdate: '#users'
        genericObject: 'User'
        callback: rerender
      )

    users = []
    for user_id in user_ids
      user = App.User.find(user_id)
      users.push user

    @$('.table-overview').html('')
    new App.ControllerTable(
      el:       @$('.table-overview')
      model:    App.User
      objects:  users
      class:    'user-list'
      callbackHeader:   callbackHeader
      callbackAttributes:
        switch_to: [
          callbackAttributes
        ]
      bindCol:
        switch_to:
          events:
            'click': switchTo
      bindRow:
        events:
          'click': edit
    )

  search: =>
    role_ids = []
    @$('.tab.active').each( (i,d) ->
      role_ids.push $(d).data('id')
    )
    App.Ajax.request(
      id:    'search'
      type:  'GET'
      url:   @apiPath + '/users/search'
      data:
        term:  @term
        limit: 140
        role_ids: role_ids
        full:  1
      processData: true,
      success: (data, status, xhr) =>

        # load assets
        App.Collection.loadAssets( data.assets )

        @renderResult(data.user_ids)
    )

  recent: =>
    role_ids = []
    @$('.tab.active').each( (i,d) ->
      role_ids.push $(d).data('id')
    )
    App.Ajax.request(
      id:    'search'
      type:  'GET'
      url:   @apiPath + '/users/recent'
      data:
        limit: 40
        role_ids: role_ids
        full:  1
      processData: true,
      success: (data, status, xhr) =>

        # load assets
        App.Collection.loadAssets( data.assets )

        @renderResult(data.user_ids)
    )

  new: (e) ->
    e.preventDefault()
    new App.ControllerGenericNew(
      pageData:
        title:     'Users'
        home:      'users'
        object:    'User'
        objects:   'Users'
        navupdate: '#users'
      genericObject: 'User'
    )

App.Config.set( 'User', { prio: 1000, name: 'Users', parent: '#manage', target: '#manage/users', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )