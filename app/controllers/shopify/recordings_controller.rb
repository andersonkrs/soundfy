class Shopify::RecordingsController < Shopify::AuthenticatedController
  def index
    recordings_scope = Current.shop
      .recordings
      .includes(:product, :recordable)
      .active
      .order(created_at: :desc)

    @pagy, @recordings = pagy(recordings_scope)

    render(
      inertia: "Recordings/Index",
      props: {
        recordings: @recordings.as_json(include: %i[product]),
        pagy: @pagy.as_json
      }
    )
  end

  def new
    render inertia: "Recordings/New"
  end

  def create
    variant = Current.shop.variants.find_by(shopify_uuid: parsed_variant_uuid)

    variant.with_lock do
      recording = variant.becomes!(Recording)
      recording.build_recordable(type: SingleTrack)

      if recording.save
        redirect_to shopify_recordings_path, notice: "Recording created successfully"
      else
        redirect_to new_shopify_recording_path, inertia: {errors: recording.errors}
      end
    end
  end

  private

  def parsed_variant_uuid
    GlobalID.parse(recording_params[:variant_gid]).model_id
  end

  def recording_params
    params.require(:recordable).permit(:title, :variant_gid)
  end
end
