class Shop < ApplicationRecord
  include ShopifyApp::ShopSessionStorageWithScopes

  include Uninstallable
  include Shopify::Collectionable
  include Shopify::Productable

  has_many :recordings, dependent: :destroy

  has_many :single_tracks, dependent: :destroy
  has_many :albums, dependent: :destroy
  has_many :album_tracks, dependent: :destroy

  encrypts :shopify_domain, deterministic: true, downcase: true
  encrypts :shopify_token

  # Helper method to build recordables with a unified interface
  def build_recordable(type:, **attributes)
    recordable_association_for(type).build(**attributes)
  end

  # Helper method to access recordable associations by type
  def recordable_association_for(type)
    case type.to_s
    when "SingleTrack"
      single_tracks
    when "Album"
      albums
    when "AlbumTrack"
      album_tracks
    else
      raise ArgumentError, "Unknown recordable type: #{type}"
    end
  end

  def api_version
    ShopifyApp.configuration.api_version
  end

  def activate_api_session
    ShopifyAPI::Context.activate_session(shopify_session)
  end

  def shopify_session
    ShopifyAPI::Auth::Session.new(
      shop: shopify_domain,
      access_token: shopify_token
    )
  end
end
