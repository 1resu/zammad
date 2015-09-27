# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class CalendarSubscriptions::Tickets

  def initialize(user, preferences)
    @user        = user
    @preferences = preferences
  end

  def all

    events_data = []
    return events_data if @preferences.empty?

    events_data += new_open
    events_data += pending
    events_data += escalation

    events_data
  end

  def owner_ids(method)

    owner_ids = []

    return owner_ids if @preferences.empty?
    return owner_ids if !@preferences[ method ]
    return owner_ids if @preferences[ method ].empty?

    preferences = @preferences[ method ]

    if preferences[:own]
      owner_ids = [ @user.id ]
    end
    if preferences[:not_assigned]
      owner_ids.push( 1 )
    end

    owner_ids
  end

  def new_open

    events_data = []
    owner_ids   = owner_ids(:new_open)
    return events_data if owner_ids.empty?

    condition = {
      'tickets.owner_id' => {
        operator: 'is',
        value: owner_ids,
      },
      'tickets.state_id' => {
        operator: 'is',
        value: Ticket::State.where(
          state_type_id: Ticket::StateType.where(
            name: %w(new open),
          ),
        ).map(&:id),
      },
    }

    tickets = Ticket.search(
      current_user: @user,
      condition: condition,
    )

    user_locale       = @user.preferences['locale'] || 'en'
    translated_ticket = Translation.translate(user_locale, 'ticket')

    events_data = []
    tickets.each do |ticket|

      event_data = {}

      translated_state = Translation.translate(user_locale, ticket.state.name)

      event_data[:dtstart]     = Icalendar::Values::Date.new( Time.zone.today )
      event_data[:dtend]       = Icalendar::Values::Date.new( Time.zone.today )
      event_data[:summary]     = "#{translated_state} #{translated_ticket}: '#{ticket.title}'"
      event_data[:description] = "T##{ticket.number}"

      events_data.push event_data
    end

    events_data
  end

  def pending

    events_data = []
    owner_ids   = owner_ids(:pending)
    return events_data if owner_ids.empty?

    condition = {
      'tickets.owner_id' => {
        operator: 'is',
        value: owner_ids,
      },
      'tickets.state_id' => {
        operator: 'is',
        value: Ticket::State.where(
          state_type_id: Ticket::StateType.where(
            name: [
              'pending reminder',
              'pending action',
            ],
          ),
        ).map(&:id),
      },
    }

    tickets = Ticket.search(
      current_user: @user,
      condition: condition,
    )

    user_locale       = @user.preferences['locale'] || 'en'
    translated_ticket = Translation.translate(user_locale, 'ticket')

    events_data = []
    tickets.each do |ticket|

      next if !ticket.pending_time

      event_data = {}

      pending_time = ticket.pending_time
      if pending_time < Time.zone.today
        pending_time = Time.zone.today
      end

      translated_state = Translation.translate(user_locale, ticket.state.name)

      event_data[:dtstart]     = Icalendar::Values::DateTime.new( pending_time )
      event_data[:dtend]       = Icalendar::Values::DateTime.new( pending_time )
      event_data[:summary]     = "#{translated_state} #{translated_ticket}: '#{ticket.title}'"
      event_data[:description] = "T##{ticket.number}"

      events_data.push event_data
    end

    events_data
  end

  def escalation

    events_data = []
    owner_ids   = owner_ids(:escalation)
    return events_data if owner_ids.empty?

    condition = {
      'tickets.owner_id' => {
        operator: 'is',
        value: owner_ids,
      },
      'tickets.escalation_time' => {
        operator: 'is not',
        value: nil,
      }
    }

    tickets = Ticket.search(
      current_user: @user,
      condition: condition,
    )

    user_locale                  = @user.preferences['locale'] || 'en'
    translated_ticket_escalation = Translation.translate(user_locale, 'ticket escalation')

    tickets.each do |ticket|

      next if !ticket.escalation_time

      event_data = {}

      escalation_time = ticket.escalation_time
      if escalation_time < Time.zone.today
        escalation_time = Time.zone.today
      end

      event_data[:dtstart]     = Icalendar::Values::DateTime.new( escalation_time )
      event_data[:dtend]       = Icalendar::Values::DateTime.new( escalation_time )
      event_data[:summary]     = "#{translated_ticket_escalation}: '#{ticket.title}'"
      event_data[:description] = "T##{ticket.number}"

      events_data.push event_data
    end

    events_data
  end
end
