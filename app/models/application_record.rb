class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  class RecordLocked < StandardError; end

  def with_non_blocking_lock!(lock = "FOR UPDATE", &block)
    with_lock(Arel.sql("#{lock} SKIP LOCKED"), &block)
  rescue ActiveRecord::RecordNotFound => e
    raise RecordLocked, "Record already locked by another process: #{e.id}"
  end
end
