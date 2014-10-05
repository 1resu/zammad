# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::Article::CommunicateFacebook < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # if sender is customer, do not communication
    sender = Ticket::Article::Sender.lookup( :id => record.sender_id )
    return 1 if sender == nil
    return 1 if sender['name'] == 'Customer'

    # only apply on emails
    type = Ticket::Article::Type.lookup( :id => record.type_id )
    return if type['name'] != 'facebook'

    a = Channel::Facebook.new
    a.send(
      {
        :from    => 'me@znuny.com',
        :to      => 'medenhofer',
        :body    => record.body
      }
    )
  end
end
