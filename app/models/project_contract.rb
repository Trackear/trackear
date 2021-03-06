# frozen_string_literal: true

class ProjectContract < ApplicationRecord
  acts_as_paranoid

  belongs_to :project
  belongs_to :user
  has_many :activity_tracks

  validates :project, presence: true
  validates :user, presence: true
  validates :activity, presence: true
  validates :active_from, date: { before: :ends_at }
  validates :ends_at, date: { after: :active_from }
  validates :project_rate, numericality: { greater_than_or_equal_to: :user_rate }
  validates :user_rate, numericality: { greater_than_or_equal_to: 0 }, unless: :user_fixed_rate?
  # validates :user_fixed_rate, numericality: { greater_than_or_equal_to: 0 }, unless: :user_rate?
  # validate :dates_do_not_collide_with_existing_contracts

  scope :only_team, -> { where.not(activity: 'Client') }
  scope :in_range, ->(from, to) { where(['active_from >= ? and ends_at >= ?', from, to]) }
  scope :active_in, ->(date) { where(['active_from <= ? and ends_at >= ?', date, date]) }
  scope :currently_active, -> { active_in(Date.today) }

  def self.from_invite(params)
    user = User.by_email_or_create(params[:user_email])
    params.delete(:user_email)
    new(params.merge(
          user: user,
          active_from: DateTime.now,
          ends_at: DateTime.now + 100.years
        ))
  end

  def dates_do_not_collide_with_existing_contracts
    return unless user.present?

    user_contracts = user.project_contracts.where(project: project).where.not(id: id)
    contracts_collide = user_contracts.active_in(active_from).or(user_contracts.active_in(ends_at))
    if contracts_collide.any?
      errors.add(:user_id, 'has contracts colliding with the selected dates')
    end
  end

  def active_in?(date)
    return false if date.nil? || active_from.nil? || ends_at.nil?

    date.between?(active_from, ends_at)
  end

  def currently_active?
    today = Date.today
    active_in? today
  end

  def deferred?
    return false if active_from.nil?

    today = Date.today
    today < active_from
  end

  def finished?
    !currently_active? && !deferred?
  end
end
