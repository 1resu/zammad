# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::CloseTime < ActiveRecord::Observer
  observe 'ticket'

  def after_create(record)
    _check(record)
  end

  def after_update(record)
    _check(record)
  end

  private
  def _check(record)
    #      puts 'check close time'

    # return if we run import mode
    return if Setting.get('import_mode')

    # check if close_time is already set
    return true if record.close_time

    # check if ticket is closed now
    state = Ticket::State.lookup( :id => record.state_id )
    state_type = Ticket::StateType.lookup( :id => state.state_type_id )
    return true if state_type.name != 'closed'

    # set close_time
    record.close_time = Time.now

    # save ticket
    record.save
  end
end
