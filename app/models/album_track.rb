class AlbumTrack < ApplicationRecord
  include Recordable

  belongs_to :album

  validates :position, presence: true
  validates :position, uniqueness: { scope: [:shop_id, :album_id] }

  scope :ordered, -> { order(position: :asc) }
end
