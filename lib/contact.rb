require 'types'

class Contact < Dry::Struct
  constructor_type :strict

  attribute :cislo, Types::String
  attribute :email, Types::String

  def id
    cislo
  end

  def self.valid?(params)
    schema = Dry::Validation.Schema do
      required(:cislo).filled
      required(:email).filled
    end

    schema.call(params).errors.empty?
  end
end
