# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Sso
  include ApplicationLib

=begin

authenticate user via username and password

  result = Sso.check( params )

returns

  result = user_model # if authentication was successfully

=end

  def self.check(params)

    # use std. auth backends
    config = [
      {
        adapter: 'Sso::Env',
      },
      {
        adapter: 'Sso::Otrs',
        required_group_ro: 'stats',
        group_rw_role_map: {
          'admin' => 'Admin',
          'stats' => 'Report',
        },
        group_ro_role_map: {
          'stats' => 'Report',
        },
        always_role: {
          'Agent' => true,
        },
      },
    ]

    # added configured backends
    Setting.where( area: 'Security::SSO' ).each {|setting|
      if setting.state[:value]
        config.push setting.state[:value]
      end
    }

    # try to login against configure auth backends
    user_auth = nil
    config.each {|config_item|
      next if !config_item[:adapter]

      # load backend
      backend = load_adapter( config_item[:adapter] )
      next if !backend

      user_auth = backend.check( params, config_item )

      # auth not ok
      next if !user_auth

      Rails.logger.info "Authentication against #{config_item[:adapter]} for user #{user.login} ok."

      # remember last login date
      user_auth.update_last_login

      return user_auth
    }
    nil
  end
end
