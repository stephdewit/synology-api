require 'errors'
require 'connection'

module SynologyApi
  
  class DownloadStation
    
    def initialize(address, port, user, password)
      @connection = Connection.new(address, port, user, password)
    end
    
  end
  
  class DownloadStationError < SynologyApiError; end
  
end