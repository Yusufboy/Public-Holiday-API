Rails.application.routes.draw do
  resources :logs
    namespace :v1 do
        resources :is_holiday, :logs
    end
end
