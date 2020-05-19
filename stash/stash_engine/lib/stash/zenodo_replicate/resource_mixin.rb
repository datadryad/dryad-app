module Stash
  module ZenodoReplicate
    module ResourceMixin

      # error if not starting as enqueued
      def error_if_not_enqueued
        return if @resource.zenodo_copies.send(@assoc_method).first&.state == 'enqueued'

        raise ZenodoError, "resource_id #{@resource.id}: You should never start replicating unless starting from an enqueued state"
      end

      # return an error if replicating already, shouldn't start another replication
      def error_if_replicating
        repli_count = @resource.identifier.zenodo_copies.send(@assoc_method).where(state: %w[replicating error]).count
        # rubocop goes bonkers on this and suggests guardclause but when you do it suggests an if statement
        # rubocop:disable Style/GuardClause
        if repli_count.positive?
          raise ZenodoError, "identifier_id #{@resource.identifier.id}: Cannot replicate a version while a previous version " \
              'is replicating or has an error'
        end
        # rubocop:enable Style/GuardClause
      end

      def error_if_out_of_order
        # this is a little similar to error_if_replicating, but catches defered or other odd states
        prev_unfinished_count = StashEngine::ZenodoCopy.where(identifier_id: @resource.identifier_id)
          .where('id < ?', @resource.zenodo_copies.send(@assoc_method).first.id).where.not(state: 'finished').count
        return if prev_unfinished_count == 0

        raise ZenodoError, "identifier_id #{@resource.identifier.id}: Cannot replicate a version when a previous version " \
              'has not replicated yet. Items must replicate in order.'
      end

      def previous_deposition_id
        last = @resource.identifier.zenodo_copies.send(@assoc_method).where.not(deposition_id: nil).last
        return nil if last.nil?

        last.deposition_id
      end
    end
  end
end
