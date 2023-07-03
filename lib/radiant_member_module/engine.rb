# frozen_string_literal: true

module ::RadiantMemberModule
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace RadiantMemberModule
    config.autoload_paths << File.join(config.root, "lib")
  end

end
