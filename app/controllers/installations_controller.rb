class InstallationsController < ApplicationController

  hobo_model_controller

  auto_actions :all

  auto_actions_for :client, [:new, :create]
end
