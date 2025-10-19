class Shopify::AudioUploadsController < Shopify::AuthenticatedController
  include AudioValidations

  before_action -> { validate_size(file_param) }
  before_action -> { validate_content_type(file_param) }

  def create
    @blob = ActiveStorage::Blob.create_and_upload!(
      io: file_param.tempfile,
      filename: file_param.original_filename,
      content_type: file_param.content_type
    )

    @blob.analyze

    render json: {
      blob: @blob.as_json(
        methods: %i[signed_id],
        only: %i[filename content_type]
      ).merge({
        human_size: number_to_human_size(@blob.byte_size),
        cover_art: @blob.metadata["cover_art"],
        artist: @blob.metadata["artist"],
        title: @blob.metadata["title"]
      })
    }, status: :created
  end

  private

  def file_param
    params.require(:file)
  end
end
