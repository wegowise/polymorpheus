module Polymorpheus
  class SqlQuerySubscriber
    attr_reader :sql_statements

    def initialize
      @sql_statements = []
    end

    def call(_name, _start, _finish, _id, payload)
      sql_statements << payload[:sql]
    end

    def clear_sql_history
      @sql_statements.clear
    end
  end
end
