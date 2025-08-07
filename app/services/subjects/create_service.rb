module Subjects
  class CreateService
    attr_reader :resource, :keywords, :scope

    def initialize(resource, keywords, scope: nil)
      @resource = resource
      @keywords = keywords.is_a?(String) ? [keywords] : keywords
      @scope = scope.is_a?(String) ? scope.to_sym : scope

      parse_keywords
    end

    def call
      return if keywords.blank?

      existing = resource.subjects
      existing = existing.send(scope) if scope
      existing = existing.map { |a| a.subject.downcase }

      resource.subjects << keywords.map do |kw|
        next if kw.blank?
        next if existing.include?(kw.downcase) || existing.include?(kw.force_encoding('UTF-8').encode('UTF-8').downcase)

        existing << kw.downcase

        new = StashDatacite::Subject
        new = new.send(scope) if scope
        new.find_or_create_by(subject: kw)
      end.compact
      resource.reload
    end

    private

    def parse_keywords
      @keywords = keywords.map { |key| key.split(/\s*[,()]\s*/) }
        .flatten
        .map { |s| strip_subject(s) }
        .delete_if(&:blank?)
    end

    def strip_subject(text)
      text.gsub(/^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$/, '')
    end
  end
end
