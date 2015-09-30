class App.PrettyDate

  # human readable time
  @humanTime: ( time, escalation, long = true ) ->
    return '' if !time
    current = new Date()
    created = new Date(time)
    diff = ( current - created ) / 1000

    escalated = ''
    if escalation
      if diff > 0
        escalated = '-'
      if diff >= 0
        style = 'class="label label-danger"'
      else if diff > -60 * 60
        style = 'class="label label-warning"'

    # remember past/future
    direction = 'future'
    if diff > -1
      direction = 'past'

    # strip not longer needed -
    if diff.toString().match('-')
      diff = diff.toString().replace('-', '')
      diff = parseFloat(diff)

    if direction is 'past' && !escalation && diff > ( 60 * 60 * 24 * 14 )
      return App.i18n.translateDate(time)

    # days
    string = ''
    count = 0
    if diff >= 86400
      count++
      unit = Math.floor( ( diff / 86400 ) )
      day = App.i18n.translateInline('d')
      if long
        if unit > 1 || unit is 0
          day = App.i18n.translateContent('days')
        else
          day = App.i18n.translateContent('day')
      string = unit + ' ' + day
      diff = diff - ( unit * 86400 )
      if unit >= 9 || diff < 3600 || count is 2
        if direction is 'past'
          string = App.i18n.translateInline('%s ago', string)
        else
          string = App.i18n.translateInline('in %s', string)
        if escalation
          string = "<span #{style}>#{string}</b>"
        return string

    # hours
    if diff >= 3600
      count++
      unit = Math.floor( ( diff / 3600 ) % 24 )
      hour = App.i18n.translateInline('h')
      if long
        if unit > 1 || unit is 0
          hour = App.i18n.translateInline('hours')
        else
          hour = App.i18n.translateInline('hour')
      if string isnt ''
        string = string + ' '
      string = string + unit + ' ' + hour
      diff = diff - ( unit * 3600 )
      if unit >= 9 || diff < 60 || count is 2
        if direction is 'past'
          string = App.i18n.translateInline('%s ago', string)
        else
          string = App.i18n.translateInline('in %s', string)
        if escalation
          string = "<span #{style}>#{string}</b>"
        return string

    # minutes
    unit = Math.floor( ( diff / 60 ) % 60 )
    minute = App.i18n.translateInline('m')
    if long
      if unit > 1 || unit is 0
        minute = App.i18n.translateContent('minutes')
      else
        minute = App.i18n.translateContent('minute')
    if string isnt ''
      string = string + ' '
    string = string + unit + ' ' + minute
    if direction is 'past'
      string = App.i18n.translateInline('%s ago', string)
    else
      string = App.i18n.translateInline('in %s', string)
    if escalation
      string = "<span #{style}>#{string}</b>"
    return string
