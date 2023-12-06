# see https://github.com/capistrano/capistrano/issues/1132
namespace :deploy do
  namespace :symlink do

    task :shared do
      invoke "deploy:symlink:optional_linked_files"
    end

    desc 'Symlink optional linked files'
    task :optional_linked_files do
      next unless any? :linked_files
      on release_roles :all do |host|
        linked_files(shared_path).each do |file|
          unless test "[ -f #{file} ]"
            # error t(:linked_file_does_not_exist, file: file, host: host)
            # exit 1
            info t(:linked_file_does_not_exist, file: file, host: host)
          end
        end
      end
    end

  end
end