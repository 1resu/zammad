# encoding: utf-8
require 'browser_test_helper'

class SwitchToUserTest < TestCase
  def test_agent_user
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    click( css: 'a[href="#manage"]' )
    click( css: 'a[href="#manage/users"]' )

    set(
      css:   '#content .js-search',
      value: 'nicole',
    )
    sleep 3

    @browser.mouse.move_to( @browser.find_elements( { css: '#content .table-overview tbody tr:first-child' } )[0] )
    click(
      css: '#content .icon-switchView',
    )

    watch_for(
      :css     => '.switchBackToUser',
      :value   => 'zammad looks like',
    )
    watch_for(
      :css     => '.switchBackToUser',
      :value   => 'Nicole',
    )
    login = @browser.find_elements( { css: '.user-menu .user a' } )[0].attribute('title')
    assert_equal(login, 'nicole.braun@zammad.org')

    click( css: '.switchBackToUser .js-close' )

    login = @browser.find_elements( { css: '.user-menu .user a' } )[0].attribute('title')
    assert_equal(login, 'master@example.com')

  end
end
