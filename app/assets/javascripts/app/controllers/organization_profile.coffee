class App.OrganizationProfile extends App.Controller
  constructor: (params) ->
    super

    # check authentication
    if !@authenticate()
      App.TaskManager.remove( @task_key )
      return

    # fetch new data if needed
    App.Organization.full( @organization_id, @render )

    # rerender view, e. g. on langauge change
    @bind 'ui:rerender', =>
      return if !@authenticate(true)
      @render( App.Organization.fullLocal( @organization_id ) )

  meta: =>
    meta =
      url: @url()
      id:  @organization_id

    if App.Organization.exists( @organization_id )
      organization = App.Organization.find( @organization_id )

      meta.head       = organization.displayName()
      meta.title      = organization.displayName()
      meta.iconClass  = organization.icon()

    meta

  url: =>
    '#organization/profile/' + @organization_id

  show: =>
    App.OnlineNotification.seen( 'Organization', @organization_id )
    @navupdate '#'

  changed: ->
    false

  render: (organization) =>

    if !@doNotLog
      @doNotLog = 1
      @recentView( 'Organization', @organization_id )

    @html App.view('organization_profile/index')(
      organization: organization
    )

    new Object(
      el:           @$('.js-object-container')
      organization: organization
    )

    new App.TicketStats(
      el:           @$('.js-ticket-stats')
      organization: organization
    )

    new App.UpdateTastbar(
      genericObject: organization
    )

class Object extends App.Controller
  events:
    'focusout [contenteditable]': 'update'

  constructor: (params) ->
    super

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = App.Organization.full( @organization.id, @render, false, true )

  release: =>
    App.Organization.unsubscribe(@subscribeId)

  render: (organization) =>

    # get display data
    organizationData = []
    for attributeName, attributeConfig of App.Organization.attributesGet('view')

      # check if value for _id exists
      name    = attributeName
      nameNew = name.substr( 0, name.length - 3 )
      if nameNew of organization
        name = nameNew

      # add to show if value exists
      if ( organization[name] || attributeConfig.tag is 'richtext' ) && attributeConfig.shown

        # do not show firstname and lastname / already show via diplayName()
        if name isnt 'name'
          organizationData.push attributeConfig

    @html App.view('organization_profile/object')(
      organization:     organization
      organizationData: organizationData
    )

    @$('[contenteditable]').ce({
      mode:      'textonly'
      multiline: true
      maxlength: 250
    })

    # start action controller
    showHistory = ->
      new App.OrganizationHistory(
        organization_id: organization.id
        container: @el.closest('.content')
      )
    editOrganization = =>
      new App.ControllerGenericEdit(
        id: organization.id
        genericObject: 'Organization'
        screen: 'edit'
        pageData:
          title: 'Organizations'
          object: 'Organization'
          objects: 'Organizations'
        container: @el.closest('.content')
      )

    actions = [
      {
        name:     'edit'
        title:    'Edit'
        callback: editOrganization
      }
      {
        name:     'history'
        title:    'History'
        callback: showHistory
      }
    ]

    new App.ActionRow(
      el:    @el.find('.js-action')
      items: actions
    )

  update: (e) =>
    name  = $(e.target).attr('data-name')
    value = $(e.target).html()
    org   = App.Organization.find( @organization.id )
    if org[name] isnt value
      data = {}
      data[name] = value
      org.updateAttributes( data )
      @log 'notice', 'update', name, value, org


class Router extends App.ControllerPermanent
  constructor: (params) ->
    super

    # cleanup params
    clean_params =
      organization_id:  params.organization_id

    App.TaskManager.execute(
      key:        'Organization-' + @organization_id
      controller: 'OrganizationProfile'
      params:     clean_params
      show:       true
    )

App.Config.set( 'organization/profile/:organization_id', Router, 'Routes' )
