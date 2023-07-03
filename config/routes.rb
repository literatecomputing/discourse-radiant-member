# frozen_string_literal: true

RadiantMemberModule::Engine.routes.draw do
  get "/examples" => "examples#index"
  # define routes here
end

Discourse::Application.routes.draw { mount ::RadiantMemberModule::Engine, at: "my-plugin" }
