# encoding: utf-8
require 'test_helper'

class ActivityStreamTest < ActiveSupport::TestCase
  role  = Role.lookup( name: 'Admin' )
  group = Group.lookup( name: 'Users' )
  admin_user = User.create_or_update(
    login: 'admin',
    firstname: 'Bob',
    lastname: 'Smith',
    email: 'bob@example.com',
    password: 'some_pass',
    active: true,
    role_ids: [role.id],
    group_ids: [group.id],
    updated_by_id: 1,
    created_by_id: 1
  )
  current_user = User.lookup( login: 'nicole.braun@zammad.org' )

  test 'ticket+user' do
    tests = [

      # test 1
      {
        create: {
          ticket: {
            group_id: Group.lookup( name: 'Users' ).id,
            customer_id: current_user.id,
            owner_id: User.lookup( login: '-' ).id,
            title: 'Unit Test 1 (äöüß)!',
            state_id: Ticket::State.lookup( name: 'new' ).id,
            priority_id: Ticket::Priority.lookup( name: '2 normal' ).id,
            updated_by_id: current_user.id,
            created_by_id: current_user.id,
          },
          article: {
              updated_by_id: current_user.id,
              created_by_id: current_user.id,
              type_id: Ticket::Article::Type.lookup( name: 'phone' ).id,
              sender_id: Ticket::Article::Sender.lookup( name: 'Customer' ).id,
              from: 'Unit Test <unittest@example.com>',
              body: 'Unit Test 123',
              internal: false
          },
        },
        update: {
          ticket: {
            title: 'Unit Test 1 (äöüß) - update!',
            state_id: Ticket::State.lookup( name: 'open' ).id,
            priority_id: Ticket::Priority.lookup( name: '1 low' ).id,
          },
        },
        update2: {
          ticket: {
            title: 'Unit Test 2 (äöüß) - update!',
            priority_id: Ticket::Priority.lookup( name: '2 normal' ).id,
          },
        },
        check: [
         {
            result: true,
            object: 'Ticket',
            type: 'updated',
          },
          {
            result: true,
            object: 'Ticket::Article',
            type: 'created',
          },
          {
            result: true,
            object: 'Ticket',
            type: 'created',
          },
          {
            result: false,
            object: 'User',
            type: 'updated',
            o_id: current_user.id,
          },
        ]
      },
    ]
    tickets = []
    tests.each { |test|

      ticket = nil
      article = nil


      ticket = Ticket.create( test[:create][:ticket] )
      test[:check][0][:o_id]          = ticket.id
      test[:check][2][:o_id]          = ticket.id
      test[:check][2][:created_at]    = ticket.created_at
      test[:check][2][:created_by_id] = current_user.id
      sleep 2

      test[:create][:article][:ticket_id] = ticket.id
      article = Ticket::Article.create( test[:create][:article] )
      test[:check][1][:o_id]          = article.id
      test[:check][1][:created_at]    = article.created_at
      test[:check][1][:created_by_id] = current_user.id

      assert_equal( ticket.class.to_s, 'Ticket' )
      assert_equal( article.class.to_s, 'Ticket::Article' )

      # update ticket
      if test[:update][:ticket]
        ticket.update_attributes( test[:update][:ticket] )

        # check updated user
        test[:check][3][:o_id]          = current_user.id
        test[:check][3][:created_at]    = ticket.created_at
        test[:check][3][:created_by_id] = current_user.id
      end
      if test[:update2][:ticket]
        ticket = Ticket.find( ticket.id )
        ticket.update_attributes( test[:update2][:ticket] )
      end
      if test[:update][:article]
        article.update_attributes( test[:update][:article] )
      end

      sleep 15
      if test[:update][:ticket]
        ticket.update_attributes( test[:update][:ticket] )
      end
      if test[:update2][:ticket]
        ticket.update_attributes( test[:update2][:ticket] )
      end

      # remember ticket
      tickets.push ticket

      # check activity_stream
      activity_stream_check( admin_user.activity_stream(3), test[:check] )
    }

    # delete tickets
    tickets.each { |ticket|
      ticket_id = ticket.id
      ticket.destroy
      found = Ticket.where( id: ticket_id ).first
      assert( !found, 'Ticket destroyed')
    }
  end

  test 'organization' do
    tests = [

      # test 1
      {
        create: {
          organization: {
            name: 'some name',
            updated_by_id: current_user.id,
            created_by_id: current_user.id,
          },
        },
        update1: {
          organization: {
            name: 'some name (äöüß)',
          },
        },
        update2: {
          organization: {
            name: 'some name 2 (äöüß)',
          },
        },
        check: [
          {
            result: true,
            object: 'Organization',
            type: 'updated',
          },
          {
            result: true,
            object: 'Organization',
            type: 'created',
          },
        ]
      },
    ]
    organizations = []
    tests.each { |test|

      organization = Organization.create( test[:create][:organization] )
      test[:check][0][:o_id]          = organization.id
      test[:check][0][:created_at]    = organization.created_at
      test[:check][0][:created_by_id] = current_user.id
      sleep 2

      assert_equal( organization.class.to_s, 'Organization' )

      if test[:update1][:organization]
        organization.update_attributes( test[:update1][:organization] )
        test[:check][1][:o_id]          = organization.id
        test[:check][1][:updated_at]    = organization.updated_at
        test[:check][1][:created_by_id] = current_user.id
        sleep 13
      end

      if test[:update2][:organization]
        organization.update_attributes( test[:update2][:organization] )
      end

      # remember organization
      organizations.push organization

      # check activity_stream
      activity_stream_check( admin_user.activity_stream(2), test[:check] )
    }

    # delete tickets
    organizations.each { |organization|
      organization_id = organization.id
      organization.destroy
      found = Organization.where( id: organization_id ).first
      assert( !found, 'Organization destroyed')
    }
  end


  test 'user with update check false' do
    tests = [

      # test 1
      {
        create: {
          user: {
            login: 'someemail@example.com',
            email: 'Bob Smith II <someemail@example.com>',
            updated_by_id: current_user.id,
            created_by_id: current_user.id,
          },
        },
        update1: {
          user: {
            firstname: 'Bob U',
            lastname: 'Smith U',
          },
        },
        check: [
          {
            result: true,
            object: 'User',
            type: 'created',
          },
          {
            result: false,
            object: 'User',
            type: 'updated',
          },
        ]
      },
    ]
    users = []
    tests.each { |test|

      user = User.create( test[:create][:user] )
      test[:check][0][:o_id]          = user.id
      test[:check][0][:created_at]    = user.created_at
      test[:check][0][:created_by_id] = current_user.id

      assert_equal( user.class.to_s, 'User' )

      if test[:update1][:user]
        user.update_attributes( test[:update1][:user] )
        test[:check][1][:o_id]          = user.id
        test[:check][1][:updated_at]    = user.updated_at
        test[:check][1][:created_by_id] = current_user.id
      end

      # remember organization
      users.push user

      # check activity_stream
      activity_stream_check( admin_user.activity_stream(3), test[:check] )
    }

    # delete tickets
    users.each { |user|
      user_id = user.id
      user.destroy
      found = User.where( id: user_id ).first
      assert( !found, 'User destroyed')
    }
  end

  test 'user with update check true' do
    tests = [

      # test 1
      {
        create: {
          user: {
            login: 'someemail@example.com',
            email: 'Bob Smith II <someemail@example.com>',
            updated_by_id: current_user.id,
            created_by_id: current_user.id,
          },
        },
        update1: {
          user: {
            firstname: 'Bob U',
            lastname: 'Smith U',
          },
        },
        update2: {
          user: {
            firstname: 'Bob',
            lastname: 'Smith',
          },
        },
        check: [
          {
            result: true,
            object: 'User',
            type: 'updated',
          },
          {
            result: true,
            object: 'User',
            type: 'created',
          },
        ]
      },
    ]
    users = []
    tests.each { |test|

      user = User.create( test[:create][:user] )
      test[:check][0][:o_id]          = user.id
      test[:check][0][:created_at]    = user.created_at
      test[:check][0][:created_by_id] = current_user.id

      assert_equal( user.class.to_s, 'User' )

      if test[:update1][:user]
        user.update_attributes( test[:update1][:user] )
        test[:check][1][:o_id]          = user.id
        test[:check][1][:updated_at]    = user.updated_at
        test[:check][1][:created_by_id] = current_user.id
      end

      # to verify update which need to be logged
      sleep 14

      if test[:update2][:user]
        user.update_attributes( test[:update2][:user] )
      end

      # remember organization
      users.push user

      # check activity_stream
      activity_stream_check( admin_user.activity_stream(2), test[:check] )
    }

    # delete tickets
    users.each { |user|
      user_id = user.id
      user.destroy
      found = User.where( id: user_id ).first
      assert( !found, 'User destroyed')
    }
  end

  def activity_stream_check( activity_stream_list, checks )
    #activity_stream_list = activity_stream_list.reverse
    #puts 'AS ' + activity_stream_list.inspect
    check_count = 0
    checks.each { |check_item|
      check_count += 1

      #puts '+++++++++++'
      #puts check_item.inspect
      check_list = 0
      activity_stream_list.each { |item|
        check_list += 1
        next if check_list != check_count
#        next if match
        #puts '--------'
        #puts item.inspect
        #puts check_item.inspect
        if check_item[:result]
          assert_equal( check_item[:object], item['object'] )
          assert_equal( check_item[:type], item['type'] )
          assert_equal( check_item[:o_id], item['o_id'] )
        else
          if check_item[:object] == item['object'] && check_item[:type] == item['type'] && check_item[:o_id] == item['o_id']
            assert( false, "entry should not exist #{ item['object'] }/#{ item['type'] }/#{ item['o_id'] }" )
          end
        end
      }
    }
  end

end
