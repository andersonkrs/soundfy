module Shop::Uninstallable
  extend ActiveSupport::Concern

  included do
    define_model_callbacks :uninstallation, only: :after
  end

  def uninstall
    run_callbacks(:uninstallation) do
      self.uninstalled_at = Time.current
      self.shopify_domain = "#{shopify_domain}_deleted_#{uninstalled_at.to_fs(:number)}"
      self.shopify_token = "{REDACTED}"
    end
  end

  def uninstalled?
    uninstalled_at.present?
  end
end
