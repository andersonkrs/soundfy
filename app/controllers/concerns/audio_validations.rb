module AudioValidations
  extend ActiveSupport::Concern

  include ActionView::Helpers::NumberHelper

  ALLOWED_AUDIO_TYPES = {
    "audio/mpeg" => ".mp3",
    "audio/wav" => ".wav"
  }

  MAX_FILE_SIZE = 50.megabytes

  private

  def validate_size(file)
    return if file.size <= MAX_FILE_SIZE

    render json: {error: "File too large. Maximum size is #{number_to_human_size(MAX_FILE_SIZE)}"}, status: :unprocessable_entity
  end

  def validate_content_type(file)
    return if file.content_type.in? allowed_mime_types

    render json: {error: "Invalid file type. Allowed types: #{allowed_mime_types.join(", ")}"}, status: :unprocessable_entity
  end

  def allowed_content_types
    ALLOWED_AUDIO_TYPES.keys
  end

  def allowed_audio_extensions
    ALLOWED_AUDIO_TYPES.values
  end

  def allowed_mime_types
    @allowed_mime_types ||= ALLOWED_AUDIO_TYPES.keys
      .flat_map { |type| Mime::Type.lookup(type) }
      .compact
      .freeze
  end
end
