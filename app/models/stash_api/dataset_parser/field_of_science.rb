module StashApi
  class DatasetParser
    class FieldOfScience < StashApi::DatasetParser::BaseParser

      # looks like this
      # "fieldOfScience": "Animal and dairy science"

      def parse
        return if @hash['fieldOfScience'].blank?

        clear_fos

        fos = StashDatacite::Subject.where(subject: @hash['fieldOfScience'], subject_scheme: 'fos')
        # Only use the fos if it matches a pre-existing fos keyword; don't create a new one
        @resource.subjects << fos.first unless fos.blank?
      end

      private

      def clear_fos
        @resource.subjects.delete(@resource.subjects.fos)
      end

    end
  end
end
