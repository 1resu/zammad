# coffeelint: disable=camel_case_classes
class App.UiElement.richtext
  @render: (attribute) ->

    item = $( App.view('generic/richtext')( attribute: attribute ) )
    item.find('[contenteditable]').ce(
      mode:      attribute.type
      maxlength: attribute.maxlength
    )
    if attribute.upload
      item.append( $( App.view('generic/attachment')( attribute: attribute ) ) )

      renderAttachment = (file) =>
        item.find('.attachments').append( App.view('generic/attachment_item')(
          fileName: file.filename
          fileSize: @humanFileSize( file.size )
          store_id: file.store_id
        ))
        item.on(
          'click'
          "[data-id=#{file.store_id}]", (e) =>
            @attachments = _.filter(
              @attachments,
              (item) ->
                return if item.id isnt file.store_id
                item
            )
            store_id = $(e.currentTarget).data('id')

            # delete attachment from storage
            App.Ajax.request(
              type:        'DELETE'
              url:         App.Config.get('api_path') + '/ticket_attachment_upload'
              data:        JSON.stringify( { store_id: store_id } ),
              processData: false
            )

            # remove attachment from dom
            element = $(e.currentTarget).closest('.attachments')
            $(e.currentTarget).closest('.attachment').remove()
            # empty .attachment (remove spaces) to keep css working, thanks @mrflix :-o
            if element.find('.attachment').length == 0
              element.empty()
        )

      @attachments           = []
      @progressBar           = item.find('.attachmentUpload-progressBar')
      @progressText          = item.find('.js-percentage')
      @attachmentPlaceholder = item.find('.attachmentPlaceholder')
      @attachmentUpload      = item.find('.attachmentUpload')
      @attachmentsHolder     = item.find('.attachments')
      @cancelContainer       = item.find('.js-cancel')

      u = => html5Upload.initialize(
        uploadUrl:              App.Config.get('api_path') + '/ticket_attachment_upload',
        dropContainer:          item.closest('form').get(0),
        cancelContainer:        @cancelContainer,
        inputField:             item.find( 'input' ).get(0),
        key:                    'File',
        data:                   { form_id: @form_id },
        maxSimultaneousUploads: 1,
        onFileAdded:            (file) =>

          file.on(

            onStart: =>
              @attachmentPlaceholder.addClass('hide')
              @attachmentUpload.removeClass('hide')
              @cancelContainer.removeClass('hide')
              console.log('upload start')

            onAborted: =>
              @attachmentPlaceholder.removeClass('hide')
              @attachmentUpload.addClass('hide')

            # Called after received response from the server
            onCompleted: (response) =>

              response = JSON.parse(response)
              @attachments.push response.data

              @attachmentPlaceholder.removeClass('hide')
              @attachmentUpload.addClass('hide')

              renderAttachment(response.data)
              console.log('upload complete', response.data )

            # Called during upload progress, first parameter
            # is decimal value from 0 to 100.
            onProgress: (progress, fileSize, uploadedBytes) =>
              @progressBar.width(parseInt(progress) + '%')
              @progressText.text(parseInt(progress))
              # hide cancel on 90%
              if parseInt(progress) >= 90
                @cancelContainer.addClass('hide')
              console.log('uploadProgress ', parseInt(progress))
          )
      )
      App.Delay.set( u, 100, undefined, 'form_upload' )
    item