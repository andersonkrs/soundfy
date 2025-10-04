class Album < ApplicationRecord
  include Recordable

  has_many :album_tracks, -> { order(position: :asc) }, dependent: :destroy
  has_many :tracks, through: :album_tracks, source: :recording
end
