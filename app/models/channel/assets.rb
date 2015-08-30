# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Channel
  module Assets

=begin

get all assets / related models for this channel

  channel = Channel.find(123)
  result = channel.assets( assets_if_exists )

returns

  result = {
    :channels => {
      123  => channel_model_123,
      1234 => channel_model_1234,
    }
  }

=end

    def assets (data = {})

      if !data[ self.class.to_app_model ]
        data[ self.class.to_app_model ] = {}
      end
      if !data[ self.class.to_app_model ][ id ]
        attributes = attributes_with_associations

        # remove passwords
        %w(inbound outbound).each {|key|
          if attributes['options'] && attributes['options'][key] && attributes['options'][key]['options']
            attributes['options'][key]['options'].delete('password')
          end
        }

        data[ self.class.to_app_model ][ id ] = attributes
      end


      return data if !self['created_by_id'] && !self['updated_by_id']
      %w(created_by_id updated_by_id).each {|local_user_id|
        next if !self[ local_user_id ]
        next if data[ User.to_app_model ] && data[ User.to_app_model ][ self[ local_user_id ] ]
        user = User.lookup( id: self[ local_user_id ] )
        data = user.assets( data )
      }
      data
    end

  end
end
