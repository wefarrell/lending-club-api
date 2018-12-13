require 'zip'
require 'open-uri'
require 'byebug'

task :load_lc_dataset  do
  DATASET_URL = 'https://resources.lendingclub.com/LoanStats_2018Q3.csv.zip'
  RAW_CSV_TABLE_NAME = 'lc_dataset'
  COLUMN_TYPES = {
    'loan_amnt' => 'FLOAT',
    'annual_inc' => 'FLOAT'
  }

  def connection
    ActiveRecord::Base.connection
  end

  def extract_remote_zip_file(file)
    zip_contents = open(file).read
    zip_file = Zip::File.open_buffer(zip_contents).first
    dest_file = Dir.mktmpdir + '/' + zip_file.name
    zip_file.extract(dest_file)
    File.read(dest_file)
  end

  def clean_file(file)
    lines = file.force_encoding('UTF-8').split("\n").drop(1)
    lines.pop(4)
    lines.join("\n")
  end

  def load_header(file)
    header = file.split("\n").first
    header.split(',').map{|col| col }
  end

  def load_column_type(column)
    COLUMN_TYPES[column.gsub('"', '')] || 'VARCHAR'
  end

  def create_table_from_csv(table_name, columns)
    connection.execute("DROP TABLE IF EXISTS #{table_name}")
    column_definitions = columns.map{|col|
      col + ' ' + load_column_type(col)
    }.join(',')
    connection.execute("CREATE TABLE #{table_name} (#{column_definitions})")
  end

  def load_csv_to_db(file_contents, table_name, columns)
    rc = connection.raw_connection

    sql = <<-SQL
      COPY #{table_name}(#{columns.join(', ')})
      FROM STDIN DELIMITER ',' CSV HEADER ;
    SQL
    #byebug
    rc.exec(sql)
    rc.put_copy_data(file_contents)
    rc.put_copy_end
    while res = rc.get_result
      raise res.error_message unless res.error_message.blank?
    end
  end

  csv_file = extract_remote_zip_file(DATASET_URL)
  csv_file = clean_file(csv_file)
  columns = load_header(csv_file)
  create_table_from_csv(RAW_CSV_TABLE_NAME, columns)
  load_csv_to_db(csv_file, RAW_CSV_TABLE_NAME, columns)

end