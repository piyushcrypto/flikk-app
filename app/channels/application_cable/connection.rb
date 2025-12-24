module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      logger.add_tags "ActionCable", current_user.email if current_user
    end

    def disconnect
      # Clean up any resources
      logger.info "User #{current_user&.id} disconnected from ActionCable"
    end

    private

    def find_verified_user
      # Try Warden first (for session-based auth)
      if verified_user = env['warden']&.user
        return verified_user
      end
      
      # Fallback to encrypted cookie
      if user_id = cookies.encrypted[:user_id]
        if verified_user = User.find_by(id: user_id)
          return verified_user
        end
      end

      # Fallback to signed cookie
      if user_id = cookies.signed[:user_id]
        if verified_user = User.find_by(id: user_id)
          return verified_user
        end
      end

      reject_unauthorized_connection
    rescue => e
      logger.error "ActionCable connection error: #{e.message}"
      reject_unauthorized_connection
    end
  end
end
