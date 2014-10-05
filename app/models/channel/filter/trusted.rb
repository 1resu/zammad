# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

# delete all X-Zammad header if channel is not trusted
module Channel::Filter::Trusted

  def self.run( channel, mail )

    # check if trust x-headers
    if !channel[:trusted]
      mail.each {|key, value|
        if key =~ /^x-zammad/i
          mail.delete(key)
        end
      }
    end

  end
end
