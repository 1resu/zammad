# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'history'

class Observer::Tag::TicketHistory < ActiveRecord::Observer
  observe 'tag'

  def after_create(record)

    # just process ticket object tags
    return true if record.tag_object.name != 'Ticket'

    # add ticket history
    History.add(
      o_id: record.o_id,
      history_type: 'added',
      history_object: 'Ticket',
      history_attribute: 'tag',
      value_to: record.tag_item.name,
    )
  end

  def after_destroy(record)

    # just process ticket object tags
    return true if record.tag_object.name != 'Ticket'

    # add ticket history
    History.add(
      o_id: record.o_id,
      history_type: 'removed',
      history_object: 'Ticket',
      history_attribute: 'tag',
      value_to: record.tag_item.name,
    )
  end
end
