# encoding: utf-8
require 'test_helper'

class TicketNotificationTest < ActiveSupport::TestCase

  # create agent1 & agent2
  groups = Group.where( name: 'Users' )
  roles  = Role.where( name: 'Agent' )
  agent1 = User.create_or_update(
    login: 'ticket-notification-agent1@example.com',
    firstname: 'Notification',
    lastname: 'Agent1',
    email: 'ticket-notification-agent1@example.com',
    password: 'agentpw',
    active: true,
    roles: roles,
    groups: groups,
    preferences: {
      locale: 'de-de',
    },
    updated_by_id: 1,
    created_by_id: 1,
  )
  agent2 = User.create_or_update(
    login: 'ticket-notification-agent2@example.com',
    firstname: 'Notification',
    lastname: 'Agent2',
    email: 'ticket-notification-agent2@example.com',
    password: 'agentpw',
    active: true,
    roles: roles,
    groups: groups,
    preferences: {
      locale: 'en-ca',
    },
    updated_by_id: 1,
    created_by_id: 1,
  )
  Group.create_if_not_exists(
    name: 'WithoutAccess',
    note: 'Test for notification check.',
    updated_by_id: 1,
    created_by_id: 1
  )

  # create customer
  roles    = Role.where( name: 'Customer' )
  customer = User.create_or_update(
    login: 'ticket-notification-customer@example.com',
    firstname: 'Notification',
    lastname: 'Customer',
    email: 'ticket-notification-customer@example.com',
    password: 'agentpw',
    active: true,
    roles: roles,
    groups: groups,
    updated_by_id: 1,
    created_by_id: 1,
  )

  test 'ticket notification simple' do

    # create ticket in group
    ticket1 = Ticket.create(
      title: 'some notification test 1',
      group: Group.lookup( name: 'Users'),
      customer: customer,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: customer.id,
      created_by_id: customer.id,
    )
    article_inbound = Ticket::Article.create(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: customer.id,
      created_by_id: customer.id,
    )
    assert( ticket1, 'ticket created - ticket notification simple' )

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off

    # verify notifications to agent1 + agent2
    assert_equal( 1, notification_check(ticket1, agent1), ticket1.id )
    assert_equal( 1, notification_check(ticket1, agent2), ticket1.id )

    # update ticket attributes
    ticket1.title    = "#{ticket1.title} - #2"
    ticket1.priority = Ticket::Priority.lookup( name: '3 high' )
    ticket1.save

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off

    # verify notifications to agent1 + agent2
    assert_equal( 2, notification_check(ticket1, agent1), ticket1.id )
    assert_equal( 2, notification_check(ticket1, agent2), ticket1.id )

    # add article to ticket
    article_note = Ticket::Article.create(
      ticket_id: ticket1.id,
      from: 'some person',
      subject: 'some note',
      body: 'some message',
      internal: true,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'note').first,
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
    )

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off

    # verify notifications to not to agent1 but to agent2
    assert_equal( 2, notification_check(ticket1, agent1), ticket1.id )
    assert_equal( 3, notification_check(ticket1, agent2), ticket1.id )

    # update ticket by user
    ticket1.owner_id      = agent1.id
    ticket1.updated_by_id = agent1.id
    ticket1.save
    article_note = Ticket::Article.create(
      ticket_id: ticket1.id,
      from: 'some person',
      subject: 'some note',
      body: 'some message',
      internal: true,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'note').first,
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
    )

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off

    # verify notifications to not to agent1 but to agent2
    assert_equal( 2, notification_check(ticket1, agent1), ticket1.id )
    assert_equal( 3, notification_check(ticket1, agent2), ticket1.id )

    # create ticket with agent1 as owner
    ticket2 = Ticket.create(
      title: 'some notification test 2',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      owner_id: agent1.id,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
    )
    article_inbound = Ticket::Article.create(
      ticket_id: ticket2.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'phone').first,
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
    )

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off
    assert( ticket2, 'ticket created' )

    # verify notifications to no one
    assert_equal( 0, notification_check(ticket2, agent1), ticket2.id )
    assert_equal( 0, notification_check(ticket2, agent2), ticket2.id )

    # update ticket
    ticket2.title         = "#{ticket2.title} - #2"
    ticket2.updated_by_id = agent1.id
    ticket2.priority      = Ticket::Priority.lookup( name: '3 high' )
    ticket2.save

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off

    # verify notifications to no one
    assert_equal( 0, notification_check(ticket2, agent1), ticket2.id )
    assert_equal( 0, notification_check(ticket2, agent2), ticket2.id )

    # update ticket
    ticket2.title         = "#{ticket2.title} - #3"
    ticket2.updated_by_id = agent2.id
    ticket2.priority      = Ticket::Priority.lookup( name: '2 normal' )
    ticket2.save

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off

    # verify notifications to agent1 and not to agent2
    assert_equal( 1, notification_check(ticket2, agent1), ticket2.id )
    assert_equal( 0, notification_check(ticket2, agent2), ticket2.id )



    # create ticket with agent2 and agent1 as owner
    ticket3 = Ticket.create(
      title: 'some notification test 3',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      owner_id: agent1.id,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: agent2.id,
      created_by_id: agent2.id,
    )
    article_inbound = Ticket::Article.create(
      ticket_id: ticket3.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'phone').first,
      updated_by_id: agent2.id,
      created_by_id: agent2.id,
    )

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off
    assert( ticket3, 'ticket created' )

    # verify notifications to agent1 and not to agent2
    assert_equal( 1, notification_check(ticket3, agent1), ticket3.id )
    assert_equal( 0, notification_check(ticket3, agent2), ticket3.id )

    # update ticket
    ticket3.title         = "#{ticket3.title} - #2"
    ticket3.updated_by_id = agent1.id
    ticket3.priority      = Ticket::Priority.lookup( name: '3 high' )
    ticket3.save

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off

    # verify notifications to no one
    assert_equal( 1, notification_check(ticket3, agent1), ticket3.id )
    assert_equal( 0, notification_check(ticket3, agent2), ticket3.id )

    # update ticket
    ticket3.title         = "#{ticket3.title} - #3"
    ticket3.updated_by_id = agent2.id
    ticket3.priority      = Ticket::Priority.lookup( name: '2 normal' )
    ticket3.save

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off

    # verify notifications to agent1 and not to agent2
    assert_equal( 2, notification_check(ticket3, agent1), ticket3.id )
    assert_equal( 0, notification_check(ticket3, agent2), ticket3.id )


    # update article / not notification should be sent
    article_inbound.internal = true
    article_inbound.save

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off

    # verify notifications not to agent1 and not to agent2
    assert_equal( 2, notification_check(ticket3, agent1), ticket3.id )
    assert_equal( 0, notification_check(ticket3, agent2), ticket3.id )


    delete = ticket1.destroy
    assert( delete, 'ticket1 destroy' )

    delete = ticket2.destroy
    assert( delete, 'ticket2 destroy' )

    delete = ticket3.destroy
    assert( delete, 'ticket3 destroy' )

  end

  test 'ticket notification events' do

    # create ticket in group
    ticket1 = Ticket.create(
      title: 'some notification event test 1',
      group: Group.lookup( name: 'Users'),
      customer: customer,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: customer.id,
      created_by_id: customer.id,
    )
    article_inbound = Ticket::Article.create(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: customer.id,
      created_by_id: customer.id,
    )
    assert( ticket1, 'ticket created' )

    # execute ticket events
    Observer::Ticket::Notification.transaction

    # update ticket attributes
    ticket1.title    = "#{ticket1.title} - #2"
    ticket1.priority = Ticket::Priority.lookup( name: '3 high' )
    ticket1.save

    list        = EventBuffer.list
    listObjects = Observer::Ticket::Notification.get_uniq_changes(list)

    assert_equal( 'some notification event test 1', listObjects[ticket1.id][:changes]['title'][0] )
    assert_equal( 'some notification event test 1 - #2', listObjects[ticket1.id][:changes]['title'][1] )
    assert_not( listObjects[ticket1.id][:changes]['priority'] )
    assert_equal( 2, listObjects[ticket1.id][:changes]['priority_id'][0] )
    assert_equal( 3, listObjects[ticket1.id][:changes]['priority_id'][1] )

    # update ticket attributes
    ticket1.title    = "#{ticket1.title} - #3"
    ticket1.priority = Ticket::Priority.lookup( name: '1 low' )
    ticket1.save

    list        = EventBuffer.list
    listObjects = Observer::Ticket::Notification.get_uniq_changes(list)

    assert_equal( 'some notification event test 1', listObjects[ticket1.id][:changes]['title'][0] )
    assert_equal( 'some notification event test 1 - #2 - #3', listObjects[ticket1.id][:changes]['title'][1] )
    assert_not( listObjects[ticket1.id][:changes]['priority'] )
    assert_equal( 2, listObjects[ticket1.id][:changes]['priority_id'][0] )
    assert_equal( 1, listObjects[ticket1.id][:changes]['priority_id'][1] )

  end


  test 'ticket notification template' do

    # create ticket in group
    ticket1 = Ticket.create(
      title: 'some notification template test 1 Bobs\'s resumé',
      group: Group.lookup( name: 'Users'),
      customer: customer,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: customer.id,
      created_by_id: customer.id,
    )
    article = Ticket::Article.create(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message\nnewline1 abc\nnewline2",
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: customer.id,
      created_by_id: customer.id,
    )
    assert( ticket1, 'ticket created - ticket notification template' )

    bg = Observer::Ticket::Notification::BackgroundJob.new(
      ticket_id: ticket1.id,
      article_id: article.id,
      type: 'update',
      changes: {
        'priority_id'  => [1, 2],
        'pending_time' => [nil, Time.parse('2015-01-11 23:33:47 UTC')],
      },
    )

    # check changed attributes
    human_changes = bg.human_changes(agent1,ticket1)
    assert( human_changes['Priority'], 'Check if attributes translated based on ObjectManager::Attribute' )
    assert( human_changes['Pending till'], 'Check if attributes translated based on ObjectManager::Attribute' )
    assert_equal( 'i18n(1 low)', human_changes['Priority'][0] )
    assert_equal( 'i18n(2 normal)', human_changes['Priority'][1] )
    assert_equal( 'i18n()', human_changes['Pending till'][0] )
    assert_equal( 'i18n(2015-01-11 23:33:47 UTC)', human_changes['Pending till'][1] )
    assert_not( human_changes['priority_id'] )
    assert_not( human_changes['pending_time'] )
    assert_not( human_changes['pending_till'] )

    # en template
    template = bg.template_update(agent2, ticket1, article, human_changes)
    assert( template[:subject] )
    assert( template[:body] )
    assert_match( /Priority/, template[:body] )
    assert_match( /1 low/, template[:body] )
    assert_match( /2 normal/, template[:body] )
    assert_match( /Pending till/, template[:body] )
    assert_match( /2015-01-11 23:33:47 UTC/, template[:body] )
    assert_match( /updated/i, template[:subject] )

    # en notification
    subject = NotificationFactory.build(
      locale: agent2.preferences[:locale],
      string: template[:subject],
      objects: {
        ticket: ticket1,
        article: article,
        recipient: agent2,
      }
    )
    assert_match( /Bobs's resumé/, subject )
    body = NotificationFactory.build(
      locale: agent2.preferences[:locale],
      string: template[:body],
      objects: {
        ticket: ticket1,
        article: article,
        recipient: agent2,
      }
    )
    assert_match( /Priority/, body )
    assert_match( /1 low/, body )
    assert_match( /2 normal/, body )
    assert_match( /Pending till/, body )
    assert_match( /2015-01-11 23:33:47 UTC/, body )
    assert_match( /update/, body )
    assert_no_match( /pending_till/, body )
    assert_no_match( /i18n/, body )

    # de template
    template = bg.template_update(agent1, ticket1, article, human_changes)
    assert( template[:subject] )
    assert( template[:body] )
    assert_match( /Priority/, template[:body] )
    assert_match( /1 low/, template[:body] )
    assert_match( /2 normal/, template[:body] )
    assert_match( /Pending till/, template[:body] )
    assert_match( /2015-01-11 23:33:47 UTC/, template[:body] )
    assert_match( /aktualis/, template[:subject] )

    # de notification
    subject = NotificationFactory.build(
      locale: agent1.preferences[:locale],
      string: template[:subject],
      objects: {
        ticket: ticket1,
        article: article,
        recipient: agent2,
      }
    )
    assert_match( /Bobs's resumé/, subject )
    body = NotificationFactory.build(
      locale: agent1.preferences[:locale],
      string: template[:body],
      objects: {
        ticket: ticket1,
        article: article,
        recipient: agent1,
      }
    )

    assert_match( /Priorität/, body )
    assert_match( /1 niedrig/, body )
    assert_match( /2 normal/, body )
    assert_match( /Warten/, body )
    assert_match( /2015-01-11 23:33:47 UTC/, body )
    assert_match( /aktualis/, body )
    assert_no_match( /pending_till/, body )
    assert_no_match( /i18n/, body )

    bg = Observer::Ticket::Notification::BackgroundJob.new(
      ticket_id: ticket1.id,
      article_id: article.id,
      type: 'update',
      changes: {
        title: ['some notification template test 1', 'some notification template test 1 #2'],
        priority_id: [2, 3],
      },
    )

    puts "hc #{human_changes.inspect}"
    # check changed attributes
    human_changes = bg.human_changes(agent1,ticket1)
    assert( human_changes['Title'], 'Check if attributes translated based on ObjectManager::Attribute' )
    assert( human_changes['Priority'], 'Check if attributes translated based on ObjectManager::Attribute' )
    assert_equal( 'i18n(2 normal)', human_changes['Priority'][0] )
    assert_equal( 'i18n(3 high)', human_changes['Priority'][1] )
    assert_equal( 'some notification template test 1', human_changes['Title'][0] )
    assert_equal( 'some notification template test 1 #2', human_changes['Title'][1] )
    assert_not( human_changes['priority_id'] )
    assert_not( human_changes['pending_time'] )
    assert_not( human_changes['pending_till'] )

    human_changes = bg.human_changes(agent2,ticket1)
    puts "hc2 #{human_changes.inspect}"

    template = bg.template_update(agent1, ticket1, article, human_changes)
    puts "t1 #{template.inspect}"

    template = bg.template_update(agent2, ticket1, article, human_changes)
    puts "t2 #{template.inspect}"



  end

  def notification_check(ticket, recipient)
    result = ticket.history_get()
    count  = 0
    result.each {|item|
      next if item['type'] != 'notification'
      next if item['object'] != 'Ticket'
      next if item['value_to'] !~ /#{recipient.email}/i
      count += 1
    }
    count
  end
end
