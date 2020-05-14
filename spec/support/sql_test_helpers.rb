module SqlTestHelpers
  extend ActiveSupport::Concern

  included do
    before(:all) do
      class << ActiveRecord::Base.connection
        include Polymorpheus::SqlLogger
        alias_method :original_execute, :execute
        alias_method :execute, :log_sql_statements
      end
    end

    after(:all) do
      class << ActiveRecord::Base.connection
        alias_method :execute, :original_execute
      end
    end

    let(:connection) { ActiveRecord::Base.connection }
    let(:sql) { connection.sql_statements }

    def clean_sql(sql_string)
      sql_string
        .squish
        .gsub('`', '')
        .gsub(/\ FOREIGN KEY/, "\nFOREIGN KEY")
        .gsub(/\ REFERENCES/, "\nREFERENCES")
        .gsub(/\ ON DELETE/, "\nON DELETE")
        .gsub(/\ ON UPDATE/, "\nON UPDATE")
        .gsub(/([[:alpha:]])\(/, '\1 (')
    end

    def clear_sql_history
      connection.clear_sql_history
    end

    def should_execute_sql(expected)
      expect(clean_sql(sql.join("\n"))).to include(clean_sql(expected))
    end
  end
end
