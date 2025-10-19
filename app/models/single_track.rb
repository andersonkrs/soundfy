class SingleTrack < ApplicationRecord
  include Recordable

  has_one_attached :audio_file
end
