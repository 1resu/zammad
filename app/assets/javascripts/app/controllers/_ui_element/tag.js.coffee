class App.UiElement.tag
  @render: (attribute) ->
    item = $( App.view('generic/input')( attribute: attribute ) )
    a = =>
      $('#' + attribute.id ).tokenfield()
      $('#' + attribute.id ).parent().css('height', 'auto')
    App.Delay.set( a, 120, undefined, 'tags' )
    item