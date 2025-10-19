# frozen_string_literal: true

# Register custom Active Storage analyzers
# Prepend our custom AudioMetadataAnalyzer so it runs instead of the default AudioAnalyzer
Rails.application.config.after_initialize do
  # Remove the default AudioAnalyzer
  Rails.application.config.active_storage.analyzers.delete(ActiveStorage::Analyzer::AudioAnalyzer)

  # Add our custom analyzer that includes ID3 metadata extraction
  Rails.application.config.active_storage.analyzers.prepend(AudioMetadataAnalyzer)
end
