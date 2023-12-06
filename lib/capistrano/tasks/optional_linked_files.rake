# see https://github.com/capistrano/capistrano/issues/1132
namespace :deploy do
  namespace :symlink do

    task :shared do
      invoke "deploy:symlink:optional_linked_files"
    end

    desc 'Symlink optional linked files'
    task :optional_linked_files do
      next unless any? :optional_linked_files
      on release_roles :all do
        execute :mkdir, "-p", linked_file_dirs(release_path)

        fetch(:optional_linked_files).each do |file|
          target = release_path.join(file)
          source = shared_path.join(file)
          next unless test "[ -f #{source} ]" # *** skip files that don't exist
          next if test "[ -L #{target} ]"
          execute :rm, target if test "[ -f #{target} ]"
          execute :ln, "-s", source, target
        end
      end
    end

  end
end