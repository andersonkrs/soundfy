class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  class RecordLocked < StandardError; end

  def with_non_blocking_lock!(lock = "FOR UPDATE SKIP LOCKED", &block)
    with_lock(lock, &block)
  rescue ActiveRecord::RecordNotFound => e
    raise RecordLocked, "Record already locked by another process: #{e.id}"
  end
end
