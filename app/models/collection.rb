class Collection < ApplicationRecord
  belongs_to :shop

  validates :shopify_uuid, presence: true, uniqueness: { scope: :shop_id }
  validates :title, presence: true
end