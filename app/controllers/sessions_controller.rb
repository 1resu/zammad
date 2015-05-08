# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class SessionsController < ApplicationController

  # "Create" a login, aka "log the user in"
  def create

    # in case, remove switched_from_user_id
    session[:switched_from_user_id] = nil

    # authenticate user
    user = User.authenticate( params[:username], params[:password] )

    # auth failed
    if !user
      render json: { error: 'login failed' }, status: :unauthorized
      return
    end

    # remember me - set session cookie to expire later
    if params[:remember_me]
      request.env['rack.session.options'][:expire_after] = 1.year
    else
      request.env['rack.session.options'][:expire_after] = nil
    end
    # both not needed to set :expire_after works fine
    #  request.env['rack.session.options'][:renew] = true
    #  reset_session

    # set session user
    current_user_set(user)

    # log new session
    user.activity_stream_log( 'session started', user.id, true )

    # auto population of default collections
    collections, assets = SessionHelper.default_collections(user)

    # add session user assets
    assets = user.assets(assets)

    # get models
    models = SessionHelper.models(user)

    # check logon session
    logon_session_key = nil
    if params['logon_session']
      logon_session_key = Digest::MD5.hexdigest( rand(999_999).to_s + Time.zone.now.to_s )
      #      session = ActiveRecord::SessionStore::Session.create(
      #        :session_id => logon_session_key,
      #        :data => {
      #          :user_id => user['id']
      #        }
      #      )
    end

    # return new session data
    render  status: :created,
            json: {
              session: user,
              models: models,
              collections: collections,
              assets: assets,
              logon_session: logon_session_key,
            }
  end

  def show

    user_id = nil

    # no valid sessions
    if session[:user_id]
      user_id = session[:user_id]
    end

    # check logon session
    if params['logon_session']
      session = SessionHelper.get( params['logon_session'] )
      if session
        user_id = session.data[:user_id]
      end
    end

    if !user_id
      # get models
      models = SessionHelper.models()

      render json: {
        error: 'no valid session',
        config: config_frontend,
        models: models,
        collections: {
          Locale.to_app_model => Locale.where( active: true )
        }
      }
      return
    end

    # Save the user ID in the session so it can be used in
    # subsequent requests
    user = User.find( user_id )

    # auto population of default collections
    collections, assets = SessionHelper.default_collections(user)

    # add session user assets
    assets = user.assets(assets)

    # get models
    models = SessionHelper.models(user)

    # return current session
    render json: {
      session: user,
      models: models,
      collections: collections,
      assets: assets,
      config: config_frontend,
    }
  end

  # "Delete" a login, aka "log the user out"
  def destroy

    # Remove the user id from the session
    @_current_user = session[:user_id] = nil

    # reset session cookie (reset :expire_after in case remember_me is active)
    request.env['rack.session.options'][:expire_after] = -1.year
    request.env['rack.session.options'][:renew] = true

    render json: {}
  end

  def create_omniauth

    # in case, remove switched_from_user_id
    session[:switched_from_user_id] = nil

    auth = request.env['omniauth.auth']

    if !auth
      logger.info('AUTH IS NULL, SERVICE NOT LINKED TO ACCOUNT')

      # redirect to app
      redirect_to '/'
    end

    # Create a new user or add an auth to existing user, depending on
    # whether there is already a user signed in.
    authorization = Authorization.find_from_hash(auth)
    if !authorization
      authorization = Authorization.create_from_hash(auth, current_user)
    end

    # set current session user
    current_user_set(authorization.user)

    # log new session
    authorization.user.activity_stream_log( 'session started', authorization.user.id, true )

    # remember last login date
    authorization.user.update_last_login

    # redirect to app
    redirect_to '/'
  end

  def create_sso

    # in case, remove switched_from_user_id
    session[:switched_from_user_id] = nil

    user = User.sso(params)

    # Log the authorizing user in.
    if user

      # set current session user
      current_user_set(user)

      # log new session
      user.activity_stream_log( 'session started', user.id, true )

      # remember last login date
      user.update_last_login
    end

    # redirect to app
    redirect_to '/#'
  end

  # "switch" to user
  def switch_to_user
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    # check user
    if !params[:id]
      render(
        json: { message: 'no user given' },
        status: :not_found
      )
      return false
    end

    user = User.lookup( id: params[:id] )
    if !user
      render(
        json: {},
        status: :not_found
      )
      return false
    end

    # remember old user
    session[:switched_from_user_id] = current_user.id

    # log new session
    user.activity_stream_log( 'switch to', current_user.id, true )

    # set session user
    current_user_set(user)

    redirect_to '/#'
  end

  # "switch" back to user
  def switch_back_to_user

    # check if it's a swich back
    if !session[:switched_from_user_id]
      response_access_deny
      return false
    end

    user = User.lookup( id: session[:switched_from_user_id] )
    if !user
      render(
        json: {},
        status: :not_found
      )
      return false
    end

    # rememeber current user
    current_session_user = current_user

    # remove switched_from_user_id
    session[:switched_from_user_id] = nil

    # set old session user again
    current_user_set(user)

    # log end session
    current_session_user.activity_stream_log( 'ended switch to', user.id, true )

    redirect_to '/#'
  end

  def list
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    assets = {}
    sessions_clean = []
    SessionHelper.list.each {|session|
      next if !session.data['user_id']
      sessions_clean.push session
      if session.data['user_id']
        user = User.lookup( id: session.data['user_id'] )
        assets = user.assets( assets )
      end
    }
    render json: {
      sessions: sessions_clean,
      assets: assets,
    }
  end

  def delete
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    SessionHelper.destroy( params[:id] )
    render json: {}
  end

end
