class OmniauthAuthenticateAction
  # Request object, received from the controller
  attr_reader :request

  def initialize request
    @request = request
  end

  def missing_omniauth_params?
    omniauth_hash.blank? || redirect_path.blank?
  end

  def find_or_create_user_by_omniauth!
    @user ||= begin
      raise ActiveRecord::RecordNotFound if uid.blank?
      User.find_by("#{provider_uid}": uid) ||
      User.find_by(email: email).tap{ |u| u&.update("#{provider_uid}": uid) } ||
      password = Utils::TokenGenerator.url_safe
      User.create(
        email:                  email,
        password:               password,
        password_confirmation:  password,
        "#{provider_uid}":      uid,
        registration_completed: false
      )
    end
  end

  def redirect_path
    request.env['omniauth.origin']
  end

  private

  def uid
    omniauth_hash[:uid]
  end

  def provider_uid
    "#{omniauth_hash[:provider]}_uid"
  end

  def email
    omniauth_hash.dig :info, :email
  end

  # Omniauth object. It acts like an hash an contains the user attributes
  def omniauth_hash
    request.env.fetch 'omniauth.auth', {}
  end
end
