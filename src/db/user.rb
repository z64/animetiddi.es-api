module Database
  class User < Sequel::Model
    alias_method :blocked?, :blocked

    def block!
      update(blocked: true)
    end

    def unblock!
      update(blocked: false)
    end
  end
end
