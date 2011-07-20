GatewayManagerHobo::Application.routes.draw do
  root :to => 'front#index'

  match 'search' => 'front#search', :as => 'site_search'
  match 'export' => 'installations#export'
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  
  # gateway's all routes : gateway is the alias of the proxypass of apache
  match 'gateway/search' => 'front#search', :as => 'site_search'
  match 'gateway/export' => 'installations#export'
  match 'gateway/login(.:format)' => 'users#login', :as => 'user_login'
  get 'gateway/logout(.:format)' => 'users#logout', :as => 'user_logout'
  match 'gateway/forgot_password(.:format)' => 'users#forgot_password', :as => 'user_forgot_password'
  
  match 'gateway/:controller(/:action(/:id(.:format)))'
end