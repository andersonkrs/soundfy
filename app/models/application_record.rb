class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  class RecordLocked < StandardError; end

  def with_non_blocking_lock!(lock = "FOR UPDATE", &block)
    safe_sql = self.class.sanitize_sql([Arel.sql("? SKIP LOCKED"), lock])
    with_lock(safe_sql, &block)
  rescue ActiveRecord::RecordNotFound => e
    raise RecordLocked, "Record already locked by another process: #{e.id}"
  end
end
