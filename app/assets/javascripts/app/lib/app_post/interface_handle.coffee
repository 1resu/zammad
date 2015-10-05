class App.Run extends App.Controller
  constructor: ->
    super
    @el = $('#app')

    App.Event.trigger('app:init')

    # browser check
    if !App.Browser.check()
      return

    # hide splash screen
    $('.splash').hide()

    # init collections
    App.Collection.init()

    # check if session already exists/try to get session data from server
    App.Auth.loginCheck()

    # create web socket connection
    App.WebSocket.connect()

    # start frontend time update
    @frontendTimeUpdate()

    # start navbars
    @setupWidget( 'Navigations', 'nav', @el )

    # start widgets
    @setupWidget( 'Widgets', 'widget', @el )

    # bind to fill selected text into
    App.ClipBoard.bind( @el )

    App.Event.trigger('app:ready')

  setupWidget: (config, event, el) ->

    # start widgets
    App.Event.trigger(event + ':init')
    widgets = App.Config.get(config)
    if widgets
      for key, widget of widgets
        new widget(
          el:  el
          key: key
        )
    App.Event.trigger(event + ':ready')

class App.Content extends App.ControllerWidgetPermanent
  className: 'content flex horizontal'

  constructor: ->
    super

    Routes = @Config.get('Routes')
    for route, callback of Routes
      do (route, callback) =>
        @route(route, (params) ->

          @log 'debug', 'execute page controller', route, params

          # remove events for page
          App.Event.unbindLevel('page')

          # remove delay for page
          App.Delay.clearLevel('page')

          # remove interval for page
          App.Interval.clearLevel('page')

          # unbind in controller area
          @el.unbind()
          @el.undelegate()

          # send current controller
          params_only = {}
          for i of params
            if typeof params[i] isnt 'object'
              params_only[i] = params[i]

          # tell server what we are calling right now
          App.WebSocket.send(
            action:     'active_controller',
            controller: route,
            params:     params_only,
          )

          # remember history
          # needed to mute "redirect" url to support browser back
          history = App.Config.get('History')
          if history[10]
            history.shift()
          history.push window.location.hash

          # execute controller
          controller = (params) =>
            params.el = @el
            new callback(params)
          controller(params)
        )

    Spine.Route.setup()

App.Config.set( 'content', App.Content, 'Widgets' )
