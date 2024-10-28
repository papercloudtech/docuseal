# frozen_string_literal: true

# == Schema Information
#
# Table name: webhook_urls
#
#  id         :bigint           not null, primary key
#  events     :text             not null
#  secret     :text
#  sha1       :string           not null
#  url        :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_webhook_urls_on_account_id  (account_id)
#  index_webhook_urls_on_sha1        (sha1)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class WebhookUrl < ApplicationRecord
  EVENTS = %w[
    form.viewed
    form.started
    form.completed
    form.declined
    template.created
    template.updated
    submission.created
    submission.archived
  ].freeze

  belongs_to :account

  attribute :events, :string, default: -> { %w[form.viewed form.started form.completed form.declined] }

  serialize :events, coder: JSON
  serialize :secret, coder: JSON

  scope :with_event, ->(event) { with_events([event]) }
  scope :with_events, lambda { |events|
    where(events.map do |event|
      Arel::Table.new(:webhook_urls)[:events].matches("%\"#{event}\"%")
    end.reduce(:or))
  }

  before_validation :set_sha1

  encrypts :url, :secret

  def set_sha1
    self.sha1 = Digest::SHA1.hexdigest(url)
  end
end
