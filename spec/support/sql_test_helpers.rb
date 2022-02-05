module SqlTestHelpers
  extend ActiveSupport::Concern

  included do
    before do
      ActiveSupport::Notifications.subscribe('sql.active_record', sql_logger)
    end

    after do
      ActiveSupport::Notifications.unsubscribe(sql_logger)
    end

    let(:connection) { ActiveRecord::Base.connection }
    let(:sql_logger) { Polymorpheus::SqlQuerySubscriber.new }

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
      sql_logger.clear_sql_history
    end

    def should_execute_sql(expected)
      expect(clean_sql(sql.join("\n"))).to include(clean_sql(expected))
    end

    def sql
      sql_logger.sql_statements
    end
  end
end
