class Recording < Variant
  belongs_to :recordable, polymorphic: true, optional: true

  delegated_type :recordable, types: %w[SingleTrack Album AlbumTrack], optional: true

  # Scopes for different recording types
  scope :singles, -> { where(recordable_type: "SingleTrack") }
  scope :albums, -> { where(recordable_type: "Album") }
  scope :tracks, -> { where(recordable_type: "AlbumTrack") }
  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  # Archival methods
  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end
end
