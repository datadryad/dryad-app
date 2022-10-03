module StashDatacite
  class ContributorGrouping < ApplicationRecord
    self.table_name = 'dcs_contributor_groupings'

    enum contributor_type: {
      contactperson: 0,
      datacollector: 1,
      datacurator: 2,
      datamanager: 3,
      distributor: 4,
      editor: 5,
      funder: 6,
      hostinginstitution: 7,
      producer: 8,
      projectleader: 9,
      projectmanager: 10,
      projectmember: 11,
      registrationagency: 12,
      registrationauthority: 13,
      relatedperson: 14,
      researcher: 15,
      researchgroup: 16,
      rightsholder: 17,
      sponsor: 18,
      supervisor: 19,
      workpackageleader: 20
    }

    enum identifier_type: {
      isni: 0,
      grid: 1,
      crossref_funder_id: 2,
      ror: 3,
      other: 4
    }

    # In order for this to group you should have a contributor_name and the rest defined for the group.
    # The json_contains field should have a JSON array with individual group records so you know
    # what makes up the special group.
    #
    # example:
    # [
    #   {
    #     "contributor_name": "Center for Information Technology",
    # 		"contributor_type": "funder",
    # 		"identifier_type": "crossref_funder_id",
    # 		"name_identifier_id": "http://dx.doi.org/10.13039/100000093"
    # 	},
    #   {
    # 		"contributor_name": "National Center for Advancing Translational Sciences",
    # 		"contributor_type": "funder",
    # 		"identifier_type": "crossref_funder_id",
    # 		"name_identifier_id": "http://dx.doi.org/10.13039/100006108"
    # 	},
    #  ... etc
    # ]
    #


  end
end
