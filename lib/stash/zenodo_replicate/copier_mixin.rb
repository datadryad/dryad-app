module Stash
  module ZenodoReplicate
    module CopierMixin

      # error if not starting as enqueued
      def error_if_not_enqueued
        return if @copy.state == 'enqueued'

        raise ZenodoError, "copy_id #{@copy.id}: You should never start replicating unless starting from an enqueued state"
      end

      # return an error if replicating already, shouldn't start another replication
      def error_if_replicating
        repli_count = @resource.identifier.zenodo_copies.send(@dataset_type).where(state: %w[replicating error])
          .where('stash_engine_zenodo_copies.resource_id <= ?', @resource.id).where('stash_engine_zenodo_copies.id <= ?', @copy.id).count
        # rubocop goes bonkers on this and suggests guardclause but when you do it suggests an if statement
        # rubocop:disable Style/GuardClause
        if repli_count.positive?
          raise ZenodoError, "identifier_id #{@resource.identifier.id}: Cannot replicate a version while a previous version " \
                             'is replicating or has an error'
        end
        # rubocop:enable Style/GuardClause
      end

      def error_if_out_of_order
        # this is a little similar to error_if_replicating, but catches deferred or other odd states
        prev_unfinished_count = StashEngine::ZenodoCopy.where(identifier_id: @copy.identifier_id)
          .where('id < ?', @copy.id).send(@dataset_type).where.not(state: 'finished').count
        return if prev_unfinished_count == 0

        raise ZenodoError, "identifier_id #{@copy.identifier_id}: Cannot replicate when a previous replication for the " \
                           'identifier has not finished yet. Items must replicate in order.'
      end
    end
  end
end
