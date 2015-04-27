# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module User::Permission

=begin

check if user has access to user

  user   = User.find(123)
  result = user.permission( :type => 'rw', :current_user => User.find(123) )

returns

  result = true|false

=end

  def permission (data)

    # check customer
    if data[:current_user].is_role(Z_ROLENAME_CUSTOMER)

      # access ok if its own user
      return true if self.id == data[:current_user].id

      # no access
      return false
    end

    # check agent
    return true if data[:current_user].is_role(Z_ROLENAME_ADMIN)
    return true if data[:current_user].is_role('Agent')
    return false
  end

end
