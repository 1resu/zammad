# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
class Ticket::State < ApplicationModel
  belongs_to    :state_type, class_name: 'Ticket::StateType'
  validates     :name, presence: true

  latest_change_support

=begin

list tickets by customer

  states = Ticket::State.by_category('open') # open|closed|work_on|work_on_all|pending_reminder|pending_action

returns:

  state objects

=end

  def self.by_category(category)
    if category == 'open'
      return Ticket::State.where(
        state_type_id: Ticket::StateType.where( name: ['new', 'open', 'pending reminder', 'pending action'] )
      )
    elsif category == 'pending_reminder'
      return Ticket::State.where(
        state_type_id: Ticket::StateType.where( name: ['pending reminder'] )
      )
    elsif category == 'pending_action'
      return Ticket::State.where(
        state_type_id: Ticket::StateType.where( name: ['pending action'] )
      )
    elsif category == 'work_on'
      return Ticket::State.where(
        state_type_id: Ticket::StateType.where( name: ['new', 'open'] )
      )
    elsif category == 'work_on_all'
      return Ticket::State.where(
        state_type_id: Ticket::StateType.where( name: ['new', 'open', 'pending reminder'] )
      )
    elsif category == 'closed'
      return Ticket::State.where(
        state_type_id: Ticket::StateType.where( name: ['closed'] )
      )
    end
    fail "Unknown category '#{category}'"
  end

=begin

check if state is ignored for escalation

  state = Ticket::State.lookup( :name => 'state name' )

  result = state.ignore_escalation?

returns:

  true/false

=end

  def ignore_escalation?
    ignore_escalation = %w(removed closed merged)
    return true if ignore_escalation.include?( name )
    false
  end
end
