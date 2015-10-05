# encoding: utf-8
require 'browser_test_helper'

class AgentTicketActionLevel6Test < TestCase
  def test_ticket

    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    #
    # attachment checks - new ticket
    #

    # create new ticket with no attachment, attachment check should pop up
    ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'test 6 - ticket 1',
        body: 'test 6 - ticket 1 - with the word attachment, but not attachment atteched it should give an warning on submit',
      },
      do_not_submit: true,
    )
    sleep 1

    # submit form
    click( css: '.content.active button.js-submit' )
    sleep 2

    # check warning
    alert = @browser.switch_to.alert
    alert.dismiss()
    #alert.accept()
    #alert = alert.text

    # add attachment, attachment check should quiet
    @browser.execute_script( "App.TestHelper.attachmentUploadFake('.active .richtext .attachments')" )

    # submit form
    click( css: '.content.active button.js-submit' )
    sleep 5

    # no warning
    #alert = @browser.switch_to.alert

    # check if ticket is shown
    location_check( url: '#ticket/zoom/' )
    sleep 2
    ticket_number = @browser.find_elements( { css: '.active .ticketZoom-header .ticket-number' } )[0].text

    #
    # attachment checks - update ticket
    #

    # update ticket with no attachment, attachment check should pop up
    ticket_update(
      data: {
        body: 'test 6 - ticket 1-1 - with the word attachment, but not attachment atteched it should give an warning on submit',
      },
      do_not_submit: true,
    )

    # submit form
    click(
      css: '.active .js-submit',
    )
    sleep 2

    # check warning
    alert = @browser.switch_to.alert
    alert.dismiss()

    # add attachment, attachment check should quiet
    @browser.execute_script( "App.TestHelper.attachmentUploadFake('.active .article-add .textBubble .attachments')" )

    # submit form
    click(
      css: '.active .js-submit',
    )
    sleep 2

    # no warning
    #alert = @browser.switch_to.alert

    # check if article exists

    # discard changes should gone away
    watch_for_disappear(
      css: '.content.active .js-reset',
      value: '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )
    ticket_verify(
      data: {
        body: '',
      },
    )

    # check content and edit screen in instance 1
    match(
      css: '.active div.ticket-article',
      value: 'test 6 - ticket 1-1',
    )

    #
    # ticket customer change checks
    #

    # use current session
    browser1 = @browser

    browser2 = browser_instance
    login(
      browser: browser2,
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all(
      browser: browser2,
    )
    random     = 'ticket-actions-6-test-' + rand(999_999).to_s
    user_email = random + '@example.com'
    user_create(
      browser: browser2,
      data: {
        firstname: 'Action6 Firstname' + random,
        lastname: 'Action6 Lastname' + random,
        email: user_email,
        password: 'some-pass',
      },
    )

    # update customer, check if new customer is shown in side bar
    ticket_open_by_search(
      browser: browser2,
      number: ticket_number,
    )
    ticket_update(
      browser: browser2,
      data: {
        customer: user_email,
      },
      do_not_submit: true,
    )

    # check if customer has changed in second browser
    click( browser: browser1, css: '.active .tabsSidebar-tab[data-tab="customer"]')
    watch_for(
      browser: browser1,
      css: '.active .tabsSidebar',
      value: user_email,
    )

    #
    # modify customer
    #

    # modify customer
    click( browser: browser1, css: '.active .sidebar[data-tab="customer"] .js-actions .dropdown-toggle')
    click( browser: browser1, css: '.active .sidebar[data-tab="customer"] .js-actions [data-type="customer-edit"]')
    sleep 2
    set( browser: browser1, css: '.modal [name="address"]', value: 'some new address' )
    click( browser: browser1, css: '.modal .js-submit')

    # verify is customer has chnaged other browser too
    click( browser: browser2, css: '.active .tabsSidebar-tab[data-tab="customer"]')
    watch_for(
      browser: browser2,
      css: '.active .sidebar[data-tab="customer"]',
      value: 'some new address',
    )

    #
    # ticket customer organization change checks
    #

    # change org of customer, check if org is shown in sidebar
    click( browser: browser1, css: '.active .sidebar[data-tab="customer"] .js-actions .dropdown-toggle')
    click( browser: browser1, css: '.active .sidebar[data-tab="customer"] .js-actions [data-type="customer-edit"]')
    sleep 2
    set( browser: browser1, css: '.modal .js-input', value: 'zammad' )
    click( browser: browser1, css: '.modal .js-input' )
    click( browser: browser1, css: '.modal .js-option' )

    click( browser: browser1, css: '.modal .js-submit')

    # check if org has changed in second browser
    sleep 3
    click( browser: browser2, css: '.active .tabsSidebar-tab[data-tab="organization"]')
    watch_for(
      browser: browser2,
      css: '.active .sidebar[data-tab="organization"]',
      value: 'Zammad Foundation',
    )

    #
    # form change/reset checks
    #

    # some form reset checks
  end
end
