require 'errors'

require 'net/http'

require 'rubygems'
require 'json'

module SynologyApi
  
  class Connection
    
    def initialize(address, port, user, password)
      raise ArgumentError.new("Not nil 'address' argument expected") if address == nil
      raise ArgumentError.new("Not nil 'port' argument expected") if port == nil
      raise ArgumentError.new("Not nil 'user' argument expected") if user == nil
      raise ArgumentError.new("Not nil 'password' argument expected") if password == nil
      
      cleaned_address = address.strip
      raise ArgumentError.new("Not empty 'address' argument expected") if cleaned_address.empty?
      
      raise TypeError.new("Integer 'port' argument expected") if not port.is_a? Integer
      
      cleaned_user = user.strip
      raise ArgumentError.new("Not empty 'user' argument expected") if cleaned_user.empty?

      @http = Net::HTTP.new(cleaned_address, port)
      @user = cleaned_user
      @password = password
      
      @token = nil
    end
    
    def address
      if @http
        @http.address
      end
    end
    
    def port
      if @http
        @http.port
      end
    end
    
    attr_reader :user

    def login
      logout
      
      result = send({'action' => 'login', 'username' => @user, 'passwd' => @password}, false)
      raise LoginFailedError.new("Login failed for user #{@user}") unless result['login_success']
      
      @token = result['id']
    end
    
    def logout
      @token = nil
    end
      
    def is_connected?
      @token != nil
    end
    
    DOWNLOADREDIRECTOR_PATH = '/download/download_redirector.cgi'
    
    def send(data, add_token=true)
      raise ArgumentError.new("Not nil 'data' argument expected") if data == nil
      raise TypeError.new("Hash 'data' argument expected") if not data.is_a? Hash
      raise ArgumentError.new("Not empty 'data' argument expected") if data.empty?
      
      login if (add_token && !is_connected?)
      
      if add_token
        data_to_add = { 'id' => @token }
      else
        data_to_add = {}
      end
      
      data_to_send = data_to_add.merge(data)
      
      response_body = nil
      
      if (data.values.none? { |v| v.is_a? File })
        response_body = send_data_with_builtin_http(data_to_send)
      else
        response_body = send_data_with_curl(data_to_send)
      end
      
      result = JSON.parse(response_body)
      # TODO: be more specific
      raise SynologyApiError.new('Something went wrong while processing query') unless result['success']
      
      result
    end
    
    def send_data_with_builtin_http(data)
      request = Net::HTTP::Post.new(DOWNLOADREDIRECTOR_PATH)
      request.set_form_data(data)

      begin
        response = @http.start { |h| h.request(request) }
      rescue SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT => x
        exception = NetworkError.new("Can't connect to server: #{x.message}")
        exception.inner_exception = x
        raise exception
      end
      
      if not response.is_a? Net::HTTPSuccess
        begin
          response.error!
        rescue => x
          exception = HttpError.new("Can't talk with server: #{x.message}")
          exception.inner_exception = x
          raise exception
        end
      end

      response.body
    end
    
    private :send_data_with_builtin_http
    
    # FIXME
    # Couldn't find a gem which handles multipart POSTs correctly
    # Why the hell can't Net::HTTP do that ??!?
    def send_data_with_curl(data)
      `curl -F "id=#{@token}" -F "torrent=@#{file}" http://#{address}:#{port}#{DOWNLOADREDIRECTOR_PATH}`
    end
    
    private :send_data_with_curl
    
  end
  
  class NetworkError < SynologyApiError
    
    attr_accessor :inner_exception
    
    # Best effort...
    def possible_cause
      return nil if (@inner_exception == nil)
      
      case @inner_exception
        when SocketError: :dns
        when Errno::ECONNREFUSED: :port
        when Errno::ETIMEDOUT: :ip_or_firewall
        else nil
      end
    end
    
  end
  
  class HttpError < NetworkError
    
    def possible_cause
      :protocol
    end
    
  end
  
  class LoginFailedError < SynologyApiError; end
  
end
