module BundlerHelp

  def self.find_path(dir_name)
    path = File.expand_path('.')
    path_arr = path.split(File::SEPARATOR).map {|x| x=="" ? File::SEPARATOR : x}
    while (path_arr.length > 0) do
      test = File.join(path_arr, dir_name)
      return test if Dir.exists?(test)
      path_arr.pop
    end
    false
  end
end