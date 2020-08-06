class AddFosToSubjects < ActiveRecord::Migration[5.0]

  SUBJECT_LIST = [
      'Natural sciences',
      'Mathematics',
      'Computer and information sciences',
      'Physical sciences',
      'Chemical sciences',
      'Earth and related environmental sciences',
      'Biological sciences',
      'Other natural sciences',
      'Engineering and technology',
      'Civil engineering',
      'Electrical engineering, electronic engineering, information engineering',
      'Mechanical engineering',
      'Chemical engineering',
      'Materials engineering',
      'Medical engineering',
      'Environmental engineering',
      'Environmental biotechnology',
      'Industrial biotechnology',
      'Nano-technology',
      'Other engineering and technologies',
      'Medical and health sciences',
      'Basic medicine',
      'Clinical medicine',
      'Health sciences',
      'Medical biotechnology',
      'Other medical sciences',
      'Agricultural sciences',
      'Agriculture, forestry, and fisheries',
      'Animal and dairy science',
      'Veterinary science',
      'Agricultural biotechnology',
      'Other agricultural sciences',
      'Social sciences',
      'Psychology',
      'Economics and business',
      'Educational sciences',
      'Sociology',
      'Law',
      'Political science',
      'Social and economic geography',
      'Media and communications',
      'Other social sciences',
      'Humanities',
      'History and archaeology',
      'Languages and literature',
      'Philosophy, ethics and religion',
      'Arts (arts, history of arts, performing arts, music)',
      'Other humanities'
  ]

  # this up will insert the needed values if needed, but otherwise leave the existing ones alone
  def up
    # it can have unexpected consequences to use ActiveRecord models directly in a migration, so using SQL,
    # btw, no values have an apostrophe or other weird characters in them and a controlled list
    results = ActiveRecord::Base.connection.instance_variable_get('@connection').
        query("SELECT * FROM dcs_subjects WHERE subject_scheme = 'fos'", as: :hash)
    existing_subjects = results.map { |i| i['subject'] } # can't use a symbol here for more compact notation

    need_insertion = SUBJECT_LIST - existing_subjects
    return if need_insertion.empty?

    t = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    insertion_list = need_insertion.map { |i| "('#{i}', 'fos', '#{t}', '#{t}')"}

    execute <<-SQL
      INSERT INTO dcs_subjects (subject, subject_scheme, created_at, updated_at)
      VALUES #{insertion_list.join(', ')}
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Not removing subjects from FOS subjects from database. They may be used by data.'
  end
end
