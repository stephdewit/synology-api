require 'test/unit'

require File.join(File.dirname(__FILE__), 'synologyapitest')
require File.join(File.dirname(__FILE__), '../lib/downloadstation.rb')

include SynologyApi::DownloadStation

class DownloadStationTest < Test::Unit::TestCase
  
  include SynologyApiTest
  
  def get_downloadstation
    DownloadStation.new(@address, @port, @user, @password)
  end
  
  private :get_downloadstation
  
  def test_initialize
    downloadstation = nil
    assert_nothing_thrown {
      downloadstation = get_downloadstation()
    }
    
    assert_not_nil(downloadstation)
  end
  
  def test_initialize_job
    job = nil
    qux_value = 'quux'
    corge_value = 'grault'
    assert_nothing_thrown {
      job = Job.new({'qux' => qux_value, 'corge' => corge_value})
    }
    
    assert_not_nil(job)
    assert_equal(qux_value, job.qux)
    assert_equal(corge_value, job.corge)
    
    assert_raise(NoMethodError) {
      job.garply
    }
  end
  
  def test_initialize_job_with_nil_data
    assert_raise(ArgumentError) {
      Job.new(nil)
    }
  end
  
  def test_initialize_job_with_not_hash_data
    assert_raise(TypeError) {
      Job.new('baz')
    }
  end
  
  def test_initialize_job_with_empty_data
    assert_raise(ArgumentError) {
      Job.new({})
    }
  end
  
  def test_get_jobs_list
    jobs = nil
    assert_nothing_thrown {
      jobs = get_downloadstation().jobs
    }
    
    assert_not_nil(jobs)
    assert_kind_of(Array, jobs)
  end
  
  def test_create_job_by_url
    downloadstation = get_downloadstation()
    assert_nothing_thrown {
      downloadstation.add_url(@small_file_url)
    }
    
    assert(downloadstation.jobs.any? { |j| j.url == @small_file_url})
  end
  
  def test_create_job_with_dirty_url
    downloadstation = get_downloadstation()
    assert_nothing_thrown {
      job = downloadstation.add_url("  \n\r#{@small_file_url}\t\t\n")
    }
    
    assert(downloadstation.jobs.any? { |j| j.url == @small_file_url})
  end
  
  def test_create_job_with_nil_url
    assert_raise(ArgumentError) {
      get_downloadstation().add_url(nil)
    }
  end
  
  def test_create_job_with_empty_url
    EMPTY_STRINGS.each { |s|
      assert_raise(ArgumentError) {
        get_downloadstation().add_url(s)
      }
    }
  end
  
  def test_create_job_with_not_string_url
    assert_raise(TypeError) {
      get_downloadstation().add_url([])
    }
  end
  
  def test_clear
    downloadstation = get_downloadstation()
    completed_status_value = 5
    
    downloadstation.add_url(@small_file_url) if downloadstation.jobs.none? { |j| j.status == completed_status_value }
    i = 0
    max_retries = 10
    while i < max_retries && downloadstation.jobs.none? { |j| j.status == completed_status_value } do
      Kernel.sleep 3
      i = i + 1
    end
    
    raise 'Can''t complete a download' if i == max_retries
    
    before = downloadstation.jobs
    
    assert_nothing_thrown {
      downloadstation.clear
    }
    
    after = downloadstation.jobs
    
    assert(after.count < before.count)
    assert(before.any? { |j| j.status == completed_status_value })
    assert(after.none? { |j| j.status == completed_status_value })
  end
  
end
