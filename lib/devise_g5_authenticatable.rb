require 'devise_g5_authenticatable/version'

require 'devise'
require 'omniauth-g5'

require 'devise_g5_authenticatable/routes'
require 'devise_g5_authenticatable/controllers/url_helpers'

Devise.add_module(:g5_authenticatable,
                  strategy: false,
                  route: :g5_authenticatable,
                  controller: :g5_sessions,
                  model: 'devise_g5_authenticatable/model')
