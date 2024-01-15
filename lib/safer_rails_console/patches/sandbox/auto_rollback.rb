# frozen_string_literal: true

module SaferRailsConsole
  module Patches
    module Sandbox
      module AutoRollback

        def self.rollback_and_begin_new_transaction
          connection = ::ActiveRecord::Base.connection
          connection.rollback_db_transaction
          connection.begin_db_transaction
        end

        def self.handle_and_reraise_exception(error)
          binding.pry
          if error.message.include?('PG::ReadOnlySqlTransaction') || error.message.include?('MySQL::ReadOnlySqlTransaction')
            puts SaferRailsConsole::Colors.color_text( # rubocop:disable Rails/Output
              'An operation could not be completed due to read-only mode.',
              SaferRailsConsole::Colors::RED
            )
          else
            rollback_and_begin_new_transaction
          end

          raise error
        end

        module PostgreSQLAdapterPatch
          def execute_and_clear(...)
            super
          rescue StandardError => e
            SaferRailsConsole::Patches::Sandbox::AutoRollback.handle_and_reraise_exception(e)
          end
        end

        if defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
          ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PostgreSQLAdapterPatch)
        end

        module Mysql2AdapterPatch
          def execute_and_clear(...)
            super
          rescue StandardError => e
            SaferRailsConsole::Patches::Sandbox::AutoRollback.handle_and_reraise_exception(e)
          end
        end

        if defined?(::ActiveRecord::ConnectionAdapters::Mysql2Adapter)
          ActiveRecord::ConnectionAdapters::Mysql2Adapter.prepend(Mysql2AdapterPatch)
        end
      end
    end
  end
end
