class Index extends App.ControllerContent
  events:
    'submit form': 'submit'
    'click .submit': 'submit'
    'click .cancel': 'cancel'

  constructor: ->
    super

    # go back if feature is not enabled
    if !@Config.get('user_create_account')
      @navigate '#'
      return

    @navHide()

    # set title
    @title 'Sign up'
    @navupdate '#signup'

    @render()

  render: ->

    # set password as required
    for item in App.User.configure_attributes
      if item.name is 'password'
        item.null = false

    @html App.view('signup')()

    new App.ControllerForm(
      el:        @el.find('form')
      model:     App.User
      required:  'signup'
      autofocus: true
    )

  cancel: ->
    @navigate '#login'

  submit: (e) ->
    e.preventDefault()
    @formDisable(e)
    @params = @formParam(e.target)

    # if no login is given, use emails as fallback
    if !@params.login && @params.email
      @params.login = @params.email

    @params.role_ids = [0]
    @log 'notice', 'updateAttributes', @params
    user = new App.User
    user.load(@params)

    errors = user.validate()
    if errors
      @log 'error new', errors
      @formValidate( form: e.target, errors: errors )
      @formEnable(e)
      return false

    # save user
    user.save(
      done: (r) =>
        App.Auth.login(
          data:
            username: @params.login
            password: @params.password
          success: @success
          error: @error
        )
#      fail: =>
#        @modalHide()
    )

  success: (data, status, xhr) =>

    # login check
    App.Auth.loginCheck()

    # add notify
    @notify
      type:      'success'
      msg:       'Thanks for joining. Email sent to "' + @params.email + '". Please verify your email address.'
      removeAll: true

    # redirect to #
    @navigate '#'

  error: (xhr, statusText, error) =>

    # add notify
    @notify
      type:      'warning'
      msg:       'Wrong Username and Password combination.'
      removeAll: true

App.Config.set( 'signup', Index, 'Routes' )
