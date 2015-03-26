require 'oai/client'
require 'time'

# A utility wrapper around +OAI::Record+ that flattens the OAI XML structure
# and converts types (e.g., string datestamps to +Time+ objects)
#
# @!attribute [r] datestamp
#   @return [Time] The datestamp of the record.
# @!attribute [r] deleted
#   @return [Boolean] True if the record is deleted, false otherwise.
# @!attribute [r] identifier
#   @return [String] The OAI identifier of the record.
# @!attribute [r] metadata_root
#   @return [REXML::Element] The root (inner) element of the record metadata.
class Dash2::Harvester::OAIRecord
  attr_reader :datestamp
  attr_reader :deleted
  attr_reader :identifier
  attr_reader :metadata_root

  alias_method :deleted?, :deleted

  # @param record [OAI::Record] An OAI record as returned by +OAI::Client+
  def initialize(record)
    @datestamp = Time.parse(record.header.datestamp)
    @deleted = record.deleted?
    @identifier = record.header.identifier
    @metadata_root = record.deleted? ? nil : record.metadata.elements[1]
  end

  def ==(other)
    return true if self.equal?(other)
    return false unless other.instance_of?(self.class)
    return false unless other.datestamp == datestamp
    return false unless other.deleted == deleted
    return false unless other.identifier == identifier
    return false unless other.metadata_root == metadata_root
    true
  end
end
