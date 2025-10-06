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
end
