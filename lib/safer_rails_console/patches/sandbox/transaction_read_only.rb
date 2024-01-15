# frozen_string_literal: true

module SaferRailsConsole
  module Patches
    module Sandbox
      module TransactionReadOnly
        module PostgreSQLAdapterPatch
          def begin_db_transaction
            super
            execute 'SET TRANSACTION READ ONLY'
          end
        end

        if defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
          ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PostgreSQLAdapterPatch)

          # Ensure transaction is read-only if it was began before this patch was loaded
          connection = ::ActiveRecord::Base.connection
          connection.execute 'SET TRANSACTION READ ONLY' if connection.open_transactions > 0
        end

        module Mysql2AdapterPatch
          def begin_db_transaction
            super
            execute 'SET SESSION TRANSACTION READ ONLY'
          end
        end

        if defined?(::ActiveRecord::ConnectionAdapters::Mysql2Adapter)
          ::ActiveRecord::ConnectionAdapters::Mysql2Adapter.prepend(Mysql2AdapterPatch)

          # Ensure transaction is read-only if it was began before this patch was loaded
          connection = ::ActiveRecord::Base.connection
          connection.execute 'SET SESSION TRANSACTION READ ONLY' if connection.open_transactions > 0
        end
      end
    end
  end
end
