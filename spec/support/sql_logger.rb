module Polymorpheus
  module SqlLogger

    def sql_statements
      @sql_statements ||= []
    end

    def clear_sql_history
      @sql_statements = nil
    end

    def stub_sql(statement, response)
      @stubbed ||= {}
      @stubbed[statement] = response
    end

    private

    def log_sql_statements(sql, name = nil)
      if @stubbed && @stubbed.has_key?(sql)
        @stubbed[sql]
      else
        sql_statements << sql
        original_execute(sql, name)
      end
    end

  end
end

