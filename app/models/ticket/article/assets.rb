# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module Ticket::Article::Assets

=begin

get all assets / related models for this article

  article = Ticket::Article.find(123)
  result = article.assets( assets_if_exists )

returns

  result = {
    :users => {
      123  => user_model_123,
      1234 => user_model_1234,
    }
    :article => [ article_model1 ],
  }

=end

  def assets (data)

    if !data[ Ticket.to_app_model ]
      data[ Ticket.to_app_model ] = {}
    end
    if !data[ Ticket.to_app_model ][ ticket_id ]
      ticket = Ticket.find( ticket_id )
      data = ticket.assets(data)
    end

    if !data[ Ticket::Article.to_app_model ]
      data[ Ticket::Article.to_app_model ] = {}
    end
    if !data[ Ticket::Article.to_app_model ][ id ]
      data[ Ticket::Article.to_app_model ][ id ] = attributes

      # add attachment list to article
      data[ Ticket::Article.to_app_model ][ id ]['attachments'] = attachments
    end

    %w(created_by_id updated_by_id).each {|local_user_id|
      next if !self[ local_user_id ]
      next if data[ User.to_app_model ] && data[ User.to_app_model ][ self[ local_user_id ] ]
      user = User.lookup( id: self[ local_user_id ] )
      data = user.assets( data )
    }
    data
  end
end
