require 'test/unit'
require File.join(File.dirname(__FILE__), '../lib/downloadstation.rb')
require 'yaml'

include SynologyApi

class ConnectionTest < Test::Unit::TestCase

  EMPTY_STRINGS = ['', '   ', "\n \t"]
  
  def setup
    config_file_path = File.join(File.dirname(__FILE__), 'config.yaml')
    settings = YAML::load_file(config_file_path)
    
    @address = settings['address']
    @port = settings['port']
    @user = settings['user']
    @password = settings['password']
  end
  
  def get_connection
    Connection.new(@address, @port, @user, @password)
  end
  
  private :get_connection
  
  def test_initialize
    connection = nil
    assert_nothing_thrown {
      connection = get_connection
    }
    
    assert_not_nil(connection)
    
    assert_equal(@address, connection.address)
    assert_equal(@port, connection.port)
    assert_equal(@user, connection.user)
  end
  
  def test_initialize_with_dirty_data
    connection = nil
    assert_nothing_thrown {
      connection = Connection.new("  \t#{@address}\r\n", @port, "\n\n#{@user} \n", @password)
    }
    
    assert_not_nil(connection)
    
    assert_equal(@address, connection.address)
    assert_equal(@port, connection.port)
    assert_equal(@user, connection.user)
  end
  
  def test_initialize_with_nil_address
    assert_raise(ArgumentError) {
      Connection.new(nil, @port, @user, @password)
    }
  end
  
  def test_initialize_with_nil_port
    assert_raise(ArgumentError) {
      Connection.new(@address, nil, @user, @password)
    }
  end
  
  def test_initialize_with_nil_user
    assert_raise(ArgumentError) {
      Connection.new(@address, @port, nil, @password)
    }
  end
  
  def test_initialize_with_nil_password
    assert_raise(ArgumentError) {
      Connection.new(@address, @port, @user, nil)
    }
  end
  
  def test_initialize_with_empty_address
    EMPTY_STRINGS.each { |s|
      assert_raise(ArgumentError) {
        Connection.new(s, @port, @user, @password)
      }
    }
  end
  
  def test_initialize_with_empty_user
    EMPTY_STRINGS.each { |s|
      assert_raise(ArgumentError) {
        Connection.new(@address, @port, s, @password)
      }
    }
  end
  
  def test_initialize_with_nonnumeric_port
    assert_raise(TypeError) {
      Connection.new(@address, 'foo', @user, @password)
    }
  end
  
  def test_send_with_nil_data
    assert_raise(ArgumentError) {
      get_connection().send(nil, false)
    }
  end
  
  def test_send_with_not_hash_data
    assert_raise(TypeError) {
      get_connection().send('bar', false)
    }
  end
  
  def test_send_with_empty_data
    assert_raise(ArgumentError) {
      get_connection().send({}, false)
    }
  end
  
  def test_send_with_bad_address
    connection = nil
    assert_nothing_thrown {
      # I hope this IP address isn't used...
      connection = Connection.new('109.199.202.40', @port, @user, @password)
    }
    
    assert_raise(NetworkError) {
      connection.send({'baz' => 'qux'}, false)
    }
  end
  
  def test_send_with_bad_port
    connection = nil
    assert_nothing_thrown {
      # I hope this TCP port isn't used...
      connection = Connection.new(@address, 45150, @user, @password)
    }
    
    assert_raise(NetworkError) {
      connection.send({'quux' => 'corge'}, false)
    }
  end
  
  def test_login
    assert_nothing_thrown {
      get_connection().login
    }
  end
  
  def test_login_with_bad_user
    connection = nil
    assert_nothing_thrown {
      connection = Connection.new(@address, @port, 'grault', @password)
    }
    
    assert_raise(LoginFailedError) {
      connection.login
    }
  end
  
  def test_login_with_bad_password
    connection = nil
    assert_nothing_thrown {
      connection = Connection.new(@address, @port, @user, 'garply')
    }
    
    assert_raise(LoginFailedError) {
      connection.login
    }
  end

end
