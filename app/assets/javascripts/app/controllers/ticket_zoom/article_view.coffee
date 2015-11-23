class App.TicketZoomArticleView extends App.Controller
  constructor: ->
    super

    @article_controller = {}

  execute: (params) ->
    all = []
    for ticket_article_id in params.ticket_article_ids
      if !@article_controller[ticket_article_id]
        el = $('<div></div>')
        @article_controller[ticket_article_id] = new ArticleViewItem(
          ticket:            @ticket
          ticket_article_id: ticket_article_id
          el:                el
          ui:                @ui
          highligher:        @highligher
        )
        all.push el
    @el.append( all )

class ArticleViewItem extends App.Controller
  hasChangedAttributes: ['from', 'to', 'cc', 'subject', 'body', 'preferences']

  elements:
    '.textBubble-content':           'textBubbleContent'
    '.textBubble-overflowContainer': 'textBubbleOverflowContainer'

  events:
    'click .show_toogle':          'show_toogle'
    'click .textBubble':           'toggle_meta_with_delay'
    'click .textBubble a':         'stopPropagation'
    'click .js-unfold':            'unfold'

  constructor: ->
    super

    @seeMore = false

    @render()

    # set expand of text area only once
    @bind('ui::ticket::shown', (data) =>
      return if data.ticket_id.toString() isnt @ticket.id.toString()

      # set highlighter
      @setHighlighter()

      # set see more
      @setSeeMore()
    )

    # rerender, e. g. on language change
    @bind('ui:rerender', =>
      @render(undefined, true)
    )

    # subscribe to changes
    @subscribeId = App.TicketArticle.full(@ticket_article_id, @render, false, true)

  release: =>
    App.TicketArticle.unsubscribe(@subscribeId)

  setHighlighter: =>
    return if @el.is(':hidden')
    # use delay do no ui blocking
    #@highligher.loadHighlights(@ticket_article_id)
    d = =>
      @highligher.loadHighlights(@ticket_article_id)
    @delay(d, 200)

  hasChanged: (article) =>

    # if no last article exists, remember it and return true
    if !@articleAttributesLastUpdate
      @articleAttributesLastUpdate = {}
      for item in @hasChangedAttributes
        @articleAttributesLastUpdate[item] = article[item]
      return true

    # compare last and current article attributes
    articleAttributesLastUpdateCheck = {}
    for item in @hasChangedAttributes
      articleAttributesLastUpdateCheck[item] = article[item]
    diff = difference(@articleAttributesLastUpdate, articleAttributesLastUpdateCheck)
    return false if !diff || _.isEmpty( diff )
    @articleAttributesLastUpdate = articleAttributesLastUpdateCheck
    true

  render: (article, force = false) =>

    # get articles
    @article = App.TicketArticle.fullLocal( @ticket_article_id )

    # set @el attributes
    if !article
      @el.addClass("ticket-article-item #{@article.sender.name.toLowerCase()}")
      @el.attr('data-id',  @article.id)
      @el.attr('id', "article-#{@article.id}")

    # set internal change directly in dom, without rerender while article
    if !article || ( @lastArticle && @lastArticle.internal isnt @article.internal )
      if @article.internal is true
        @el.addClass('is-internal')
      else
        @el.removeClass('is-internal')

    # check if rerender is needed
    if !force && !@hasChanged(@article)
      @lastArticle = @article.attributes()
      return

    # prepare html body
    if @article.content_type is 'text/html'
      @article['html'] = @article.body
      @article['html'] = App.Utils.signatureIdentify( @article['html'] )
    else

      # client signature detection
      bodyHtml = App.Utils.text2html(@article.body)
      @article['html'] = App.Utils.signatureIdentify(bodyHtml)

      # if no signature detected or within frist 25 lines, check if signature got detected in backend
      if @article['html'] is bodyHtml || (@article.preferences && @article.preferences.signature_detection < 25)
        signatureDetected = false
        body = @article.body
        if @article.preferences && @article.preferences.signature_detection
          signatureDetected = '########SIGNATURE########'
          # coffeelint: disable=no_unnecessary_double_quotes
          body = body.split("\n")
          body.splice(@article.preferences.signature_detection, 0, signatureDetected)
          body = body.join("\n")
          # coffeelint: enable=no_unnecessary_double_quotes
        if signatureDetected
          body = App.Utils.textCleanup(body)
          @article['html'] = App.Utils.text2html(body)
          @article['html']  = @article['html'].replace(signatureDetected, '<span class="js-signatureMarker"></span>')

    @html App.view('ticket_zoom/article_view')(
      ticket:     @ticket
      article:    @article
      isCustomer: @isRole('Customer')
    )

    new App.WidgetAvatar(
      el:      @$('.js-avatar')
      user_id: @article.created_by_id
      size:    40
    )

    new App.TicketZoomArticleActions(
      el:      @$('.js-article-actions')
      ticket:  @ticket
      article: @article
    )

    # set see more
    @shown = false
    a = =>
      @setSeeMore()
    @delay( a, 50 )

    # set highlighter
    @setHighlighter()

  # set see more options
  setSeeMore: =>
    return if @el.is(':hidden')
    return if @shown
    @shown = true

    maxHeight               = 560
    bubbleContent           = @textBubbleContent
    bubbleOvervlowContainer = @textBubbleOverflowContainer

    # expand if see more is already clicked
    if @seeMore
      bubbleContent.css('height', 'auto')
      bubbleOvervlowContainer.addClass('hide')
      return

    # reset bubble heigth and "see more" opacity
    bubbleContent.css('height', '')
    bubbleOvervlowContainer.css('opacity', '')

    # remember offset of "see more"
    offsetTop = bubbleContent.find('.js-signatureMarker').position()

    # remember bubble heigth
    heigth = bubbleContent.height()
    if offsetTop && heigth
      bubbleContent.attr('data-height', heigth)
      bubbleContent.css('height', "#{offsetTop.top + 30}px")
      bubbleOvervlowContainer.removeClass('hide')
    else if heigth > maxHeight
      bubbleContent.attr('data-height', heigth)
      bubbleContent.css('height', "#{maxHeight}px")
      bubbleOvervlowContainer.removeClass('hide')
    else
      bubbleOvervlowContainer.addClass('hide')

  show_toogle: (e) ->
    e.stopPropagation()
    e.preventDefault()
    #$(e.target).hide()
    if $(e.target).next('div')[0]
      if $(e.target).next('div').hasClass('hide')
        $(e.target).next('div').removeClass('hide')
        $(e.target).text( App.i18n.translateContent('Fold in') )
      else
        $(e.target).text( App.i18n.translateContent('See more') )
        $(e.target).next('div').addClass('hide')

  stopPropagation: (e) ->
    e.stopPropagation()

  toggle_meta_with_delay: (e) =>
    # allow double click select
    # by adding a delay to the toggle

    if @lastClick and +new Date - @lastClick < 100
      clearTimeout(@toggleMetaTimeout)
    else
      @toggleMetaTimeout = setTimeout(@toggle_meta, 100, e)
      @lastClick = +new Date

  toggle_meta: (e) =>
    e.preventDefault()

    animSpeed      = 300
    article        = $(e.target).closest('.ticket-article-item')
    metaTopClip    = article.find('.article-meta-clip.top')
    metaBottomClip = article.find('.article-meta-clip.bottom')
    metaTop        = article.find('.article-content-meta.top')
    metaBottom     = article.find('.article-content-meta.bottom')

    if @elementContainsSelection( article.get(0) )
      @stopPropagation(e)
      return false

    if !metaTop.hasClass('hide')
      article.removeClass('state--folde-out')

      # scroll back up
      article.velocity 'scroll',
        container: article.scrollParent()
        offset: -article.offset().top - metaTop.outerHeight()
        duration: animSpeed
        easing: 'easeOutQuad'

      metaTop.velocity
        properties:
          translateY: 0
          opacity: [ 0, 1 ]
        options:
          speed: animSpeed
          easing: 'easeOutQuad'
          complete: -> metaTop.addClass('hide')

      metaBottom.velocity
        properties:
          translateY: [ -metaBottom.outerHeight(), 0 ]
          opacity: [ 0, 1 ]
        options:
          speed: animSpeed
          easing: 'easeOutQuad'
          complete: -> metaBottom.addClass('hide')

      metaTopClip.velocity({ height: 0 }, animSpeed, 'easeOutQuad')
      metaBottomClip.velocity({ height: 0 }, animSpeed, 'easeOutQuad')
    else
      article.addClass('state--folde-out')
      metaBottom.removeClass('hide')
      metaTop.removeClass('hide')

      # balance out the top meta height by scrolling down
      article.velocity('scroll',
        container: article.scrollParent()
        offset: -article.offset().top + metaTop.outerHeight()
        duration: animSpeed
        easing: 'easeOutQuad'
      )

      metaTop.velocity
        properties:
          translateY: [ 0, metaTop.outerHeight() ]
          opacity: [ 1, 0 ]
        options:
          speed: animSpeed
          easing: 'easeOutQuad'

      metaBottom.velocity
        properties:
          translateY: [ 0, -metaBottom.outerHeight() ]
          opacity: [ 1, 0 ]
        options:
          speed: animSpeed
          easing: 'easeOutQuad'

      metaTopClip.velocity({ height: metaTop.outerHeight() }, animSpeed, 'easeOutQuad')
      metaBottomClip.velocity({ height: metaBottom.outerHeight() }, animSpeed, 'easeOutQuad')

  unfold: (e) ->
    e.preventDefault()
    e.stopPropagation()

    @seeMore = true

    bubbleContent           = @textBubbleContent
    bubbleOvervlowContainer = @textBubbleOverflowContainer

    bubbleOvervlowContainer.velocity
      properties:
        opacity: 0
      options:
        duration: 300

    bubbleContent.velocity
      properties:
        height: bubbleContent.attr('data-height')
      options:
        duration: 300
        complete: -> bubbleOvervlowContainer.addClass('hide')

  isOrContains: (node, container) ->
    while node
      if node is container
        return true
      node = node.parentNode
    false

  elementContainsSelection: (el) ->
    sel = window.getSelection()
    if sel.rangeCount > 0 && sel.toString()
      for i in [0..sel.rangeCount-1]
        if !@isOrContains(sel.getRangeAt(i).commonAncestorContainer, el)
          return false
      return true
    false
