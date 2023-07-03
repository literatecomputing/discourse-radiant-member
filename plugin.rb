# frozen_string_literal: true

# name: discourse-radiant-member
# about: Add/remove Radiant members from a group
# version: 0.0.1
# authors: pfaffman
# url: https://github.com/literatecomputing/discourse-radiant-member
# required_version: 2.7.0

enabled_site_setting :radiant_member_enabled

module ::MyPluginModule
  PLUGIN_NAME = "discourse-radiant-member"
end

require_relative "lib/my_plugin_module/engine"

after_initialize do
  # Code which should run after Rails has finished booting
end
