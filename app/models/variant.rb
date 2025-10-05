class Variant < ApplicationRecord
  belongs_to :shop
  belongs_to :product

  # Scope for regular variants (not STI subclasses)
  scope :regular, -> { where(type: nil) }
  scope :active, -> { where(discarded_at: nil) }
  scope :discarded, -> { where.not(discarded_at: nil) }

  def discard!
    update!(discarded_at: Time.current)
  end

  def discarded?
    discarded_at.present?
  end

  def kept? = !discarded?
end
