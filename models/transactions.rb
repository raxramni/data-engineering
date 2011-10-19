require 'datamapper'

class Transaction
  include DataMapper::Resource
  property :id, Serial
  property :purchaser_name, String
  property :item_description, Text
  property :item_price, Float
  property :purchase_count, Integer
  property :merchant_address, String
  property :merchant_name, String
end
