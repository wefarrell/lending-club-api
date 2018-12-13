class OpenRemote

  def initialize(url)
    @url = url
  end

  def save_remote_file
    require 'open-uri'
    file = tmp_file_path

    File.open(file, "w") do |tmp_file|
      content = open(@url).read.force_encoding('UTF-8')

      tmp_file.write(content)
    end
    File.new(file, 'r')
  end

  def tmp_file_path
    "#{Dir.mktmpdir}/#{SecureRandom.hex(5)}"
  end
end