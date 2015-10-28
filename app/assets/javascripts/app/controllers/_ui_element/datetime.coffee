# coffeelint: disable=camel_case_classes
class App.UiElement.datetime
  @render: (attributeOrig) ->

    attribute = _.clone(attributeOrig)
    attribute.nameRaw = attribute.name
    attribute.name = "{datetime}#{attribute.name}"

    item = $( App.view('generic/datetime')(
      attribute: attribute
    ) )

    # set our custom template
    $.fn.datepicker.defaults.template = App.view('generic/datepicker')()

    # apply date widgets
    $.fn.datepicker.dates['custom'] =
      days: [App.i18n.translateInline('Sunday'), App.i18n.translateInline('Monday'), App.i18n.translateInline('Tuesday'), App.i18n.translateInline('Wednesday'), App.i18n.translateInline('Thursday'), App.i18n.translateInline('Friday'), App.i18n.translateInline('Saturday'), App.i18n.translateInline('Sunday')],
      daysShort: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      daysMin: [App.i18n.translateInline('Su'), App.i18n.translateInline('Mo'), App.i18n.translateInline('Tu'), App.i18n.translateInline('We'), App.i18n.translateInline('Th'), App.i18n.translateInline('Fr'), App.i18n.translateInline('Sa'), App.i18n.translateInline('Su')],
      months: [App.i18n.translateInline('January'), App.i18n.translateInline('February'), App.i18n.translateInline('March'), App.i18n.translateInline('April'), App.i18n.translateInline('May'), App.i18n.translateInline('June'), App.i18n.translateInline('July'), App.i18n.translateInline('August'), App.i18n.translateInline('September'), App.i18n.translateInline('October'), App.i18n.translateInline('November'), App.i18n.translateInline('December')],
      monthsShort: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
      today: App.i18n.translateInline('today'),
      clear: App.i18n.translateInline('clear')
    currentDate = undefined
    if attribute.value
      startDate = new Date(attribute.value)
    item.find('.js-datepicker').datepicker(
      weekStart: 1
      autoclose: true
      todayBtn: 'linked'
      todayHighlight: true
      #startDate: startDate
      format: App.i18n.timeFormat().date
      container: item
      language: 'custom'
    )

    # set initial date time
    @setNewTimeInitial(item, attribute)

    # apply time widgets
    item.find('.js-timepicker').timepicker()

    # observer changes
    item.find('input').bind('keyup blur focus change', (e) =>
      @setNewTime(item, attribute, 0)
      @validation(item, attribute, true)
    )
    item.bind('validate', (e) =>
      @validation(item, attribute)
    )

    item

  @setNewTime: (item, attribute, tolerant = false) ->

    datetime = item.find('.js-datepicker').datepicker('getDate')
    if !datetime || datetime.toString() is 'Invalid Date'
      App.Log.debug 'UiElement.datetime.setNewTime', datetime
      item.find("[name=\"#{attribute.name}\"]").val('')
      return

    App.Log.debug 'UiElement.datetime.setNewTime', datetime
    year  = datetime.getFullYear()
    month = datetime.getMonth() + 1
    day   = datetime.getDate()
    date  = "#{App.Utils.formatTime(year)}-#{App.Utils.formatTime(month,2)}-#{App.Utils.formatTime(day,2)}"
    time  = item.find('.js-timepicker').val()

    if date is '' || time is ''
      item.find("[name=\"#{attribute.name}\"]").val('')
      return

    timestamp = "#{date}T#{time}:00.000Z"
    time = new Date( Date.parse(timestamp) )
    time.setMinutes( time.getMinutes() + time.getTimezoneOffset() )
    App.Log.debug 'UiElement.datetime.setNewTime', time.toString()
    timestamp = time.toISOString().replace(/\d\d\.\d\d\dZ$/, '00.000Z')
    item.find("[name=\"#{attribute.name}\"]").val(timestamp)

  @setNewTimeInitial: (item, attribute) ->
    App.Log.debug 'UiElement.datetime.setNewTimeInitial', timestamp
    timestamp = item.find("[name=\"#{attribute.name}\"]").val()
    if !timestamp
      item.find('.js-timepicker').val('08:00')
      return

    timeObject = new Date( Date.parse( timestamp ) )

    hour   = timeObject.getHours()
    minute = timeObject.getMinutes()
    time   = "#{App.Utils.formatTime(hour,2)}:#{App.Utils.formatTime(minute,2)}"

    App.Log.debug 'UiElement.datetime.setNewTimeInitial', timestamp, timeObject
    item.find('.js-datepicker').datepicker('setUTCDate', timeObject)
    item.find('.js-timepicker').val(time)

  @validation: (item, attribute, runtime) ->

    # remove old validation
    item.closest('.form-group').removeClass('has-error')
    item.find('.has-error').removeClass('has-error')
    item.find('.help-inline').html('')
    item.closest('.form-group').find('.help-inline').html('')

    timestamp = item.find("[name=\"#{attribute.name}\"]").val()

    # check required attributes
    errors = {}
    if !timestamp
      if !attribute.null
        errors[attribute.name] = 'missing'
    else
      timeObject = new Date( Date.parse( timestamp ) )


    formGroup = item.closest('.form-group')
    App.Log.debug 'UiElement.datetime.validation', errors
    return if _.isEmpty(errors)

    # show invalid options
    for key, value of errors
      formGroup.addClass('has-error')
