class Sessions::Backend::ActivityStream

  def initialize( user, client = nil, client_id = nil, ttl = 30 )
    @user        = user
    @client      = client
    @client_id   = client_id
    @ttl         = ttl
    @last_change = nil
  end

  def load

    # get whole collection
    activity_stream = @user.activity_stream( 25 )
    if activity_stream && !activity_stream.first
      return
    end

    if activity_stream && activity_stream.first && activity_stream.first['created_at'] == @last_change
      return
    end

    # update last changed
    if activity_stream && activity_stream.first
       @last_change = activity_stream.first['created_at']
    end

    @user.activity_stream( 25, true )
  end

  def client_key
    "as::load::#{ self.class.to_s }::#{ @user.id }::#{ @client_id }"
  end

  def push

    # check timeout
    timeout = Sessions::CacheIn.get( self.client_key )
    return if timeout

    # set new timeout
    Sessions::CacheIn.set( self.client_key, true, { expires_in: @ttl.seconds } )

    data = self.load

    return if !data || data.empty?

    if !@client
      return {
        event: 'activity_stream_rebuild',
        collection: 'activity_stream',
        data: data,
      }
    end

    @client.log 'notify', "push activity_stream #{ data.first.class.to_s } for user #{ @user.id }"
    @client.send({
      event: 'activity_stream_rebuild',
      collection: 'activity_stream',
      data: data,
    })
  end

end
