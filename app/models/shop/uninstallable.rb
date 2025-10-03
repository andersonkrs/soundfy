module Shop::Uninstallable
  extend ActiveSupport::Concern

  included do
    after_update_commit :schedule_incineration, if: :saved_change_to_shopify_uninstalled_at?
  end

  def uninstall
    shop.shopify_uninstalled_at = Time.current
    shop.shopify_domain = "#{shop.shopify_domain}_deleted_#{shop.shopify_uninstalled_at.to_fs(:number)}"
    shop.shopify_token = "{REDACTED}"
  end

  def uninstalled?
    shopify_domain.match?(/_deleted_\d{12}$/)
  end

  private

  def schedule_incineration
    # TODO: Schedule the incineration job couple days from now
  end
end
