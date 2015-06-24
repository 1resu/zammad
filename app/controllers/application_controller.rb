# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class ApplicationController < ActionController::Base
  #  http_basic_authenticate_with :name => "test", :password => "ttt"

  helper_method :current_user,
                :authentication_check,
                :config_frontend,
                :role?,
                :model_create_render,
                :model_update_render,
                :model_restory_render,
                :mode_show_rendeder,
                :model_index_render

  skip_before_action :verify_authenticity_token
  before_action :set_user, :session_update
  before_action :cors_preflight_check

  after_action  :set_access_control_headers
  after_action  :trigger_events

  # For all responses in this controller, return the CORS access control headers.
  def set_access_control_headers
    headers['Access-Control-Allow-Origin']      = '*'
    headers['Access-Control-Allow-Methods']     = 'POST, GET, PUT, DELETE, OPTIONS'
    headers['Access-Control-Max-Age']           = '1728000'
    headers['Access-Control-Allow-Headers']     = 'Content-Type, Depth, User-Agent, X-File-Size, X-Requested-With, If-Modified-Since, X-File-Name, Cache-Control, Accept-Language'
    headers['Access-Control-Allow-Credentials'] = 'true'
  end

  # If this is a preflight OPTIONS request, then short-circuit the
  # request, return only the necessary headers and return an empty
  # text/plain.

  def cors_preflight_check

    return if request.method != 'OPTIONS'

    headers['Access-Control-Allow-Origin']      = '*'
    headers['Access-Control-Allow-Methods']     = 'POST, GET, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers']     = 'Content-Type, Depth, User-Agent, X-File-Size, X-Requested-With, If-Modified-Since, X-File-Name, Cache-Control, Accept-Language'
    headers['Access-Control-Max-Age']           = '1728000'
    headers['Access-Control-Allow-Credentials'] = 'true'
    render text: '', content_type: 'text/plain'

    false
  end

  private

  # execute events
  def trigger_events
    Observer::Ticket::Notification.transaction
  end

  # Finds the User with the ID stored in the session with the key
  # :current_user_id This is a common way to handle user login in
  # a Rails application; logging in sets the session value and
  # logging out removes it.
  def current_user
    return @_current_user if @_current_user
    return if !session[:user_id]
    @_current_user = User.find( session[:user_id] )
  end

  def current_user_set(user)
    session[:user_id] = user.id
    @_current_user = user
    set_user
  end

  # Sets the current user into a named Thread location so that it can be accessed
  # by models and observers
  def set_user
    return if !current_user
    UserInfo.current_user_id = current_user.id
  end

  # update session updated_at
  def session_update
    #sleep 0.6

    session[:ping] = Time.zone.now.iso8601

    # check if remote ip need to be updated
    if !session[:remote_id] || session[:remote_id] != request.remote_ip
      session[:remote_id]  = request.remote_ip
      session[:geo]        = GeoIp.location( request.remote_ip )
    end

    # fill user agent
    return if session[:user_agent]

    session[:user_agent] = request.env['HTTP_USER_AGENT']
  end

  def authentication_check_only(auth_param)

    logger.debug 'authentication_check'
    #logger.debug params.inspect
    #logger.debug session.inspect
    #logger.debug cookies.inspect

    # already logged in, early exit
    if session.id && session[:user_id]
      userdata = User.find( session[:user_id] )
      current_user_set(userdata)

      return {
        auth: true
      }
    end

    error_message = 'authentication failed'

    # check logon session
    if params['logon_session']
      logon_session = ActiveRecord::SessionStore::Session.where( session_id: params['logon_session'] ).first

      # set logon session user to current user
      if logon_session
        userdata = User.find( logon_session.data[:user_id] )
        current_user_set(userdata)

        session[:persistent] = true

        return {
          auth: true
        }
      end

      error_message = 'no valid session, user_id'
    end

    # check sso
    sso_userdata = User.sso(params)
    if sso_userdata

      current_user_set(sso_userdata)

      session[:persistent] = true

      return {
        auth: true
      }
    end

    # check http basic auth
    authenticate_with_http_basic do |username, password|
      logger.debug "http basic auth check '#{username}'"

      userdata = User.authenticate( username, password )

      next if !userdata

      # set basic auth user to current user
      current_user_set(userdata)
      return {
        auth: true
      }
    end

    # check token
    if auth_param[:token_action]
      authenticate_with_http_token do |token, _options|
        logger.debug "token auth check #{token}"

        userdata = Token.check(
          action: auth_param[:token_action],
          name: token,
        )

        next if !userdata

        # set token user to current user
        current_user_set(userdata)

        return {
          auth: true
        }
      end
    end

    logger.debug error_message
    {
      auth: false,
      message: error_message,
    }
  end

  def authentication_check( auth_param = {} )
    result = authentication_check_only(auth_param)

    # check if basic_auth fallback is possible
    if auth_param[:basic_auth_promt] && result[:auth] == false

      return request_http_basic_authentication
    end

    # return auth not ok
    if result[:auth] == false
      render(
        json: {
          error: result[:message],
        },
        status: :unauthorized
      )
      return false
    end

    # store current user id into the session
    session[:user_id] = current_user.id

    # return auth ok
    true
  end

  def role?( role_name )
    return false if !current_user
    current_user.role?( role_name )
  end

  def ticket_permission(ticket)
    return true if ticket.permission( current_user: current_user )
    response_access_deny
    false
  end

  def deny_if_not_role( role_name )
    return false if role?( role_name )
    response_access_deny
    true
  end

  def valid_session_with_user
    return true if current_user
    render json: { message: 'No session user!' }, status: :unprocessable_entity
    false
  end

  def response_access_deny
    render(
      json: {},
      status: :unauthorized
    )
    false
  end

  def config_frontend

    # config
    config = {}
    Setting.select('name').where( frontend: true ).each { |setting|
      config[setting.name] = Setting.get(setting.name)
    }

    # get all time zones
    config['timezones'] = {}
    TZInfo::Timezone.all.each { |t|

      # ignore the following time zones
      next if t.name =~ /^GMT/
      next if t.name =~ /^Etc/
      next if t.name =~ /^MET/
      next if t.name =~ /^MST/
      next if t.name =~ /^ROC/
      next if t.name =~ /^ROK/
      diff = t.current_period.utc_total_offset / 60 / 60
      config['timezones'][ t.name ] = diff
    }

    if session[:switched_from_user_id]
      config['switch_back_to_possible'] = true
    end

    config
  end

  # model helper
  def model_create_render (object, params)

    # create object
    generic_object = object.new( object.param_cleanup( params[object.to_app_model_url], true ) )

    # save object
    generic_object.save!

    # set relations
    generic_object.param_set_associations( params )

    model_create_render_item(generic_object)
  rescue => e
    logger.error e.message
    logger.error e.backtrace.inspect
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def model_create_render_item (generic_object)
    render json: generic_object.attributes_with_associations, status: :created
  end

  def model_update_render (object, params)

    # find object
    generic_object = object.find( params[:id] )

    # save object
    generic_object.update_attributes!( object.param_cleanup( params[object.to_app_model_url] ) )

    # set relations
    generic_object.param_set_associations( params )

    model_update_render_item( generic_object )
  rescue => e
    logger.error e.message
    logger.error e.backtrace.inspect
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def model_update_render_item (generic_object)
    render json: generic_object.attributes_with_associations, status: :ok
  end

  def model_destory_render (object, params)
    generic_object = object.find( params[:id] )
    generic_object.destroy
    model_destory_render_item()
  rescue => e
    logger.error e.message
    logger.error e.backtrace.inspect
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def model_destory_render_item ()
    render json: {}, status: :ok
  end

  def model_show_render (object, params)

    if params[:full]
      generic_object_full = object.full( params[:id] )
      render json: generic_object_full, status: :ok
      return
    end

    generic_object = object.find( params[:id] )
    model_show_render_item(generic_object)
  rescue => e
    logger.error e.message
    logger.error e.backtrace.inspect
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def model_show_render_item (generic_object)
    render json: generic_object.attributes_with_associations, status: :ok
  end

  def model_index_render (object, _params)
    generic_objects = object.all
    model_index_render_result( generic_objects )
  rescue => e
    logger.error e.message
    logger.error e.backtrace.inspect
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def model_index_render_result (generic_objects)
    render json: generic_objects, status: :ok
  end

end
