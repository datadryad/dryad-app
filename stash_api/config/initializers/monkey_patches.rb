Dir[File.join(StashApi::Engine.root, 'lib', 'core_extensions', '*/**')].each {|file| require file }

Hash.include CoreExtensions::Hash::RecursiveCompact