class Bound
  class PublicSendCaller
    def self.call(object, method, *args)
      object.public_send(method, *args)
    end
  end

  class ManualCaller
    def self.call(object, method, *args)
      if object.respond_to?(method)
        object.send method, *args
      else
        raise NoMethodError, "undefined method `#{method}' for #{object}"
      end
    end
  end

  if Object.respond_to? :public_send
    Caller = PublicSendCaller
  else
    Caller = ManualCaller
  end
end
