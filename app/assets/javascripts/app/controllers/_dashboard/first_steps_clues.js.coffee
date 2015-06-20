class App.FirstStepsClues extends App.Controller
  clues: [
    {
      container: '.search-holder'
      headline: 'Suche'
      text: 'Um alles zu finden nutze den <kbd>*</kbd>-Platzhalter'
    }
    {
      container: '.user-menu'
      headline: 'Erstellen'
      text: 'Hier kannst du Tickets, Kunden und Organisationen anlegen.'
      actions: [
        'click .add .js-action',
        'hover .add'
      ]
    }
    {
      container: '.user-menu'
      headline: 'Persönliches Menü'
      text: 'Hier findest du den Logout, den Weg zu deinen Einstellungen und deinen Verlauf.'
      actions: [
        'click .user .js-action',
        'hover .user'
      ]
    }
    {
      container: '.main-navigation .overviews'
      headline: 'Übersichten'
      text: 'Hier findest du eine Liste aller Tickets.'
      actions: [
        'hover'
      ]
    }
    {
      container: '.main-navigation .dashboard'
      headline: 'Dashboard'
      text: 'Hier siehst du auf einem Blick ob sich alle Agenten an die Spielregeln halten.'
      actions: [
        'hover'
      ]
    }
  ]

  elements:
    '.js-positionOrigin': 'modalWindow'
    '.js-backdrop':       'backdrop'

  events:
    'click': 'stopPropagation'
    'click .js-next': 'next'
    'click .js-previous': 'previous'
    'click .js-close': 'close'

  constructor: ->
    super

    ###

    options
      clues: list of clues
      onComplete: a callback for when the user is done

    ###
    @el = $('body')
    @options.onComplete = -> null
    @position = 0
    @render()

  stopPropagation: (event) ->
    event.stopPropagation()

  next: (event) =>
    event.stopPropagation()
    @navigate 1

  previous: (event) =>
    event.stopPropagation()
    @navigate -1

  close: =>
    @cleanUp()
    @options.onComplete()
    @remove()

  remove: ->
    @$('.modal').remove()

  navigate: (direction) ->
    @cleanUp =>
      @position += direction

      if @position < @clues.length
        @showClue()
      else
        @options.onComplete()
        @remove()

  cleanUp: (callback) ->
    @hideWindow =>
      clue = @clues[@position]
      container = $(clue.container)
      container.removeClass('selected-clue')

      # undo click perform by doing it again
      if clue.actions
        @perform clue.actions, container

      callback()

  render: =>
    html = App.view('layout_ref/clues')
    console.log('HH', html)
    @el.append(html)
    #@modalWindow = $('.js-positionOrigin')
    #@backdrop = $('.js-backdrop')
    @backdrop.velocity
      properties:
        opacity: [1, 0]
      options:
        duration: 300
        complete: @showClue

  showClue: =>
    clue = @clues[@position]
    container = $(clue.container)
    container.addClass('selected-clue')
    console.log('showClue', clue, clue.container)
    if clue.actions
      @perform clue.actions, container

    # calculate bounding box after actions
    # to take toggled child nodes into account
    boundingBox = @getVisibleBoundingBox(container.get(0))

    center =
      x: boundingBox.left + boundingBox.width/2
      y: boundingBox.top + boundingBox.height/2

    @modalWindow.html App.view('layout_ref/clue_content')
      headline: clue.headline
      text: clue.text
      position: @position
      max: @clues.length

    @placeWindow(boundingBox)

    @backdrop.velocity
      properties:
        translateX: center.x
        translateY: center.y
        translateZ: 0
      options:
        duration: 300
        complete: @showWindow

  showWindow: =>
    @modalWindow.velocity
      properties: 
        scale: [1, 0.2]
        opacity: [1, 0]
      options:
        duration: 300
        easing: [0.34,1.61,0.7,1]

  hideWindow: (callback) =>
    @modalWindow.velocity
      properties: 
        scale: [0.2, 1]
        opacity: 0
      options:
        duration: 200
        complete: callback


  placeWindow: (target) ->
    # reset scale in order to get correct measurements
    $.Velocity.hook(@modalWindow, 'scale', 1)

    modal = @modalWindow.get(0).getBoundingClientRect()
    position = ''
    left = 0
    top = 0
    maxWidth = $(window).width()
    maxHeight = $(window).height()

    # try to place it parallel to the larger side
    if target.height > target.width
      # try to place it aside
      # prefer right
      if target.right + modal.width <= maxWidth
        left = target.right
        position = 'right'
      else 
        # place left
        left = target.left - modal.width
        position = 'left'

      if position
        top = target.top + target.height/2 - modal.height/2
    else if target.height <= target.width or !position
      # try to place it above or below
      # prefer above
      if target.top - modal.height >= 0
        top = target.top - modal.height
        position = 'above'
      else
        top = target.bottom
        position = 'below'

      if position
        left = target.left + target.width/2 - modal.width/2

    # keep it inside the window
    # horizontal
    if left < 0
      moveArrow = modal.width/2 + left
      left = 0
    else if left + modal.width > maxWidth
      moveArrow = modal.width/2 + maxWidth - (left + modal.width)
      left = maxWidth - modal.width

    if top < 0
      moveArrow = modal.height/2 + height
      top = 0
    else if top + modal.height > maxHeight
      moveArrow = modal.height/2 + maxHeight - (top + modal.height)
      top = maxHeight - modal.height

    transformOrigin = @getTransformOrigin(modal, position)

    if moveArrow
      parameter = if position is 'above' or position is 'below' then 'left' else 'top'
      # move arrow
      @modalWindow.find('.js-arrow').css(parameter, moveArrow)

      # adjust transform origin
      if position is 'above' or position is 'below'
        transformOrigin.x = moveArrow
      else
        transformOrigin.y = moveArrow

    # place window
    @modalWindow
      .attr 'data-position', position
      .css
        left: left
        top: top
        transformOrigin: "#{transformOrigin.x}px #{transformOrigin.y}px"

  getTransformOrigin: (modal, position) ->
    positionDictionary =
      above:
        x: modal.width/2
        y: modal.height
      below:
        x: modal.width/2
        y: 0
      left:
        x: modal.width + @transformOriginPadding
        y: modal.height/2
      right:
        x: -@transformOriginPadding
        y: modal.height/2

    return positionDictionary[position]

  getVisibleBoundingBox: (el) ->
    ###

      getBoundingClientRect doesn't take 
      absolute-positioned child nodes into account

    ###
    children = el.querySelectorAll('*')
    bb = el.getBoundingClientRect()
    dimensions =
      left: bb.left,
      right: bb.right,
      top: bb.top,
      bottom: bb.bottom

    for child in children

      continue if getComputedStyle(child).position is not 'absolute'

      bb = child.getBoundingClientRect()

      continue if bb.width is 0 or bb.height is 0

      if bb.left < dimensions.left
        dimensions.left = bb.left
      if bb.top < dimensions.top
        dimensions.top = bb.top
      if bb.right > dimensions.right
        dimensions.right = bb.right
      if bb.bottom > dimensions.bottom
        dimensions.bottom = bb.bottom

    dimensions.width = dimensions.right - dimensions.left
    dimensions.height = dimensions.bottom - dimensions.top

    dimensions

  perform: (actions, container) ->
    for action in actions
      if action.indexOf(" ") < 0
        # 'click'
        eventName = action
        target = container
      else
        # 'click .target'
        eventName = action.substr 0, action.indexOf(' ')
        target = container.find( action.substr action.indexOf(' ') + 1 )

      switch eventName
        when 'click' then target.trigger('click')
        when 'hover' then target.toggleClass('is-hovered')