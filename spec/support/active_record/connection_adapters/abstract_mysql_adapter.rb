# Patch support for MySQL 5.7+ onto ActiveRecord < 4.1.
if ActiveRecord::VERSION::MAJOR < 4 ||
   (ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR < 1)

  require 'active_record/connection_adapters/abstract_mysql_adapter'
  class ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
    NATIVE_DATABASE_TYPES[:primary_key] = "int(11) auto_increment PRIMARY KEY"
  end
end
