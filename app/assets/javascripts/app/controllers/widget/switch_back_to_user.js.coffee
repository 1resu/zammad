class Widget extends App.ControllerWidgetOnDemand
  className: 'switchBackToUser'
  constructor: ->
    super

    # start widget
    @bind 'app:ready', =>
      @render()

    # e. g. if language has chnaged
    @bind 'ui:rerender', =>
      @render()

    # remove widget
    @bind 'auth:logout', =>
      App.Config.set('switch_back_to_possible', false)
      @render()

  render: (user) ->

    # if no switch to user is active
    if !App.Config.get('switch_back_to_possible') || !App.Session.get()
      @element().remove()
      return

    # show switch back widget
    @html App.view('widget/switch_back_to_user')()
    console.log('@el', @element())
    @element().on('click', '.js-close', (e) =>
      @switchBack(e)
    )

  switchBack: (e) =>
    e.preventDefault()
    @disconnectClient()
    $('#app').hide().attr('style', 'display: none!important')
    App.Auth._logout()
    window.location = App.Config.get('api_path') + '/sessions/switch_back'

App.Config.set( 'switch_back_to_user', Widget, 'Widgets' )
