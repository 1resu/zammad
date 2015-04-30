# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'digest/md5'

# @model User
#
# @property id(required)    [Integer] The identifier for the User.
# @property login(required) [String]  The login of the User used for authentication.
# @property firstname       [String]  The firstname of the User.
# @property lastname        [String]  The lastname of the User.
# @property email           [String]  The email of the User.
# @property image           [String]  The Image used as the User avatar (TODO: Image model?).
# @property web             [String]  The website/URL of the User.
# @property password        [String]  The password of the User.
# @property phone           [String]  The phone number of the User.
# @property fax             [String]  The fax number of the User.
# @property mobile          [String]  The mobile number of the User.
# @property department      [String]  The department the User is working at.
# @property street          [String]  The street the User lives in.
# @property zip             [Integer] The zip postal code of the User city.
# @property city            [String]  The city the User lives in.
# @property country         [String]  The country the User lives in.
# @property verified        [Boolean] The flag that shows the verified state of the User.
# @property active          [Boolean] The flag that shows the active state of the User.
# @property note            [String]  The note or comment stored to the User.
class User < ApplicationModel
  include User::Permission
  load 'user/assets.rb'
  include User::Assets
  extend User::Search
  include User::SearchIndex

  before_create   :check_name, :check_email, :check_login, :check_password
  before_update   :check_password, :check_email, :check_login
  after_create    :avatar_check
  after_update    :avatar_check
  after_destroy   :avatar_destroy
  notify_clients_support

  has_and_belongs_to_many :groups,          after_add: :cache_update, after_remove: :cache_update
  has_and_belongs_to_many :roles,           after_add: :cache_update, after_remove: :cache_update
  has_and_belongs_to_many :organizations,   after_add: :cache_update, after_remove: :cache_update
  has_many                :tokens,          after_add: :cache_update, after_remove: :cache_update
  has_many                :authorizations,  after_add: :cache_update, after_remove: :cache_update
  belongs_to              :organization,    class_name: 'Organization'

  store                   :preferences

  activity_stream_support(
    role: Z_ROLENAME_ADMIN,
    ignore_attributes: {
      last_login: true,
      image: true,
      image_source: true,
    }
  )
  history_support(
    ignore_attributes: {
      password: true,
      image: true,
      image_source: true,
    }
  )
  search_index_support(
    ignore_attributes: {
      password: true,
      image: true,
      image_source: true,
      source: true,
      login_failed: true,
      preferences: true,
    }
  )

=begin

fullname of user

  user = User.find(123)
  result = user.fulename

returns

  result = "Bob Smith"

=end

  def fullname
    fullname = ''
    if self.firstname && !self.firstname.empty?
      fullname = fullname + self.firstname
    end
    if self.lastname && !self.lastname.empty?
      if fullname != ''
        fullname = fullname + ' '
      end
      fullname = fullname + self.lastname
    end
    if fullname == '' && self.email
      fullname = self.email
    end
    fullname
  end

=begin

check if user is in role

  user = User.find(123)
  result = user.is_role('Customer')

returns

  result = true|false

=end

  def is_role( role_name )
    self.roles.each { |role|
      return role if role.name == role_name
    }
    false
  end

=begin

get users activity stream

  user = User.find(123)
  result = user.activity_stream( 20 )

returns

  result = [
    {
      :id            => 2,
      :o_id          => 2,
      :created_by_id => 3,
      :created_at    => '2013-09-28 00:57:21',
      :object        => "User",
      :type          => "created",
    },
    {
      :id            => 2,
      :o_id          => 2,
      :created_by_id => 3,
      :created_at    => '2013-09-28 00:59:21',
      :object        => "User",
      :type          => "updated",
    },
  ]

=end

  def activity_stream( limit, fulldata = false )
    activity_stream = ActivityStream.list( self, limit )
    return activity_stream if !fulldata

    # get related objects
    assets = ApplicationModel.assets_of_object_list(activity_stream)

    return {
      activity_stream: activity_stream,
      assets: assets,
    }
  end

=begin

authenticate user

  result = User.authenticate(username, password)

returns

  result = user_model # user model if authentication was successfully

=end

  def self.authenticate( username, password )

    # do not authenticate with nothing
    return if !username || username == ''
    return if !password || password == ''

    # try to find user based on login
    user = User.where( login: username.downcase, active: true ).first

    # try second lookup with email
    if !user
      user = User.where( email: username.downcase, active: true ).first
    end

    # check failed logins
    max_login_failed = Setting.get('password_max_login_failed').to_i || 10
    if user && user.login_failed > max_login_failed
      return false
    end

    user_auth = Auth.check( username, password, user )

    # set login failed +1
    if !user_auth && user
      sleep 1
      user.login_failed = user.login_failed + 1
      user.save
    end

    # auth ok
    user_auth
  end

=begin

authenticate user agains sso

  result = User.sso(sso_params)

returns

  result = user_model # user model if authentication was successfully

=end

  def self.sso(params)

    # try to login against configure auth backends
    user_auth = Sso.check( params )
    return if !user_auth

    user_auth
  end

=begin

create user from from omni auth hash

  result = User.create_from_hash!(hash)

returns

  result = user_model # user model if create was successfully

=end

  def self.create_from_hash!(hash)
    url = ''
    if hash['info']['urls'] then
      url = hash['info']['urls']['Website'] || hash['info']['urls']['Twitter'] || ''
    end
    roles = Role.where( name: 'Customer' )
    self.create(
      login: hash['info']['nickname'] || hash['uid'],
      firstname: hash['info']['name'],
      email: hash['info']['email'],
      image: hash['info']['image'],
      #      :url        => url.to_s,
      note: hash['info']['description'],
      source: hash['provider'],
      roles: roles,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

=begin

send reset password email with token to user

  result = User.password_reset_send(username)

returns

  result = token

=end

  def self.password_reset_send(username)
    return if !username || username == ''

    # try to find user based on login
    user = User.where( login: username.downcase, active: true ).first

    # try second lookup with email
    if !user
      user = User.where( email: username.downcase, active: true ).first
    end

    # check if email address exists
    return if !user
    return if !user.email

    # generate token
    token = Token.create( action: 'PasswordReset', user_id: user.id )

    # send mail
    data = {}
    data[:subject] = 'Reset your #{config.product_name} password'
    data[:body]    = 'Forgot your password?

We received a request to reset the password for your #{config.product_name} account (#{user.login}).

If you want to reset your password, click on the link below (or copy and paste the URL into your browser):

#{config.http_type}://#{config.fqdn}/#password_reset_verify/#{token.name}

This link takes you to a page where you can change your password.

If you don\'t want to reset your password, please ignore this message. Your password will not be reset.

Your #{config.product_name} Team'

    # prepare subject & body
    [:subject, :body].each { |key|
      data[key.to_sym] = NotificationFactory.build(
        locale: user.preferences[:locale],
        string: data[key.to_sym],
        objects: {
          token: token,
          user: user,
        }
      )
    }

    # send notification
    NotificationFactory.send(
      recipient: user,
      subject: data[:subject],
      body: data[:body]
    )
    token
  end

=begin

check reset password token

  result = User.password_reset_check(token)

returns

  result = user_model # user_model if token was verified

=end

  def self.password_reset_check(token)
    user = Token.check( action: 'PasswordReset', name: token )

    # reset login failed if token is valid
    if user
      user.login_failed = 0
      user.save
    end
    user
  end

=begin

reset reset password with token and set new password

  result = User.password_reset_via_token(token,password)

returns

  result = user_model # user_model if token was verified

=end

  def self.password_reset_via_token(token, password)

    # check token
    user = Token.check( action: 'PasswordReset', name: token )
    return if !user

    # reset password
    user.update_attributes( password: password )

    # delete token
    Token.where( action: 'PasswordReset', name: token ).first.destroy
    user
  end

=begin

update last login date and reset login_failed (is automatically done by auth and sso backend)

  user = User.find(123)
  result = user.update_last_login

returns

  result = new_user_model

=end

  def update_last_login
    self.last_login = Time.now

    # reset login failed
    self.login_failed = 0

    # set updated by user
    self.updated_by_id = self.id

    self.save
  end

  private

  def check_name

    if ( self.firstname && !self.firstname.empty? ) && ( !self.lastname || self.lastname.empty? )

      # Lastname, Firstname
      scan = self.firstname.scan(/, /)
      if scan[0]
        name = self.firstname.split(', ', 2)
        if name[0] != nil
          self.lastname  = name[0]
        end
        if name[1] != nil
          self.firstname = name[1]
        end
        return
      end

      # Firstname Lastname
      name = self.firstname.split(' ', 2)
      if name[0] != nil
        self.firstname = name[0]
      end
      if name[1] != nil
        self.lastname = name[1]
      end
      return

    # -no name- firstname.lastname@example.com
    elsif ( !self.firstname || self.firstname.empty? ) && ( !self.lastname || self.lastname.empty? ) && ( self.email && !self.email.empty? )
      scan = self.email.scan(/^(.+?)\.(.+?)\@.+?$/)
      if scan[0]
        if scan[0][0] != nil
          self.firstname = scan[0][0].capitalize
        end
        if scan[0][1] != nil
          self.lastname  = scan[0][1].capitalize
        end
      end
    end
  end

  def check_email

    return if !self.email

    self.email = self.email.downcase
  end

  def check_login

    # use email as login if not given
    if !self.login && self.email
      self.login = self.email
    end

    # if email has changed, login is old email, change also login
    if self.changes && self.changes['email']
      if self.changes['email'][0] == self.login
        self.login = self.email
      end
    end

    # check if login already exists
    return if !self.login

    self.login = self.login.downcase
    check      = true
    while check
      exists = User.where( login: self.login ).first
      if exists && exists.id != self.id
        self.login = self.login + rand(999).to_s
      else
        check = false
      end
    end
  end

  def avatar_check

    return if !self.email
    return if self.email.empty?

    # save/update avatar
    avatar = Avatar.auto_detection(
      object: 'User',
      o_id: self.id,
      url: self.email,
      source: 'app',
      updated_by_id: self.updated_by_id,
      created_by_id: self.updated_by_id,
    )

    # update user link
    return if !avatar

    self.update_column( :image, avatar.store_hash )
    self.cache_delete
  end

  def avatar_destroy
    Avatar.remove( 'User', self.id )
  end

  def check_password

    # set old password again if not given
    if self.password == '' || !self.password

      # get current record
      if self.id
        #current = User.find(self.id)
        #self.password = current.password
        self.password = self.password_was
      end

    end

    # crypt password if not already crypted
    return if !self.password
    return if self.password =~ /^\{sha2\}/

    crypted       = Digest::SHA2.hexdigest( self.password )
    self.password = "{sha2}#{crypted}"
  end
end
