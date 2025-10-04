module Recordable
  extend ActiveSupport::Concern

  included do
    has_one :recording, as: :recordable, dependent: :destroy
    has_one :product, through: :recording

    belongs_to :shop, default: -> { recording.shop }
  end

  # Since Recording now inherits from Variant, this returns self
  def variant
    recording
  end
end
