# This is an auto-generated file: don't edit!
# You can add your own routes in the config/routes.rb file
# which will override the routes in this file.

GatewayManagerHobo::Application.routes.draw do


  # Resource routes for controller "biens"
  get 'biens(.:format)' => 'biens#index', :as => 'biens'
  get 'biens/new(.:format)', :as => 'new_bien'
  get 'biens/:id/edit(.:format)' => 'biens#edit', :as => 'edit_bien'
  get 'biens/:id(.:format)' => 'biens#show', :as => 'bien', :constraints => { :id => %r([^/.?]+) }
  post 'biens(.:format)' => 'biens#create', :as => 'create_bien'
  put 'biens/:id(.:format)' => 'biens#update', :as => 'update_bien', :constraints => { :id => %r([^/.?]+) }
  delete 'biens/:id(.:format)' => 'biens#destroy', :as => 'destroy_bien', :constraints => { :id => %r([^/.?]+) }


  # Resource routes for controller "bien_emplacements"
  get 'bien_emplacements(.:format)' => 'bien_emplacements#index', :as => 'bien_emplacements'
  get 'bien_emplacements/new(.:format)', :as => 'new_bien_emplacement'
  get 'bien_emplacements/:id/edit(.:format)' => 'bien_emplacements#edit', :as => 'edit_bien_emplacement'
  get 'bien_emplacements/:id(.:format)' => 'bien_emplacements#show', :as => 'bien_emplacement', :constraints => { :id => %r([^/.?]+) }
  post 'bien_emplacements(.:format)' => 'bien_emplacements#create', :as => 'create_bien_emplacement'
  put 'bien_emplacements/:id(.:format)' => 'bien_emplacements#update', :as => 'update_bien_emplacement', :constraints => { :id => %r([^/.?]+) }
  delete 'bien_emplacements/:id(.:format)' => 'bien_emplacements#destroy', :as => 'destroy_bien_emplacement', :constraints => { :id => %r([^/.?]+) }


  # Resource routes for controller "bien_photos"
  get 'bien_photos(.:format)' => 'bien_photos#index', :as => 'bien_photos'
  get 'bien_photos/new(.:format)', :as => 'new_bien_photo'
  get 'bien_photos/:id/edit(.:format)' => 'bien_photos#edit', :as => 'edit_bien_photo'
  get 'bien_photos/:id(.:format)' => 'bien_photos#show', :as => 'bien_photo', :constraints => { :id => %r([^/.?]+) }
  post 'bien_photos(.:format)' => 'bien_photos#create', :as => 'create_bien_photo'
  put 'bien_photos/:id(.:format)' => 'bien_photos#update', :as => 'update_bien_photo', :constraints => { :id => %r([^/.?]+) }
  delete 'bien_photos/:id(.:format)' => 'bien_photos#destroy', :as => 'destroy_bien_photo', :constraints => { :id => %r([^/.?]+) }


  # Resource routes for controller "bien_transactions"
  get 'bien_transactions(.:format)' => 'bien_transactions#index', :as => 'bien_transactions'
  get 'bien_transactions/new(.:format)', :as => 'new_bien_transaction'
  get 'bien_transactions/:id/edit(.:format)' => 'bien_transactions#edit', :as => 'edit_bien_transaction'
  get 'bien_transactions/:id(.:format)' => 'bien_transactions#show', :as => 'bien_transaction', :constraints => { :id => %r([^/.?]+) }
  post 'bien_transactions(.:format)' => 'bien_transactions#create', :as => 'create_bien_transaction'
  put 'bien_transactions/:id(.:format)' => 'bien_transactions#update', :as => 'update_bien_transaction', :constraints => { :id => %r([^/.?]+) }
  delete 'bien_transactions/:id(.:format)' => 'bien_transactions#destroy', :as => 'destroy_bien_transaction', :constraints => { :id => %r([^/.?]+) }


  # Resource routes for controller "bien_types"
  get 'bien_types(.:format)' => 'bien_types#index', :as => 'bien_types'
  get 'bien_types/new(.:format)', :as => 'new_bien_type'
  get 'bien_types/:id/edit(.:format)' => 'bien_types#edit', :as => 'edit_bien_type'
  get 'bien_types/:id(.:format)' => 'bien_types#show', :as => 'bien_type', :constraints => { :id => %r([^/.?]+) }
  post 'bien_types(.:format)' => 'bien_types#create', :as => 'create_bien_type'
  put 'bien_types/:id(.:format)' => 'bien_types#update', :as => 'update_bien_type', :constraints => { :id => %r([^/.?]+) }
  delete 'bien_types/:id(.:format)' => 'bien_types#destroy', :as => 'destroy_bien_type', :constraints => { :id => %r([^/.?]+) }


  # Resource routes for controller "clients"
  get 'clients(.:format)' => 'clients#index', :as => 'clients'
  get 'clients/new(.:format)', :as => 'new_client'
  get 'clients/:id/edit(.:format)' => 'clients#edit', :as => 'edit_client'
  get 'clients/:id(.:format)' => 'clients#show', :as => 'client', :constraints => { :id => %r([^/.?]+) }
  post 'clients(.:format)' => 'clients#create', :as => 'create_client'
  put 'clients/:id(.:format)' => 'clients#update', :as => 'update_client', :constraints => { :id => %r([^/.?]+) }
  delete 'clients/:id(.:format)' => 'clients#destroy', :as => 'destroy_client', :constraints => { :id => %r([^/.?]+) }


  # Resource routes for controller "executions"
  get 'executions(.:format)' => 'executions#index', :as => 'executions'
  get 'executions/new(.:format)', :as => 'new_execution'
  get 'executions/:id/edit(.:format)' => 'executions#edit', :as => 'edit_execution'
  get 'executions/:id(.:format)' => 'executions#show', :as => 'execution', :constraints => { :id => %r([^/.?]+) }
  post 'executions(.:format)' => 'executions#create', :as => 'create_execution'
  put 'executions/:id(.:format)' => 'executions#update', :as => 'update_execution', :constraints => { :id => %r([^/.?]+) }
  delete 'executions/:id(.:format)' => 'executions#destroy', :as => 'destroy_execution', :constraints => { :id => %r([^/.?]+) }


  # Resource routes for controller "execution_source_files"
  get 'execution_source_files(.:format)' => 'execution_source_files#index', :as => 'execution_source_files'
  get 'execution_source_files/new(.:format)', :as => 'new_execution_source_file'
  get 'execution_source_files/:id/edit(.:format)' => 'execution_source_files#edit', :as => 'edit_execution_source_file'
  get 'execution_source_files/:id(.:format)' => 'execution_source_files#show', :as => 'execution_source_file', :constraints => { :id => %r([^/.?]+) }
  post 'execution_source_files(.:format)' => 'execution_source_files#create', :as => 'create_execution_source_file'
  put 'execution_source_files/:id(.:format)' => 'execution_source_files#update', :as => 'update_execution_source_file', :constraints => { :id => %r([^/.?]+) }
  delete 'execution_source_files/:id(.:format)' => 'execution_source_files#destroy', :as => 'destroy_execution_source_file', :constraints => { :id => %r([^/.?]+) }


  # Resource routes for controller "installations"
  get 'installations(.:format)' => 'installations#index', :as => 'installations'
  get 'installations/new(.:format)', :as => 'new_installation'
  get 'installations/:id/edit(.:format)' => 'installations#edit', :as => 'edit_installation'
  get 'installations/:id(.:format)' => 'installations#show', :as => 'installation', :constraints => { :id => %r([^/.?]+) }
  post 'installations(.:format)' => 'installations#create', :as => 'create_installation'
  put 'installations/:id(.:format)' => 'installations#update', :as => 'update_installation', :constraints => { :id => %r([^/.?]+) }
  delete 'installations/:id(.:format)' => 'installations#destroy', :as => 'destroy_installation', :constraints => { :id => %r([^/.?]+) }

  # Owner routes for controller "installations"
  get 'clients/:client_id/installations/new(.:format)' => 'installations#new_for_client', :as => 'new_installation_for_client'
  post 'clients/:client_id/installations(.:format)' => 'installations#create_for_client', :as => 'create_installation_for_client'

  # Web method routes for controller "installations"
  post 'installations/:id/data(.:format)' => 'installations#data', :as => 'installation_data'


  # Resource routes for controller "passerelles"
  get 'passerelles(.:format)' => 'passerelles#index', :as => 'passerelles'
  get 'passerelles/new(.:format)', :as => 'new_passerelle'
  get 'passerelles/:id/edit(.:format)' => 'passerelles#edit', :as => 'edit_passerelle'
  get 'passerelles/:id(.:format)' => 'passerelles#show', :as => 'passerelle', :constraints => { :id => %r([^/.?]+) }
  post 'passerelles(.:format)' => 'passerelles#create', :as => 'create_passerelle'
  put 'passerelles/:id(.:format)' => 'passerelles#update', :as => 'update_passerelle', :constraints => { :id => %r([^/.?]+) }
  delete 'passerelles/:id(.:format)' => 'passerelles#destroy', :as => 'destroy_passerelle', :constraints => { :id => %r([^/.?]+) }

  # Owner routes for controller "passerelles"
  get 'installations/:installation_id/passerelles/new(.:format)' => 'passerelles#new_for_installation', :as => 'new_passerelle_for_installation'
  post 'installations/:installation_id/passerelles(.:format)' => 'passerelles#create_for_installation', :as => 'create_passerelle_for_installation'


  # Lifecycle routes for controller "users"
  put 'users/:id/accept_invitation(.:format)' => 'users#do_accept_invitation', :as => 'do_user_accept_invitation'
  get 'users/:id/accept_invitation(.:format)' => 'users#accept_invitation', :as => 'user_accept_invitation'
  put 'users/:id/reset_password(.:format)' => 'users#do_reset_password', :as => 'do_user_reset_password'
  get 'users/:id/reset_password(.:format)' => 'users#reset_password', :as => 'user_reset_password'

  # Resource routes for controller "users"
  get 'users/:id/edit(.:format)' => 'users#edit', :as => 'edit_user'
  get 'users/:id(.:format)' => 'users#show', :as => 'user', :constraints => { :id => %r([^/.?]+) }
  post 'users(.:format)' => 'users#create', :as => 'create_user'
  put 'users/:id(.:format)' => 'users#update', :as => 'update_user', :constraints => { :id => %r([^/.?]+) }
  delete 'users/:id(.:format)' => 'users#destroy', :as => 'destroy_user', :constraints => { :id => %r([^/.?]+) }

  # Show action routes for controller "users"
  get 'users/:id/account(.:format)' => 'users#account', :as => 'user_account'

  # User routes for controller "users"
  match 'login(.:format)' => 'users#login', :as => 'user_login'
  get 'logout(.:format)' => 'users#logout', :as => 'user_logout'
  match 'forgot_password(.:format)' => 'users#forgot_password', :as => 'user_forgot_password'

  namespace :admin do


    # Lifecycle routes for controller "admin/users"
    post 'users/invite(.:format)' => 'users#do_invite', :as => 'do_user_invite'
    get 'users/invite(.:format)' => 'users#invite', :as => 'user_invite'

    # Resource routes for controller "admin/users"
    get 'users(.:format)' => 'users#index', :as => 'users'
    get 'users/new(.:format)', :as => 'new_user'
    get 'users/:id/edit(.:format)' => 'users#edit', :as => 'edit_user'
    get 'users/:id(.:format)' => 'users#show', :as => 'user', :constraints => { :id => %r([^/.?]+) }
    post 'users(.:format)' => 'users#create', :as => 'create_user'
    put 'users/:id(.:format)' => 'users#update', :as => 'update_user', :constraints => { :id => %r([^/.?]+) }
    delete 'users/:id(.:format)' => 'users#destroy', :as => 'destroy_user', :constraints => { :id => %r([^/.?]+) }

  end

end
