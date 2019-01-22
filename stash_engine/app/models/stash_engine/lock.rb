# see https://makandracards.com/makandra/1026-simple-database-lock-for-mysql for info about simple DB locking
# rubocop:disable
module StashEngine
  class Lock < ActiveRecord::Base

    self.table_name = 'locks'

    def self.acquire(name)
      already_acquired = definitely_acquired?(name)

      if already_acquired
        yield
      else
        begin
          create(:name => name) unless where(name: name).first # changed because find_by deprecated
        rescue ActiveRecord::StatementInvalid
          # concurrent create is okay
        end

        begin
          result = nil

          transaction do
            lock.where(name: name).first # this updated instead of the next line, find_by deprecated
            # find_by_name(name, :lock => true) # this is the call that will block
            acquired_lock(name)
            result = yield
          end

          result
        ensure
          maybe_released_lock(name)
        end
      end
    end

    # if true, the lock is acquired
    # if false, the lock might still be acquired, because we were in another db transaction
    def self.definitely_acquired?(name)
      !!Thread.current[:definitely_acquired_locks] and Thread.current[:definitely_acquired_locks].has_key?(name)
    end

    def self.acquired_lock(name)
      logger.debug("Acquired lock '#{name}'") unless Rails.env == 'test'
      Thread.current[:definitely_acquired_locks] ||= {}
      Thread.current[:definitely_acquired_locks][name] = true
    end

    def self.maybe_released_lock(name)
      logger.debug("Released lock '#{name}' (if we are not in a bigger transaction)") unless Rails.env == 'test'
      Thread.current[:definitely_acquired_locks] ||= {}
      Thread.current[:definitely_acquired_locks].delete(name)
    end

    private_class_method :acquired_lock, :maybe_released_lock

  end
end
# rubocop:enable