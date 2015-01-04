class Index extends App.Controller
  events:
    'submit form': 'update'

  constructor: ->
    super
    return if !@authenticate()
    @render()

  render: =>

    html = $( App.view('profile/language')() )

    configure_attributes = [
      { name: 'locale', display: '', tag: 'select', null: false, class: 'input', options: { de: 'Deutsch', en: 'English (United States)', 'en-CA': 'English (Canada)', 'en-GB': 'English (United Kingdom)' }, default: App.i18n.get()  },
    ]

    @form = new App.ControllerForm(
      el:        html.find('.language_item')
      model:     { configure_attributes: configure_attributes }
      autofocus: false
    )
    @html html

  update: (e) =>
    e.preventDefault()
    params = @formParam(e.target)
    error  = @form.validate(params)
    if error
      @formValidate( form: e.target, errors: error )
      return false

    @formDisable(e)

    # get data
    @locale = params['locale']
    @ajax(
      id:          'preferences'
      type:        'PUT'
      url:         @apiPath + '/users/preferences'
      data:        JSON.stringify({user:params})
      processData: true
      success:     @success
      error:       @error
    )

  success: (data, status, xhr) =>
    App.User.full(
      App.Session.get( 'id' ),
      =>
        App.i18n.set( @locale )
        App.Event.trigger( 'ui:rerender' )
        App.Event.trigger( 'ui:page:rerender' )
        @notify(
          type: 'success'
          msg:  App.i18n.translateContent( 'Successfully!' )
        )
      ,
      true
    )

  error: (xhr, status, error) =>
    @render()
    data = JSON.parse( xhr.responseText )
    @notify(
      type: 'error'
      msg:  App.i18n.translateContent( data.message )
    )

App.Config.set( 'Language', { prio: 1000, name: 'Language', parent: '#profile', target: '#profile/language', controller: Index }, 'NavBarProfile' )