# frozen_string_literal: true

require "taglib"

# Custom analyzer that extends Active Storage's AudioAnalyzer
# to extract ID3 metadata (title, cover art) in addition to
# standard audio properties (duration, bit_rate, sample_rate)
class AudioMetadataAnalyzer < ActiveStorage::Analyzer::AudioAnalyzer
  def self.accept?(blob)
    blob.audio?
  end

  # Override metadata to include ID3 tag information
  # Calls super to get duration, bit_rate, sample_rate, and tags
  # Then merges in title and cover_art from ID3 tags
  def metadata
    super.merge(id3_metadata).compact
  end

  private

  # Extract ID3 metadata (title, artist, and cover art) using TagLib
  def id3_metadata
    download_blob_to_tempfile do |file|
      {
        title: extract_title(file),
        artist: extract_artist(file),
        cover_art: extract_cover_art(file)
      }
    end
  rescue => e
    logger.error "Failed to extract ID3 metadata: #{e.message}"
    {}
  end

  # Extract song title from ID3 tags
  def extract_title(file)
    TagLib::FileRef.open(file.path) do |fileref|
      return nil if fileref.null?
      tag = fileref.tag
      tag&.title
    end
  rescue => e
    logger.error "Failed to extract title: #{e.message}"
    nil
  end

  # Extract artist name from ID3 tags
  def extract_artist(file)
    TagLib::FileRef.open(file.path) do |fileref|
      return nil if fileref.null?
      tag = fileref.tag
      tag&.artist
    end
  rescue => e
    logger.error "Failed to extract artist: #{e.message}"
    nil
  end

  # Extract cover art from ID3 tags and return as base64 data URI
  def extract_cover_art(file)
    # Only extract from MPEG/MP3 files for now
    return nil unless blob.content_type == "audio/mpeg"

    TagLib::MPEG::File.open(file.path) do |mpeg_file|
      id3v2_tag = mpeg_file.id3v2_tag
      return nil unless id3v2_tag

      # Find the APIC frame (Attached Picture)
      frame_list = id3v2_tag.frame_list("APIC")
      return nil if frame_list.empty?

      picture = frame_list.first
      return nil unless picture

      # Get the image data
      image_data = picture.picture
      mime_type = picture.mime_type || "image/jpeg"

      # Convert to base64 data URI
      base64_data = Base64.strict_encode64(image_data)
      "data:#{mime_type};base64,#{base64_data}"
    end
  rescue => e
    logger.error "Failed to extract cover art: #{e.message}"
    nil
  end
end
