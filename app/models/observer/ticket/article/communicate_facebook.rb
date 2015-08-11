# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'channel/facebook'

class Observer::Ticket::Article::CommunicateFacebook < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # if sender is customer, do not communication
    sender = Ticket::Article::Sender.lookup( id: record.sender_id )
    return 1 if sender.nil?
    return 1 if sender['name'] == 'Customer'

    # only apply for facebook
    type = Ticket::Article::Type.lookup( id: record.type_id )
    return if type['name'] !~ /\Afacebook/

    facebook = Channel::Facebook.new
    post     = facebook.send({
                               type:        type['name'],
                               to:          record.to,
                               body:        record.body,
                               in_reply_to: record.in_reply_to
                             })
    record.message_id = post['id']
    record.save
  end
end
