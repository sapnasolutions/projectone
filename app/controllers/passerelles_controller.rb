class PasserellesController < ApplicationController

  hobo_model_controller

  auto_actions :all

  auto_actions_for :installation, [:new, :create]
end
