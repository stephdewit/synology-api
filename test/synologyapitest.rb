require 'yaml'

module SynologyApiTest
  
  EMPTY_STRINGS = ['', '   ', "\n \t"]
  
  def setup
    config_file_path = File.join(File.dirname(__FILE__), 'config.yaml')
    settings = YAML::load_file(config_file_path)
    
    @address = settings['address']
    @port = settings['port']
    @user = settings['user']
    @password = settings['password']
    
    @small_file_url = settings['testurls']['smallfile']
    @large_file_url = settings['testurls']['largefile']
  end
  
end
