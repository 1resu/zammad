# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::OnlineNotificationSeen < ActiveRecord::Observer
  observe 'ticket'

  def after_create(record)
    _check(record)
  end

  def after_update(record)
    _check(record)
  end

  private
  def _check(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # check if existing online notifications for this ticket should be set to seen
    return true if !record.online_notification_seen_state

    # set all online notifications to seen
    OnlineNotification.seen_by_object( 'Ticket', record.id )
  end
end