# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Group < ApplicationModel
  has_and_belongs_to_many  :users,         after_add: :cache_update, after_remove: :cache_update
  belongs_to               :email_address
  belongs_to               :signature
  validates                :name, presence: true

  activity_stream_support  role: Z_ROLENAME_ADMIN
  history_support
  latest_change_support
end
