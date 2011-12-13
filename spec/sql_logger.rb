module Polymorpheus
  module SqlLogger

    def sql_statements
      @sql_statements ||= []
    end

    private

    def execute(sql, name = nil)
      sql_statements << sql
      sql
    end

  end
end

