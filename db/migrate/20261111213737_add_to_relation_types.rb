class AddToRelationTypes < ActiveRecord::Migration[8.0]
  def up
    change_column :dcs_related_identifiers, :relation_type, "ENUM('iscitedby','cites','issupplementto','issupplementedby','iscontinuedby','continues','isnewversionof','ispreviousversionof','ispartof','haspart','isreferencedby','references','isdocumentedby','documents','iscompiledby','compiles','isvariantformof','isoriginalformof','isidenticalto','hasmetadata','ismetadatafor','reviews','isreviewedby','isderivedfrom','issourceof','iscollectedby','collects')"
  end
  def down
    change_column :dcs_related_identifiers, :relation_type, "ENUM('iscitedby','cites','issupplementto','issupplementedby','iscontinuedby','continues','isnewversionof','ispreviousversionof','ispartof','haspart','isreferencedby','references','isdocumentedby','documents','iscompiledby','compiles','isvariantformof','isoriginalformof','isidenticalto','hasmetadata','ismetadatafor','reviews','isreviewedby','isderivedfrom','issourceof')"
  end
end
