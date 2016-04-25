# encoding: utf-8
require 'test_helper'

class NotificationFactoryMailerTest < ActiveSupport::TestCase

  Translation.load('de-de')

  test 'notifications send' do
    result = NotificationFactory::Mailer.send(
      recipient: User.find(2),
      subject: 'sime subject',
      body: 'some body',
      content_type: '',
    )
    assert_match('some body', result.to_s)
    assert_match('text/plain', result.to_s)
    assert_no_match('text/html', result.to_s)

    result = NotificationFactory::Mailer.send(
      recipient: User.find(2),
      subject: 'sime subject',
      body: 'some body',
      content_type: 'text/plain',
    )
    assert_match('some body', result.to_s)
    assert_match('text/plain', result.to_s)
    assert_no_match('text/html', result.to_s)

    result = NotificationFactory::Mailer.send(
      recipient: User.find(2),
      subject: 'sime subject',
      body: 'some <span>body</span>',
      content_type: 'text/html',
    )
    assert_match('some body', result.to_s)
    assert_match('text/plain', result.to_s)
    assert_match('<span>body</span>', result.to_s)
    assert_match('text/html', result.to_s)
  end

  test 'notifications template' do
    groups = Group.where(name: 'Users')
    roles  = Role.where(name: 'Agent')
    agent1 = User.create_or_update(
      login: 'notification-template-agent1@example.com',
      firstname: 'Notification<b>xxx</b>',
      lastname: 'Agent1<b>yyy</b>',
      email: 'notification-template-agent1@example.com',
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

    result = NotificationFactory::Mailer.template(
      template: 'password_reset',
      locale: 'de-de',
      objects:  {
        user: agent1,
      },
    )
    assert_match('Zurücksetzen Deines', result[:subject])
    assert_match('wir haben eine Anfrage zum Zurücksetzen', result[:body])
    assert_match('Dein', result[:body])
    assert_match('Dein', result[:body])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_no_match('Your', result[:body])

    result = NotificationFactory::Mailer.template(
      template: 'password_reset',
      locale: 'de',
      objects:  {
        user: agent1,
      },
    )
    assert_match('Zurücksetzen Deines', result[:subject])
    assert_match('wir haben eine Anfrage zum Zurücksetzen', result[:body])
    assert_match('Dein', result[:body])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_no_match('Your', result[:body])

    result = NotificationFactory::Mailer.template(
      template: 'password_reset',
      locale: 'es-us',
      objects:  {
        user: agent1,
      },
    )
    assert_match('Reset your', result[:subject])
    assert_match('We received a request to reset the password', result[:body])
    assert_match('Your', result[:body])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_no_match('Dein', result[:body])

    ticket = Ticket.create(
      group_id: Group.lookup(name: 'Users').id,
      customer_id: User.lookup(email: 'nicole.braun@zammad.org').id,
      owner_id: User.lookup(login: '-').id,
      title: 'Welcome to Zammad!',
      state_id: Ticket::State.lookup(name: 'new').id,
      priority_id: Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: 1,
      created_by_id: 1,
    )
    article = Ticket::Article.create(
      ticket_id: ticket.id,
      type_id: Ticket::Article::Type.lookup(name: 'phone').id,
      sender_id: Ticket::Article::Sender.lookup(name: 'Customer').id,
      from: 'Zammad Feedback <feedback@zammad.org>',
      content_type: 'text/plain',
      body: 'Welcome!
<b>test123</b>',
      internal: false,
      updated_by_id: 1,
      created_by_id: 1,
    )

    changes = {}
    result = NotificationFactory::Mailer.template(
      template: 'ticket_create',
      locale: 'es-us',
      objects:  {
        ticket: ticket,
        article: article,
        recipient: agent1,
        changes: changes,
      },
    )
    assert_match('New Ticket', result[:subject])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_match('has been created by', result[:body])
    assert_match('&lt;b&gt;test123&lt;/b&gt;', result[:body])
    assert_match('Manage your notifications settings', result[:body])
    assert_no_match('Dein', result[:body])

    result = NotificationFactory::Mailer.template(
      template: 'ticket_create',
      locale: 'de-de',
      objects:  {
        ticket: ticket,
        article: article,
        recipient: agent1,
        changes: changes,
      },
    )
    assert_match('Neues Ticket', result[:subject])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_match('es wurde ein neues Ticket', result[:body])
    assert_match('&lt;b&gt;test123&lt;/b&gt;', result[:body])
    assert_match('Benachrichtigungseinstellungen Verwalten', result[:body])
    assert_no_match('Your', result[:body])

    article = Ticket::Article.create(
      ticket_id: ticket.id,
      type_id: Ticket::Article::Type.lookup(name: 'phone').id,
      sender_id: Ticket::Article::Sender.lookup(name: 'Customer').id,
      from: 'Zammad Feedback <feedback@zammad.org>',
      content_type: 'text/html',
      body: 'Welcome!
<b>test123</b>',
      internal: false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    changes = {
      state: %w(aaa bbb),
      group: %w(xxx yyy),
    }
    result = NotificationFactory::Mailer.template(
      template: 'ticket_update',
      locale: 'es-us',
      objects:  {
        ticket: ticket,
        article: article,
        recipient: agent1,
        changes: changes,
      },
    )
    assert_match('Updated Ticket', result[:subject])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_match('has been updated by', result[:body])
    assert_match('<b>test123</b>', result[:body])
    assert_match('Manage your notifications settings', result[:body])
    assert_no_match('Dein', result[:body])

    result = NotificationFactory::Mailer.template(
      template: 'ticket_update',
      locale: 'de-de',
      objects:  {
        ticket: ticket,
        article: article,
        recipient: agent1,
        changes: changes,
      },
    )
    assert_match('Ticket aktualisiert', result[:subject])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_match('wurde von', result[:body])
    assert_match('<b>test123</b>', result[:body])
    assert_match('Benachrichtigungseinstellungen Verwalten', result[:body])
    assert_no_match('Your', result[:body])

  end

  test 'notifications settings' do

    groups = Group.all
    roles  = Role.where(name: 'Agent')
    agent1 = User.create_or_update(
      login: 'notification-settings-agent1@example.com',
      firstname: 'Notification<b>xxx</b>',
      lastname: 'Agent1',
      email: 'notification-settings-agent1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

    agent2 = User.create_or_update(
      login: 'notification-settings-agent2@example.com',
      firstname: 'Notification<b>xxx</b>',
      lastname: 'Agent2',
      email: 'notification-settings-agent2@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

    group_notification_setting = Group.create_or_update(
      name: 'NotificationSetting',
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1 = Ticket.create(
      group_id: Group.lookup(name: 'Users').id,
      customer_id: User.lookup(email: 'nicole.braun@zammad.org').id,
      owner_id: User.lookup(login: '-').id,
      title: 'Notification Settings Test 1!',
      state_id: Ticket::State.lookup(name: 'new').id,
      priority_id: Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket2 = Ticket.create(
      group_id: Group.lookup(name: 'Users').id,
      customer_id: User.lookup(email: 'nicole.braun@zammad.org').id,
      owner_id: agent1.id,
      title: 'Notification Settings Test 2!',
      state_id: Ticket::State.lookup(name: 'new').id,
      priority_id: Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket3 = Ticket.create(
      group_id: group_notification_setting.id,
      customer_id: User.lookup(email: 'nicole.braun@zammad.org').id,
      owner_id: User.lookup(login: '-').id,
      title: 'Notification Settings Test 1!',
      state_id: Ticket::State.lookup(name: 'new').id,
      priority_id: Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket4 = Ticket.create(
      group_id: group_notification_setting.id,
      customer_id: User.lookup(email: 'nicole.braun@zammad.org').id,
      owner_id: agent1.id,
      title: 'Notification Settings Test 2!',
      state_id: Ticket::State.lookup(name: 'new').id,
      priority_id: Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    agent1.preferences[:notification_config][:group_ids] = nil
    agent1.save

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket1, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket2, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket3, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket4, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    agent2.preferences[:notification_config][:group_ids] = nil
    agent2.save

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket1, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket2, 'create')
    assert_equal(nil, result)

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket3, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket4, 'create')
    assert_equal(nil, result)

    # no group selection
    agent1.preferences[:notification_config][:group_ids] = []
    agent1.save

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket1, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket2, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket3, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket4, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    agent2.preferences[:notification_config][:group_ids] = []
    agent2.save

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket1, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket2, 'create')
    assert_equal(nil, result)

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket3, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket4, 'create')
    assert_equal(nil, result)

    agent1.preferences[:notification_config][:group_ids] = ['-']
    agent1.save

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket1, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket2, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket3, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket4, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    agent2.preferences[:notification_config][:group_ids] = ['-']
    agent2.save

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket1, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket2, 'create')
    assert_equal(nil, result)

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket3, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket4, 'create')
    assert_equal(nil, result)

    # dedecated group selection
    agent1.preferences[:notification_config][:group_ids] = [Group.lookup(name: 'Users').id]
    agent1.save

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket1, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket2, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket3, 'create')
    assert_equal(nil, result)

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket4, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    agent2.preferences[:notification_config][:group_ids] = [Group.lookup(name: 'Users').id]
    agent2.save

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket1, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket2, 'create')
    assert_equal(nil, result)

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket3, 'create')
    assert_equal(nil, result)
    assert_equal(nil, result)

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket4, 'create')
    assert_equal(nil, result)

  end

end