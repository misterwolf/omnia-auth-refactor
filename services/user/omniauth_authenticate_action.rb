# frozen_string_literal: true

# ------------------------------------------------------------------------------
# WARNING: NOT TESTED, neither manually nor with rspec!
# ------------------------------------------------------------------------------

# OmniauthAuthenticateAction
# Class is intended as "Service" that acts between Controller and Model.
# This means that coder should use it in different way:
# call the specific method, that's "find_or_create_user_by_omniauth!".
# After the method is called in the controller, he/she should check if @error
# var is clean before proceeding with the other operations in the controller.
# In truth, it would be better to name the "find_or_create_user_by_omniauth!"
# method as "call", that is the only method avaiable in this Service.

# User::OmniauthAuthenticateAction
module User
  # OmniauthAuthenticateAction
  # => initialize
  #   => omniauth_hash: Hash
  #   => omniauth_origin: String
  # => find_or_create_user_by_omniauth!
  #   => create or find user with the given params
  # => missing_omniauth_params? (deleted!)
  #   => check if omniauth_hash or redirect_path is missing
  class OmniauthAuthenticateAction
    # Removing request because it is not a param for true, but its value inside
    attr_reader :uid, :provider, :provider_uid, :email, :redirect_path, :error,
                :omniauth_hash
    # better to not access to the ---request--- object outside a View/Controller
    # let pass every single needed param for the this service
    def initialize(omniauth_hash: {}, omniauth_origin: '')
      # set a default value to not interrupt execution
      @omniauth_hash = omniauth_hash
      @redirect_path = omniauth_origin

      # dunno what is provider!
      @provider = omniauth_hash[:provider]
      # during the user creation, it is intended as user.field. If user
      # "something_uid" are static and well defined, we are OK. Anyway it not
      # a good choice.
      # Give or take, I'd say better define "provider_uid" field, with uid value
      # and point to another model
      # ---------------------
      @uid = omniauth_hash[:uid]
      @provider_uid = "#{provider}_uid".to_sym
      @email = omniauth_hash.dig(:info, :email)

      validate_params
    end

    def find_or_create_user_by_omniauth!
      return false unless @error.blank?

      @user = find_user || create_user # user is not saved. Let's pay attemption
    rescue ActiveRecord::RecordInvalid # catch the expected exception only
      @error = 'Something went wrong during user creation'

      false
    end

    # It is useless:
    # - in extreme case, if something went wrong, @error var will say you.
    # - we can't ask to a model if we have passed blank params. Model should
    # warn you ASAP about this ( eg, in the initialize) or prevent op in case.
    # def missing_omniauth_params?
    #   omniauth_hash.blank? || redirect_path.blank?
    # end

    private

    def find_user
      provider_uid_key = Hash[provider_uid, uid]

      if (user = User.find_by(provider_uid_key))
        return user
      end

      # I am supposing that "provider_uid" is a user field
      User.find_by(email: email).tap do |u|
        # I trust that the "provider_uid" value (like, eg, "12351231_key'?)
        # is correct.
        # - There are some validations/checks in the controller about
        # 'provider_uid' data?
        # - How many "provider_uid" there are? 1, 2, 3 ... 1000.
        # Better handle this differently in any case.
        u.update(provider_uid_key)
        # there was a day "update_attributes" going to be deprecated soon.
      end
    end

    def create_user
      # password is not generated in the User Model?
      # Let's move it in the model using a password/token automated generation
      # eg, Devise: password = Devise.friendly_token.first(password_length)

      # password = Utils::TokenGenerator.url_safe
      provider_uid_key = Hash[provider_uid, uid]
      user_params = provider_uid_key.merge(
        email: email,
        # password: password,
        # password_confirmation: password,
        registration_completed: false
      )
      # we can use tap here, but let's pass params once.

      User.create(user_params)
    end

    # check params in "one-shot" at initialization phase
    def validate_params
      # provider is required because the find_by param
      @error = "provider can't be blank" if provider.blank?
      @error = "uid can't be blank" if uid.blank?
      @error = "redirect_path can't be blank" if redirect_path.blank?
      @error = "omniauth_hash can't be blank" if omniauth_hash.blank?
    end
  end
end
