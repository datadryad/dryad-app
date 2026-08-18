# frozen_string_literal: true

class AddCreditTable < ActiveRecord::Migration[8.0]
  def up
    credit_roles = [
      {
        credit_id: '8b73531f-db56-4914-9502-4cc4d4d8ed73',
        credit_role: 'Conceptualization',
        description: 'Identifying the research goals behind the dataset',
        contributor_type: 'projectleader'
      },
      {
        credit_id: 'f93e0f44-f2a4-4ea1-824a-4e0853b05c9d',
        credit_role: 'Data curation',
        description: 'Managing, cleaning, and preparing data for sharing and reuse',
        contributor_type: 'datacurator'
      },
      {
        credit_id: '2451924d-425e-4778-9f4c-36c848ca70c2',
        credit_role: 'Investigation',
        description: 'Performing the experiments or data collection',
        contributor_type: 'datacollector'
      },
      {
        credit_id: 'f21e2be9-4e38-4ab7-8691-d6f72d5d5843',
        credit_role: 'Methodology',
        description: 'Designing the processes that guided data collection or analysis',
        contributor_type: 'researcher'
      },
      {
        credit_id: 'a693fe76-ea33-49ad-9dcc-5e4f3ac5f938',
        credit_role: 'Project administration',
        description: 'Overseeing project execution, including data management
planning',
        contributor_type: 'projectmanager'
      },
      {
        credit_id: 'f89c5233-01b0-4778-93e9-cc7d107aa2c8',
        credit_role: 'Software',
        description: 'Writing code or scripts used to generate or prepare the data',
        contributor_type: 'researcher'
      },
      {
        credit_id: '0c8ca7d4-06ad-4527-9cea-a8801fcb8746',
        credit_role: 'Supervision',
        description: 'Oversight of data collection or project execution,
typically by senior researchers, PIs, or data managers',
        contributor_type: 'supervisor'
      },
      {
        credit_id: '43ebbd94-98b4-42f1-866b-c930cef228ca',
        credit_role: 'Writing – original draft',
        description: 'Drafting associated documentation, such as README files
or metadata',
        contributor_type: 'researcher'
      },
      {
        credit_id: 'd3aead86-f2a2-47f7-bb99-79de6421164d',
        credit_role: 'Writing – review & editing',
        description: 'Reviewing or improving documentation and descriptive
metadata',
        contributor_type: 'editor'
      }
    ]
    credit_roles.each do |role_hash|
      StashDatacite::CreditRole.find_or_create_by(role_hash)
    end
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
