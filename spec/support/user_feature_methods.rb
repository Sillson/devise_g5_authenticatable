module UserFeatureMethods
  def stub_g5_omniauth(user, options={})
    OmniAuth.config.mock_auth[:g5] = OmniAuth::AuthHash.new({
      uid: user.uid,
      provider: 'g5',
      info: {email: user.email},
      credentials: {token: user.g5_access_token}
    }.merge(options))
  end

  def stub_g5_invalid_credentials
    OmniAuth.config.mock_auth[:g5] = :invalid_credentials
  end

  def visit_path_and_login_with(path, user)
    stub_g5_omniauth(user)
    visit path
  end
end

RSpec.configure do |config|
  config.before(:each) do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:g5] = nil
  end
  config.after(:each) { OmniAuth.config.test_mode = false }

  config.include UserFeatureMethods, type: :feature
end
