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
      job = Job.new({'qux' => qux_value, 'corge' => corge_value}, get_downloadstation())
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
      Job.new(nil, get_downloadstation())
    }
  end
  
  def test_initialize_job_with_not_hash_data
    assert_raise(TypeError) {
      Job.new('baz', get_downloadstation())
    }
  end
  
  def test_initialize_job_with_empty_data
    assert_raise(ArgumentError) {
      Job.new({}, get_downloadstation())
    }
  end
  
  def test_initialize_job_with_nil_downloadstation
    assert_raise(ArgumentError) {
      Job.new({ 'grault' => 'garply' }, nil)
    }
  end
  
  def test_initialize_job_with_not_right_typed_downloadstation
    assert_raise(TypeError) {
      Job.new({ 'waldo' => 'fred' }, 69)
    }
  end
  
  def test_get_jobs_list
    jobs = nil
    assert_nothing_thrown {
      jobs = get_downloadstation().jobs
    }
    
    assert_not_nil(jobs)
    assert_kind_of(Jobs, jobs)
  end
  
  def test_total_speed
    jobs = nil
    assert_nothing_thrown {
      jobs = get_downloadstation().jobs
    }
    
    assert_not_nil(jobs)
    assert_kind_of(Fixnum, jobs.total_download_speed)
    assert_kind_of(Fixnum, jobs.total_upload_speed)
  end
  
  def test_create_job_by_url
    downloadstation = get_downloadstation()
    assert_nothing_thrown {
      downloadstation.create_job(@small_file_url)
    }
    
    assert(downloadstation.jobs.any? { |j| j.url == @small_file_url})
  end
  
  def test_create_job_with_dirty_url
    downloadstation = get_downloadstation()
    assert_nothing_thrown {
      job = downloadstation.create_job("  \n\r#{@small_file_url}\t\t\n")
    }
    
    assert(downloadstation.jobs.any? { |j| j.url == @small_file_url})
  end
  
  def test_create_job_with_nil_url
    assert_raise(ArgumentError) {
      get_downloadstation().create_job(nil)
    }
  end
  
  def test_create_job_with_empty_url
    EMPTY_STRINGS.each { |s|
      assert_raise(ArgumentError) {
        get_downloadstation().create_job(s)
      }
    }
  end
  
  def test_create_job_with_not_string_url
    assert_raise(TypeError) {
      get_downloadstation().create_job([])
    }
  end
  
  def test_create_job_by_torrent_file
    downloadstation = get_downloadstation()
    
    torrent_filename = File.basename(@torrent_path)
    before = downloadstation.jobs.select { |j| j.url == torrent_filename}
    
    assert_nothing_thrown {
      downloadstation.create_job(File.new(@torrent_path))
    }
    
    after = downloadstation.jobs.select { |j| j.url == torrent_filename}
    
    assert(after.count > before.count)
    
    # Cleaning
    after.each { |j| j.delete }
  end
  
  def test_clear
    downloadstation = get_downloadstation()
    
    downloadstation.create_job(@small_file_url) if downloadstation.jobs.none? { |j| j.status == :COMPLETED }
    i = 0
    max_retries = 10
    while i < max_retries && downloadstation.jobs.none? { |j| j.status == :COMPLETED } do
      Kernel.sleep 3
      i = i + 1
    end
    
    raise 'Can\'t complete a download' if i == max_retries
    
    before = downloadstation.jobs
    
    assert_nothing_thrown {
      downloadstation.clear
    }
    
    after = downloadstation.jobs
    
    assert(after.count < before.count)
    assert(before.any? { |j| j.status == :COMPLETED })
    assert(after.none? { |j| j.status == :COMPLETED })
  end
  
  def test_download_status_enum
    quxValue = -69
    quuxValue = 666
    
    assert_nothing_thrown {
      DownloadStatus.add_item(:QUX, quxValue)
      DownloadStatus.add_item(:QUUX, quuxValue)
    }
    
    assert_equal(quxValue, DownloadStatus::QUX)
    assert_equal(:QUUX, DownloadStatus.key(quuxValue))
    
    assert_nil(DownloadStatus::CORGE)
    assert_nil(DownloadStatus.key(667))
  end
  
  def test_delete_job
    downloadstation = get_downloadstation()
    
    downloadstation.jobs.select { |j| j.url == @large_file_url }.each { |j| j.delete }
    downloadstation.create_job(@large_file_url)
    
    job = downloadstation.jobs.find { |j| j.url == @large_file_url }
    
    assert_not_nil(job)
    
    assert_nothing_thrown {
      job.delete
    }
    
    assert(downloadstation.jobs.none? { |j| j.url == @large_file_url })
  end
  
  def test_stop_and_resume_job
    downloadstation = get_downloadstation()
    
    downloadstation.jobs.select { |j| j.url == @large_file_url }.each { |j| j.delete }
    downloadstation.create_job(@large_file_url)
    
    job = downloadstation.jobs.find { |j| j.url == @large_file_url }
    assert_not_nil(job)
    
    assert_nothing_thrown {
      job.stop
    }
    
    job = downloadstation.jobs.find { |j| j.url == @large_file_url }
    assert_not_nil(job)
    
    assert(job.status == :PAUSED)
    
    assert_nothing_thrown {
      job.resume
    }
    
    job = downloadstation.jobs.find { |j| j.url == @large_file_url }
    assert_not_nil(job)
    
    assert(job.status != :PAUSED)
    
    # Cleaning
    job.delete
  end
  
end
