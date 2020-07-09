Dir[File.join(StashApi::Engine.root, 'lib', 'core_extensions', '*/**')].sort.each { |file| require file }

Hash.include CoreExtensions::Hash::RecursiveCompact
