module BundlerHelp

  def self.find_path(dir_name)
    paths = [File.expand_path('.'), File.expand_path('..')]
    paths.each do |path|
      path_arr = path.split(File::SEPARATOR).map {|x| x=='' ? File::SEPARATOR : x}
      while path_arr.length > 0 do
        test = File.join(path_arr, dir_name)
        return test if Dir.exists?(test)
        path_arr.pop
      end
    end
    false
  end
end
