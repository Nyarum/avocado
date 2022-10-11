require "pg"
require "crecto"

module DB
    extend Crecto::Repo

    config do |conf|
        conf.adapter = Crecto::Adapters::Postgres
        conf.hostname = "localhost"
        conf.database = "postgres"
        conf.username = "postgres"
        conf.password = "test"
    end
end

module DBModels
    class User < Crecto::Model
        schema "accounts" do
            field :username, String
            field :password, String
            field :last_login, Time
        end
    end
end