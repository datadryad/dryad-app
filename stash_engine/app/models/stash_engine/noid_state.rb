require 'noid'
require 'yaml'

module StashEngine
  # this class allows locking of NOID through the database and successive minting so no duplicates are created
  # It is a table with only one row in the database maintaining the current NOID state.
  #
  # Using ruby-microservices noid https://github.com/ruby-microservices/noid . It's not super documented, but the rspec
  # tests demonstrate how to seed minters, maintain state and similar.
  #
  # Also uses the locking scheme for MySQL (see the locks model) as explained by Makandra
  # https://makandracards.com/makandra/1026-simple-database-lock-for-mysql
  # and https://makandracards.com/makandra/31937-differences-between-transactions-and-locking to allow saving
  # state so that it's updated to current and we don't have concurrency problems.

  class NoidError < StandardError
  end

  class NoidState < ActiveRecord::Base

    self.table_name = 'noid_states'

    def self.mint
      the_id = nil # define here, needs to be available after this block
      Lock.acquire('dryad-minter') do
        initialize_minter if NoidState.all.count == 0
        minter = deserialize_from_db
        the_id = minter.mint
        serialize_to_db(minter)
      end
      the_id # return the id
    end

    def self.initialize_minter
      my_minter = Noid::Minter.new(template: '.reeeeeeee')
      my_minter.seed(9281, 0)
      serialize_to_db(my_minter)
    end

    def self.serialize_to_db(the_minter)
      row_count = NoidState.all.count
      minter_serial = YAML.dump(the_minter.dump)
      case row_count
      when 0
        NoidState.create!(state: minter_serial)
      when 1
        ns = NoidState.all.first
        ns.update!(state: minter_serial)
      else
        raise NoidError, 'Only one shared state should exist for the Noid minter'
      end
    end

    def self.deserialize_from_db
      row_count = NoidState.all.count
      case row_count
      when 0
        raise NoidError, 'Noid must have a shared state to deserialize from the shared database table'
      when 1
        ns = NoidState.all.first
      else
        raise NoidError, 'Noid should not have more than one state to deserialize from the shared database table'
      end
      # stupid RSpec breaks when using safe_load as recommended by rubocop
      # rubocop:disable Security/YAMLLoad
      minter_serial = YAML.load(ns.state)
      # rubocop:enable Security/YAMLLoad
      Noid::Minter.new(minter_serial) # return the minter
    end

    private_class_method :initialize_minter
    private_class_method :serialize_to_db
    private_class_method :deserialize_from_db
  end
end
