# frozen_string_literal: true

# name: discourse-radiant-member
# about: Add/remove Radiant members from a group
# version: 0.0.1
# authors: pfaffman
# url: https://github.com/literatecomputing/discourse-radiant-member
# required_version: 2.7.0

enabled_site_setting :radiant_member_enabled
# gem 'sha3-pure-ruby', "0.1.1"
gem "pkg-config", "1.5.0", require: false
gem "mini_portile2", "2.8.0", require: false
gem "rbsecp256k1", "5.1.1", require: false
gem "ffi-compiler", "1.0.1", require: false
gem "scrypt", "3.0.7", require: false
gem "keccak", "1.3.0", require: false
gem "konstructor", "1.0.2", require: false

gem "eth", "0.5.6" , require: false

require 'eth'
module ::RadiantMemberModule
  PLUGIN_NAME = "discourse-radiant-member"
end

require_relative "lib/radiant_member_module/engine"
load File.expand_path("lib/radiant/balance.rb", __dir__)

after_initialize do
  # Code which should run after Rails has finished booting
  register_user_custom_field_type('radiant_dollars', :float)

  add_to_class(User, "radiant_dollars") do
    return Radiant.get_rdnt_amount(self)
  end

  add_to_serializer(:current_user, :radiant_dollars) do 
    Radiant.get_rdnt_amount(object)
  end

  add_model_callback(User, :before_save) do
    puts "saving user #{self.username}"
    self.custom_fields['radiant_dollars']=Radiant.get_rdnt_amount(self)
  end
  end
