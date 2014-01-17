require 'spec_helper'

describe Devise::SessionsController do
  before { request.env['devise.mapping'] = Devise.mappings[scope] }
  let(:scope) { :user }

  describe '#new' do
    subject(:new_session) { get :new }

    context 'with user scope' do
      it 'should redirect to the scoped authorize path' do
        expect(new_session).to redirect_to(user_g5_authorize_path)
      end
    end

    context 'with admin scope' do
      let(:scope) { :admin }

      it 'should redirect to the scoped authorize path' do
        expect(new_session).to redirect_to(admin_g5_authorize_path)
      end
    end
  end

  describe '#omniauth_passthru' do
    subject(:passthru) { get :omniauth_passthru }

    it 'should return a 404' do
      expect(passthru).to be_not_found
    end
  end

  describe '#create' do
    subject(:create_session) { post :create }

    let(:auth_hash) do
      OmniAuth::AuthHash.new({
        provider: 'g5',
        uid: '45',
        info: {name: 'Foo Bar',
               email: 'foo@bar.com'},
        credentials: {token: 'abc123'}
      })
    end
    before { request.env['omniauth.auth'] = auth_hash }

    context 'when local model exists' do
      let(:model) do
        stub_model(model_class, provider: auth_hash.provider,
                         uid: auth_hash.uid,
                         email: auth_hash.email,
                         g5_access_token: auth_hash.credentials.token,
                         save!: true,
                         update_g5_credentials: true,
                         email_changed?: false)
      end
      before { model_class.stub(find_and_update_for_g5_oauth: model) }

      context 'with user scope' do
        let(:model_class) { User }
        let(:scope) { :user }

        it 'should find the user and update the oauth credentials' do
          User.should_receive(:find_and_update_for_g5_oauth).with(auth_hash).and_return(model)
          create_session
        end

        it 'should set the flash message' do
          create_session
          expect(flash[:notice]).to eq('Signed in successfully.')
        end

        it 'should sign in the user' do
          expect { create_session }.to change { controller.current_user }.from(nil).to(model)
        end

        it 'should redirect the user' do
          create_session
          expect(response).to be_a_redirect
        end
      end

      context 'with admin scope' do
        let(:model_class) { Admin }
        let(:scope) { :admin }

        it 'should find the admin and update the oauth credentials' do
          Admin.should_receive(:find_and_update_for_g5_oauth).with(auth_hash).and_return(model)
          create_session
        end

        it 'should sign in the admin' do
          expect { create_session }.to change { controller.current_admin }.from(nil).to(model)
        end
      end
    end

    context 'when local model does not exist' do
      before { model_class.stub(find_and_update_for_g5_oauth: nil) }

      context 'with user scope' do
        let(:scope) { :user }
        let(:model_class) { User }

        it 'should set the flash message' do
          create_session
          expect(flash[:alert]).to eq('You must sign up before continuing.')
        end

        it 'should not sign in a user' do
          expect { create_session }.to_not change { controller.current_user }
        end

        it 'should redirect to the user registration path' do
          expect(create_session).to redirect_to(new_user_registration_path)
        end
      end

      context 'with admin scope' do
        let(:scope) { :admin }
        let(:model_class) { Admin }

        it 'should redirect to the admin registration path' do
          expect(create_session).to redirect_to(new_admin_registration_path)
        end
      end
    end
  end

  describe '#destroy' do
    subject(:destroy_session) { delete :destroy }

    let(:auth_client) { double(:auth_client, sign_out_url: auth_sign_out_url) }
    let(:auth_sign_out_url) { 'https://auth.test.host/sign_out?redirect_url=http%3A%2F%2Ftest.host%2F' }
    before do
      allow(G5AuthenticationClient::Client).to receive(:new).and_return(auth_client)
    end

    let(:model) { create(scope) }

    before do
      sign_in(scope, model)
      allow(model).to receive(:revoke_g5_credentials!)
    end

    context 'with user scope' do
      let(:scope) { :user }

      it 'should sign out the user locally' do
        expect { destroy_session }.to change { controller.current_user }.to(nil)
      end

      it 'should construct the sign out URL with the correct redirect URL' do
        expect(auth_client).to receive(:sign_out_url).
          with(root_url).
          and_return(auth_sign_out_url)
        destroy_session
      end

      it 'should redirect to the auth server to sign out globally' do
        expect(destroy_session).to redirect_to(auth_sign_out_url)
      end

      it 'should revoke the g5 access token' do
        expect(controller.current_user).to receive(:revoke_g5_credentials!)
        destroy_session
      end
    end

    context 'with admin scope' do
      let(:scope) { :admin }

      it 'should sign out the admin locally' do
        expect { destroy_session }.to change { controller.current_admin }.to(nil)
      end

      it 'should revoke the g5 access token' do
        expect(controller.current_admin).to receive(:revoke_g5_credentials!)
        destroy_session
      end
    end
  end
end
