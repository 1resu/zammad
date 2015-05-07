# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Ticket::Number
  include ApplicationLib

=begin

generate new ticket number

  result = Ticket::Number.generate

returns

  result = "1234556" # new ticket number

=end

  def self.generate

    # generate number
    (1..50_000).each {
      number = adapter.generate
      ticket = Ticket.find_by( number: number )
      return number if !ticket
    }
    fail "Can't generate new ticket number!"
  end

=begin

check if string contrains a valid ticket number

  result = Ticket::Number.check('some string [Ticket#123456]')

returns

  result = ticket # Ticket model of ticket with matching ticket number

=end

  def self.check(string)
    adapter.check(string)
  end

  def self.adapter

    # load backend based on config
    adapter_name = Setting.get('ticket_number')
    if !adapter_name
      fail 'Missing ticket_number setting option'
    end
    adapter = load_adapter(adapter_name)
    if !adapter
      fail "Can't load ticket_number adapter '#{adapter_name}'"
    end
    adapter
  end
end
