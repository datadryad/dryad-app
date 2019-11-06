class FixPublishers < ActiveRecord::Migration
  def change
    bad_to_good = {
      'IFCA' => 'DataONE',
      'UCLA' => 'UC Los Angeles',
      'University of California-Davis' => 'UC Davis',
      'University of California, Berkeley' => 'UC Berkeley',
      'University of California, Los Angeles' => 'UC Los Angeles',
      'University of California, Office of the President' => 'UC Office of the President',
      'University of California, San Francisco' => 'UC San Francisco',
      'University of California, Santa Cruz' => 'UC Santa Cruz',
    }

    query = <<-SQL
      SELECT *
        FROM dcs_publishers
       WHERE publisher = ?
    SQL

    update = <<-SQL
      UPDATE dcs_publishers
         SET publisher = ?
       WHERE publisher = ?
    SQL

    client = ActiveRecord::Base.connection.raw_connection
    query_stmt = client.prepare(query)
    update_stmt = client.prepare(update)

    bad_to_good.each do |bad, good|
      result = query_stmt.execute(bad)
      expected = result.count

      say("Updating '#{bad}' => '#{good}' (#{expected} rows)")
      update_stmt.execute(good, bad) # note argument order
      actual = update_stmt.affected_rows
      say("\t#{actual} rows affected")

      raise "Update failed; expected #{expected} rows, was #{actual}" if actual != expected
    end
  end
end
