class Product < ApplicationRecord
  belongs_to :shop

  has_many :variants, dependent: :destroy
  has_many :recordings, -> { where(type: "Recording") }, class_name: "Recording"

  scope :active, -> { where(discarded_at: nil) }
  scope :discarded, -> { where.not(discarded_at: nil) }

  def discard!
    update!(discarded_at: Time.current)
    product.variants.update_all(discarded_at: product.discarded_at)
  end

  def discarded?
    discarded_at.present?
  end

  def kept? = !discarded?
end
