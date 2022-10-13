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
    class Account < Crecto::Model
        schema "accounts" do
            field :username, String
            field :password, String
            field :last_login, Time
        end

        has_many :characters, Character, foreign_key: :account_id
    end

    class Character < Crecto::Model
        schema "characters" do
            field :account_id, Int32
            field :name, String
            field :job, String
            field :level, Int32
        end
    end
end