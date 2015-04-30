# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

# encoding: utf-8

require 'mail'
require 'encode'

class Channel::EmailParser

=begin

  mail = parse( msg_as_string )

  mail = {
    :from              => 'Some Name <some@example.com>',
    :from_email        => 'some@example.com',
    :from_local        => 'some',
    :from_domain       => 'example.com',
    :from_display_name => 'Some Name',
    :message_id        => 'some_message_id@example.com',
    :to                => 'Some System <system@example.com>',
    :cc                => 'Somebody <somebody@example.com>',
    :subject           => 'some message subject',
    :body              => 'some message body',
    :attachments       => [
      {
        :data        => 'binary of attachment',
        :filename    => 'file_name_of_attachment.txt',
        :preferences => {
          :content-alternative => true,
          :Mime-Type           => 'text/plain',
          :Charset             => 'iso-8859-1',
        },
      },
    ],

    # ignore email header
    :x-zammad-ignore => 'false',

    # customer headers
    :x-zammad-customer-login     => '',
    :x-zammad-customer-email     => '',
    :x-zammad-customer-firstname => '',
    :x-zammad-customer-lastname  => '',

    # ticket headers
    :x-zammad-ticket-group    => 'some_group',
    :x-zammad-ticket-state    => 'some_state',
    :x-zammad-ticket-priority => 'some_priority',
    :x-zammad-ticket-owner    => 'some_owner_login',

    # article headers
    :x-zammad-article-internal => false,
    :x-zammad-article-type     => 'agent',
    :x-zammad-article-sender   => 'customer',

    # all other email headers
    :some-header => 'some_value',
  }

=end

  def parse (msg)
    data = {}
    mail = Mail.new( msg )

    # set all headers
    mail.header.fields.each { |field|
      if field.name

        # full line, encode, ready for storage
        data[field.name.to_s.downcase.to_sym] = Encode.conv( 'utf8', field.to_s )

        # if we need to access the lines by objects later again
        data[ "raw-#{field.name.downcase.to_s}".to_sym ] = field
      end
    }

    # get sender
    from = nil
    ['from', 'reply-to', 'return-path'].each { |item|
      if !from
        if mail[ item.to_sym ]
          from = mail[ item.to_sym ].value
        end
      end
    }

    # set x-any-recipient
    data['x-any-recipient'.to_sym] = ''
    ['to', 'cc', 'delivered-to', 'x-original-to', 'envelope-to'].each { |item|
      if mail[item.to_sym]
        if data['x-any-recipient'.to_sym] != ''
          data['x-any-recipient'.to_sym] += ', '
        end
        data['x-any-recipient'.to_sym] += mail[item.to_sym].to_s
      end
    }

    # set extra headers
    begin
      data[:from_email]        = Mail::Address.new( from ).address
      data[:from_local]        = Mail::Address.new( from ).local
      data[:from_domain]       = Mail::Address.new( from ).domain
      data[:from_display_name] = Mail::Address.new( from ).display_name ||
      ( Mail::Address.new( from ).comments && Mail::Address.new( from ).comments[0] )
    rescue
      data[:from_email]  = from
      data[:from_local]  = from
      data[:from_domain] = from
    end

    # do extra decoding because we needed to use field.value
    data[:from_display_name] = Mail::Field.new( 'X-From', data[:from_display_name] ).to_s

    # compat headers
    data[:message_id] = data['message-id'.to_sym]

    # body
    #    plain_part = mail.multipart? ? (mail.text_part ? mail.text_part.body.decoded : nil) : mail.body.decoded
    #    html_part = message.html_part ? message.html_part.body.decoded : nil
    data[:attachments] = []

    # multi part email
    if mail.multipart?

      # text attachment/body exists
      if mail.text_part
        data[:body] = mail.text_part.body.decoded
        data[:body] = Encode.conv( mail.text_part.charset, data[:body] )

        if !data[:body].valid_encoding?
          data[:body] = data[:body].encode('utf-8', 'binary', invalid: :replace, undef: :replace, replace: '?')
        end

      # html attachment/body may exists and will be converted to text
      else
        filename = '-no name-'
        if mail.html_part && mail.html_part.body
          filename = 'message.html'
          data[:body] = mail.html_part.body.to_s
          data[:body] = Encode.conv( mail.html_part.charset.to_s, data[:body] )
          data[:body] = data[:body].html2text.to_s.force_encoding('utf-8')

          if !data[:body].force_encoding('UTF-8').valid_encoding?
            data[:body] = data[:body].encode('utf-8', 'binary', invalid: :replace, undef: :replace, replace: '?')
          end

        # any other attachments
        else
          data[:body] = 'no visible content'
        end
      end

      # add html attachment/body as real attachment
      if mail.html_part
        filename = 'message.html'
        headers_store = {
          'content-alternative' => true,
        }
        if mail.mime_type
          headers_store['Mime-Type'] = mail.html_part.mime_type
        end
        if mail.charset
          headers_store['Charset'] = mail.html_part.charset
        end
        attachment = {
          data: mail.html_part.body.to_s,
          filename: mail.html_part.filename || filename,
          preferences: headers_store
        }
        data[:attachments].push attachment
      end

      # get attachments
      if mail.parts
        mail.parts.each { |part|

          # protect process to work fine with spam emails, see test/fixtures/mail15.box
          begin
            attachs = self._get_attachment( part, data[:attachments], mail )
            data[:attachments].concat( attachs )
          rescue
            attachs = self._get_attachment( part, data[:attachments], mail )
            data[:attachments].concat( attachs )
          end
        }
      end

    # not multipart email
    else

      # text part only
      if !mail.mime_type || mail.mime_type.to_s == '' || mail.mime_type.to_s.downcase == 'text/plain'
        data[:body] = mail.body.decoded
        data[:body] = Encode.conv( mail.charset, data[:body] )

        if !data[:body].force_encoding('UTF-8').valid_encoding?
          data[:body] = data[:body].encode('utf-8', 'binary', invalid: :replace, undef: :replace, replace: '?')
        end

      # html part only, convert ot text and add it as attachment
      else
        filename = '-no name-'
        if mail.mime_type.to_s.downcase == 'text/html'
          filename = 'message.html'
          data[:body] = mail.body.decoded
          data[:body] = Encode.conv( mail.charset, data[:body] )
          data[:body] = data[:body].html2text.to_s.force_encoding('utf-8')

          if !data[:body].valid_encoding?
            data[:body] = data[:body].encode('utf-8', 'binary', invalid: :replace, undef: :replace, replace: '?')
          end

          # any other attachments
        else
          data[:body] = 'no visible content'
        end

        # add body as attachment
        headers_store = {
          'content-alternative' => true,
        }
        if mail.mime_type
          headers_store['Mime-Type'] = mail.mime_type
        end
        if mail.charset
          headers_store['Charset'] = mail.charset
        end
        attachment = {
          data: mail.body.decoded,
          filename: mail.filename || filename,
          preferences: headers_store
        }
        data[:attachments].push attachment
      end
    end

    # strip not wanted chars
    data[:body].gsub!( /\n\r/, "\n" )
    data[:body].gsub!( /\r\n/, "\n" )
    data[:body].gsub!( /\r/, "\n" )

    data
  end

  def _get_attachment( file, attachments, mail )

    # check if sub parts are available
    if !file.parts.empty?
      a = []
      file.parts.each {|p|
        attachment = self._get_attachment( p, attachments, mail )
        a.concat( attachment )
      }
      return a
    end

    # ignore text/plain attachments - already shown in view
    return [] if mail.text_part && mail.text_part.body.to_s == file.body.to_s

    # ignore text/html - html part, already shown in view
    return [] if mail.html_part && mail.html_part.body.to_s == file.body.to_s

    # get file preferences
    headers_store = {}
    file.header.fields.each { |field|
      headers_store[field.name.to_s] = field.value.to_s
    }

    # get filename from content-disposition
    filename = nil

    # workaround for: NoMethodError: undefined method `filename' for #<Mail::UnstructuredField:0x007ff109e80678>
    begin
      filename = file.header[:content_disposition].filename
    rescue
      result = file.header[:content_disposition].to_s.scan( /filename=("|)(.+?)("|);/i )
      if result && result[0] && result[0][1]
        filename = result[0][1]
      end
    end

    # for some broken sm mail clients (X-MimeOLE: Produced By Microsoft Exchange V6.5)
    if !filename
      filename = file.header[:content_location].to_s
    end

    # generate file name
    if !filename || filename.empty?
      attachment_count = 0
      (1..1000).each {|count|
        filename_exists = false
        filename = 'file-' + count.to_s
        attachments.each {|attachment|
          if attachment[:filename] == filename
            filename_exists = true
          end
        }
        break if filename_exists == false
      }
    end

    # get mime type
    if file.header[:content_type] && file.header[:content_type].string
      headers_store['Mime-Type'] = file.header[:content_type].string
    end

    # get charset
    if file.header && file.header.charset
      headers_store['Charset'] = file.header.charset
    end

    # remove not needed header
    headers_store.delete('Content-Transfer-Encoding')
    headers_store.delete('Content-Disposition')

    attach = {
      data: file.body.to_s,
      filename: filename,
      preferences: headers_store,
    }
    [attach]
  end

  def process(channel, msg)
    mail = parse( msg )

    # run postmaster pre filter
    filters = {
      '0010' => Channel::Filter::Trusted,
      '1000' => Channel::Filter::Database,
    }

    # filter( channel, mail )
    filters.each {|prio, backend|
      begin
        backend.run( channel, mail )
      rescue Exception => e
        puts "can't run postmaster pre filter #{backend}"
        puts e.inspect
        return false
      end
    }

    # check ignore header
    return true if mail[ 'x-zammad-ignore'.to_sym ] == 'true' || mail[ 'x-zammad-ignore'.to_sym ] == true

    ticket  = nil
    article = nil
    user    = nil

    # use transaction
    ActiveRecord::Base.transaction do

      # reset current_user
      UserInfo.current_user_id = 1

      # create sender
      if mail[ 'x-zammad-customer-login'.to_sym ]
        user = User.where( login: mail[ 'x-zammad-customer-login'.to_sym ] ).first
      end
      if !user
        user = User.where( email: mail[ 'x-zammad-customer-email'.to_sym ] || mail[:from_email] ).first
      end
      if !user
        puts 'create user...'
        user = user_create(
          login: mail[ 'x-zammad-customer-login'.to_sym ] || mail[ 'x-zammad-customer-email'.to_sym ] || mail[:from_email],
          firstname: mail[ 'x-zammad-customer-firstname'.to_sym ] || mail[:from_display_name],
          lastname: mail[ 'x-zammad-customer-lastname'.to_sym ],
          email: mail[ 'x-zammad-customer-email'.to_sym ] || mail[:from_email],
        )
      end

      # create to and cc user
      ['raw-to', 'raw-cc'].each { |item|
        if mail[item.to_sym] && mail[item.to_sym].tree
          items = mail[item.to_sym].tree
          items.addresses.each {|item|
            user_create(
              firstname: item.display_name,
              lastname: '',
              email: item.address,
            )
          }
        end
      }

      # set current user
      UserInfo.current_user_id = user.id

      # get ticket# from subject
      ticket = Ticket::Number.check( mail[:subject] )

      # set ticket state to open if not new
      if ticket
        state      = Ticket::State.find( ticket.state_id )
        state_type = Ticket::StateType.find( state.state_type_id )

        # if tickte is merged, find linked ticket
        if state_type.name == 'merged'

        end

        if state_type.name != 'new'
          ticket.state = Ticket::State.where( name: 'open' ).first
          ticket.save
        end
      end

      # create new ticket
      if !ticket

        # set attributes
        ticket = Ticket.new(
          group_id: channel[:group_id] || 1,
          customer_id: user.id,
          title: mail[:subject] || '',
          state_id: Ticket::State.where( name: 'new' ).first.id,
          priority_id: Ticket::Priority.where( name: '2 normal' ).first.id,
        )

        set_attributes_by_x_headers( ticket, 'ticket', mail )

        # create ticket
        ticket.save
      end

      # import mail

      # set attributes
      article = Ticket::Article.new(
        ticket_id: ticket.id,
        type_id: Ticket::Article::Type.where( name: 'email' ).first.id,
        sender_id: Ticket::Article::Sender.where( name: 'Customer' ).first.id,
        body: mail[:body],
        from: mail[:from],
        to: mail[:to],
        cc: mail[:cc],
        subject: mail[:subject],
        message_id: mail[:message_id],
        internal: false,
      )

      # x-headers lookup
      set_attributes_by_x_headers( article, 'article', mail )

      # create article
      article.save

      # store mail plain
      Store.add(
        object: 'Ticket::Article::Mail',
        o_id: article.id,
        data: msg,
        filename: "ticket-#{ticket.number}-#{article.id}.eml",
        preferences: {}
      )

      # store attachments
      if mail[:attachments]
        mail[:attachments].each do |attachment|
          Store.add(
            object: 'Ticket::Article',
            o_id: article.id,
            data: attachment[:data],
            filename: attachment[:filename],
            preferences: attachment[:preferences]
          )
        end
      end
    end

    # execute ticket events
    Observer::Ticket::Notification.transaction

    # run postmaster post filter
    filters = {
      #      '0010' => Channel::Filter::Trusted,
    }

    # filter( channel, mail )
    filters.each {|prio, backend|
      begin
        backend.run( channel, mail, ticket, article, user )
      rescue Exception => e
        puts "can't run postmaster post filter #{backend}"
        puts e.inspect
      end
    }

    # return new objects
    [ticket, article, user]
  end

  def user_create(data)

    # return existing
    user = User.where( login: data[:email].downcase ).first
    return user if user

    # create new user
    roles = Role.where( name: 'Customer' )

    # fillup
    ['firstname', 'lastname'].each { |item|
      if data[item.to_sym] == nil
        data[item.to_sym] = ''
      end
    }
    data[:password]      = ''
    data[:active]        = true
    data[:roles]         = roles
    data[:updated_by_id] = 1
    data[:created_by_id] = 1

    user = User.create(data)
    user.update_attributes(
      updated_by_id: user.id,
      created_by_id: user.id,
    )
    user
  end

  def set_attributes_by_x_headers( item_object, header_name, mail )

    # loop all x-zammad-hedaer-* headers
    item_object.attributes.each{|key, value|

      # ignore read only attributes
      next if key == 'updated_at'
      next if key == 'created_at'
      next if key == 'updated_by_id'
      next if key == 'created_by_id'

      # check if id exists
      key_short = key[ key.length - 3, key.length ]
      if key_short == '_id'
        key_short = key[ 0, key.length - 3 ]
        header = "x-zammad-#{header_name}-#{key_short}"
        if mail[ header.to_sym ]
          puts "NOTICE: header #{header} found #{mail[ header.to_sym ]}"
          item_object.class.reflect_on_all_associations.map { |assoc|
            if assoc.name.to_s == key_short
              puts "NOTICE: ASSOC found #{assoc.class_name} lookup #{mail[ header.to_sym ]}"
              item = assoc.class_name.constantize

              if item.respond_to?(:name)
                if item.lookup( name: mail[ header.to_sym ] )
                  item_object[key] = item.lookup( name: mail[ header.to_sym ] ).id
                end
              elsif item.respond_to?(:login)
                if item.lookup( login: mail[ header.to_sym ] )
                  item_object[key] = item.lookup( login: mail[ header.to_sym ] ).id
                end
              end
            end
          }
        end
      end

      # check if attribute exists
      header = "x-zammad-#{header_name}-#{key}"
      if mail[ header.to_sym ]
        puts "NOTICE: header #{header} found #{mail[ header.to_sym ]}"
        item_object[key] = mail[ header.to_sym ]
      end
    }

  end
end

# workaround to parse subjects with 2 different encodings correctly (e. g. quoted-printable see test/fixtures/mail9.box)
module Mail
  module Encodings
    def Encodings.value_decode(str)
      # Optimization: If there's no encoded-words in the string, just return it
      return str unless str.index('=?')

      str = str.gsub(/\?=(\s*)=\?/, '?==?') # Remove whitespaces between 'encoded-word's

      # Split on white-space boundaries with capture, so we capture the white-space as well
      str.split(/([ \t])/).map do |text|
        if text.index('=?') .nil?
          text
        else
          # Join QP encoded-words that are adjacent to avoid decoding partial chars
          #          text.gsub!(/\?\=\=\?.+?\?[Qq]\?/m, '') if text =~ /\?==\?/

          # Search for occurences of quoted strings or plain strings
          text.scan(/(                                  # Group around entire regex to include it in matches
          \=\?[^?]+\?([QB])\?[^?]+?\?\=  # Quoted String with subgroup for encoding method
          |                                # or
          .+?(?=\=\?|$)                    # Plain String
          )/xmi).map do |matches|
            string, method = *matches
            if    method == 'b' || method == 'B'
              b_value_decode(string)
            elsif method == 'q' || method == 'Q'
              q_value_decode(string)
            else
              string
            end
          end
        end
      end.join('')
    end
  end
end
