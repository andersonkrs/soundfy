Rails.configuration.after_initialize do
  Rails.configuration.active_storage.analyzers.delete(ActiveStorage::Analyzer::AudioAnalyzer)

  # Add our custom analyzer that includes ID3 metadata extraction
  Rails.configuration.active_storage.analyzers.prepend(AudioMetadataAnalyzer)
end
