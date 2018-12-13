class LoadDatasetToDbService
  attr_reader :file, :table_name, :columns

  def initialize(file, table_name, headers)
    @file = file
    @table_name = table_name
    @columns = headers
  end

  def load_dataset_to_db
    connection = ActiveRecord::Base.connection.raw_connection
    connection.exec <<-SQL
      COPY #{table_name}(#{columns.join(',')})
      FROM STDIN DELIMITER ',' CSV HEADER;
    SQL
    connection.put_copy_data(File.read(file.path))
    connection.put_copy_end

    while res = connection.get_result
      raise res.error_message unless res.error_message.blank?
    end
  end
end