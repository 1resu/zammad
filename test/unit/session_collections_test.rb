# encoding: utf-8
require 'test_helper'

class SessionCollectionsTest < ActiveSupport::TestCase

  test 'c collections' do

    UserInfo.current_user_id = 1

    # create users
    roles  = Role.where( :name => [ 'Agent', 'Admin'] )
    groups = Group.all

    agent1 = User.create_or_update(
      :login     => 'session-collections-agent-1',
      :firstname => 'Session',
      :lastname  => 'collections 1',
      :email     => 'session-collections-agent-1@example.com',
      :password  => 'agentpw',
      :active    => true,
      :roles     => roles,
      :groups    => groups,
    )
    agent1.roles = roles
    agent1.save

    roles  = Role.where( :name => [ 'Agent' ] )
    groups = Group.all

    agent2 = User.create_or_update(
      :login     => 'session-collections-agent-2',
      :firstname => 'Session',
      :lastname  => 'collections 2',
      :email     => 'session-collections-agent-2@example.com',
      :password  => 'agentpw',
      :active    => true,
      :roles     => roles,
      :groups    => groups,
    )
    agent2.roles = roles
    agent2.save

    roles  = Role.where( :name => [ 'Customer'] )
    customer1 = User.create_or_update(
      :login     => 'session-collections-customer-1',
      :firstname => 'Session',
      :lastname  => 'collections 2',
      :email     => 'session-collections-customer-1@example.com',
      :password  => 'customerpw',
      :active    => true,
      :roles     => roles,
    )
    customer1.roles = roles
    customer1.save

    collection_client1 = Sessions::Backend::Collections.new(agent1, nil, 'aaa-1', 3)
    collection_client2 = Sessions::Backend::Collections.new(agent2, nil, 'bbb-2', 3)
    collection_client3 = Sessions::Backend::Collections.new(customer1, nil, 'bbb-2', 3)

    # get whole collections
    result1 = collection_client1.push
    assert( result1, "check collections" )
    assert( check_if_collection_exists(result1, :Group), "check collections - after init" )
    assert( check_if_collection_exists(result1, :Role), "check collections - after init" )
    assert( check_if_collection_exists(result1, :Signature), "check collections - after init" )
    assert( check_if_collection_exists(result1, :EmailAddress), "check collections - after init" )
    sleep 1
    result2 = collection_client2.push
    assert( result2, "check collections" )
    assert( check_if_collection_exists(result2, :Group), "check collections - after init" )
    assert( check_if_collection_exists(result2, :Role), "check collections - after init" )
    assert( check_if_collection_exists(result2, :Signature), "check collections - after init" )
    assert( check_if_collection_exists(result2, :EmailAddress), "check collections - after init" )
    assert_equal( result1, result2, "check collections" )

    result3 = collection_client3.push
    assert( result3, "check collections" )
    assert( check_if_collection_exists(result3, :Group), "check collections - after init" )
    assert( check_if_collection_exists(result3, :Role), "check collections - after init" )
    assert( !check_if_collection_exists(result3, :Signature), "check collections - after init" )
    assert( !check_if_collection_exists(result3, :EmailAddress), "check collections - after init" )

    # next check should be empty
    result1 = collection_client1.push
    assert( result1.empty?, "check collections - recall" )
    sleep 0.4
    result2 = collection_client2.push
    assert( result2.empty?, "check collections - recall" )
    result3 = collection_client3.push
    assert( result3.empty?, "check collections - recall" )

    # change collection
    group = Group.first
    group.touch
    sleep 4

    # get whole collections
    result1 = collection_client1.push
    assert( result1, "check collections - after touch" )
    assert( check_if_collection_exists(result1, :Group), "check collections - after touch" )
    sleep 0.1
    result2 = collection_client2.push
    assert( result2, "check collections - after touch" )
    assert( check_if_collection_exists(result2, :Group), "check collections - after touch" )
    result3 = collection_client3.push
    assert( result3, "check collections - after touch" )
    assert( check_if_collection_exists(result3, :Group), "check collections - after touch" )

    # change collection
    org = Organization.create( :name => 'SomeOrg::' + rand(999999).to_s, :active => true, :member_ids => [customer1.id] )
    sleep 4

    # get whole collections
    result1 = collection_client1.push
    assert( result1, "check collections - after create" )
    assert( check_if_collection_exists(result1, :Organization, { :id => org.id, :member_ids => [customer1.id] } ), "check collections - after create with attributes" )
    sleep 0.3
    result2 = collection_client2.push
    assert( result2, "check collections - after create" )
    assert( check_if_collection_exists(result2, :Organization), "check collections - after create" )
    result3 = collection_client3.push
    assert( result3, "check collections - after create" )
    assert( check_if_collection_exists(result3, :Organization), "check collections - after create" )

    # next check should be empty
    sleep 1
    result1 = collection_client1.push
    assert( result1.empty?, "check collections - recall" )
    result2 = collection_client2.push
    assert( result2.empty?, "check collections - recall" )
    result3 = collection_client3.push
    assert( result3.empty?, "check collections - recall" )
  end

  def check_if_collection_exists(results, collection, attributes = nil)
    results.each {|result|
      next if !result
      if result[:collection] && result[:collection][collection]

        # check just if collection exists
        return true if !attributes

        # check if objetc with attributes in collection exists
        result[:collection][collection].each {|item|
          match_all = true
          attributes.each {|key, value|
            if item[ key.to_s ] != value
              match_all = false
            end
          }
          return true if match_all
        }
      end
    }
    nil
  end

end