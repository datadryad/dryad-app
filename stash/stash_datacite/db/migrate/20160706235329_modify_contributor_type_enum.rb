class ModifyContributorTypeEnum < ActiveRecord::Migration[4.2]
  def change
    change_table :dcs_contributors do |t|
      t.change :contributor_type, "ENUM('contactperson', 'datacollector', 'datacurator', 'datamanager', 'distributor', " \
                                  "'editor',  'funder', 'hostinginstitution', 'producer', 'projectleader', 'projectmanager', 'projectmember', " \
                                  "'registrationagency', 'registrationauthority', 'relatedperson', 'researcher', 'researchgroup', 'rightsholder', " \
                                  "'sponsor', 'supervisor', 'workpackageleader', 'other') DEFAULT 'funder'"
    end
  end
end
