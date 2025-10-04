class Product < ApplicationRecord
  belongs_to :shop

  has_many :variants, dependent: :destroy
  has_many :recordings, -> { where(type: "Recording") }, class_name: "Recording"
end
