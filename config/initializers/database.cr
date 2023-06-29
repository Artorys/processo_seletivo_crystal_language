require "jennifer"
require "jennifer/adapter/postgres"

require "dotenv"

Dotenv.load

APP_ENV = ENV["APP_ENV"]? || "development"
DB_NAME = ENV["POSTGRES_DB"]

Jennifer::Adapter.register_adapter("postgresql", Jennifer::Postgres::Adapter )
Jennifer::Config.configure do |conf|
  conf.from_uri(ENV["DATABASE_URI"]) if ENV.has_key?("DATABASE_URI")
  severity = case APP_ENV
  when "development"
    Log::Severity::Debug
  else
    Log::Severity::Error
  end
  
  conf.logger.level = severity

  db = conf.db

  if db == DB_NAME
    puts "Connected to #{db}"
  else
    puts "Failed to connect to #{db}"
  end
end

Log.setup "db", :debug, Log::IOBackend.new(formatter: Jennifer::Adapter::DBFormatter)
