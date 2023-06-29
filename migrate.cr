#! /usr/bin/env crystal
#
# To build a standalone command line client, require the
# driver you wish to use and use `Micrate::Cli`.
#

require "micrate"
require "pg"

require "dotenv"

Dotenv.load

DB_URL = ENV["DATABASE_URI"]

Micrate::DB.connection_url = DB_URL
Micrate::Cli.run