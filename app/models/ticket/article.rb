# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
class Ticket::Article < ApplicationModel
  load 'ticket/article/assets.rb'
  include Ticket::Article::Assets
  load 'ticket/article/history_log.rb'
  include Ticket::Article::HistoryLog
  load 'ticket/article/activity_stream_log.rb'
  include Ticket::Article::ActivityStreamLog

  belongs_to    :ticket
  belongs_to    :type,        class_name: 'Ticket::Article::Type'
  belongs_to    :sender,      class_name: 'Ticket::Article::Sender'
  belongs_to    :created_by,  class_name: 'User'
  belongs_to    :updated_by,  class_name: 'User'
  store         :preferences
  before_create :check_subject, :check_message_id_md5
  before_update :check_subject, :check_message_id_md5

  notify_clients_support

  activity_stream_support ignore_attributes: {
    type_id: true,
    sender_id: true,
    preferences: true,
  }

  history_support ignore_attributes: {
    type_id: true,
    sender_id: true,
    preferences: true,
  }

  private

  # strip not wanted chars
  def check_subject
    return if !subject
    subject.gsub!(/\s|\t|\r/, ' ')
  end

  # fillup md5 of message id to search easier on very long message ids
  def check_message_id_md5
    return if !message_id
    return if message_id_md5
    self.message_id_md5 = Digest::MD5.hexdigest(message_id.to_s)
  end

  class Flag < ApplicationModel
  end

  class Sender < ApplicationModel
    validates   :name, presence: true
    latest_change_support
  end

  class Type < ApplicationModel
    validates   :name, presence: true
    latest_change_support
  end
end
