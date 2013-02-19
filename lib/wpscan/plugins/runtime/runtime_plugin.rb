# encoding: UTF-8

class RunTimePlugin < WpscanPlugin

  def initialize
    super(author: 'WPScanTeam')
  end

  def run(wp_target, options = {})
    if @start_time
      @stop_time = Time.now
      elapsed    = @stop_time - @start_time

      puts
      puts green("[+] Finished at #{@stop_time.asctime}")
      puts green("[+] Elapsed time: #{Time.at(elapsed).utc.strftime('%H:%M:%S')}")
      exit() # must exit!
    else
      @start_time = Time.now

      puts "| URL: #{wp_target.url}"
      puts "| Started on #{@start_time.asctime}"
      puts
    end
  end
end
