RAILS_ROOT = File.join(File.dirname(File.dirname(__FILE__)), "..", "..")
RAILS_ENV = "production"

2.times do |num|
  God.watch do |w|
    script = "cd #{RAILS_ROOT}; /usr/bin/env RAILS_ENV=#{RAILS_ENV} bundle exec script/delayed_job --pid-dir=#{RAILS_ROOT}/tmp/pids -i #{num}"

    w.name = "mconf_delayed_job.#{num}"
    w.group = "mconf_delayed_job"
    w.interval = 15.seconds
    w.start = "/bin/bash -c '#{script} start'"
    w.stop = "/bin/bash -c '#{script} stop'"
    w.log = "#{RAILS_ROOT}/log/god_delayed_job.#{num}.log"
    w.start_grace = 30.seconds
    w.restart_grace = 30.seconds
    w.pid_file = "#{RAILS_ROOT}/tmp/pids/delayed_job.#{num}.pid"

    w.behavior(:clean_pid_file)

    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = 5.seconds
        c.running = false
      end
    end

    w.restart_if do |restart|
      restart.condition(:memory_usage) do |c|
        c.above = 300.megabytes
        c.times = [3, 5] # 3 out of 5 intervals
      end

      restart.condition(:cpu_usage) do |c|
        c.above = 50.percent
        c.times = 5
      end
    end

    # lifecycle
    w.lifecycle do |on|
      on.condition(:flapping) do |c|
        c.to_state = [:start, :restart]
        c.times = 5
        c.within = 5.minute
        c.transition = :unmonitored
        c.retry_in = 10.minutes
        c.retry_times = 5
        c.retry_within = 2.hours
      end
    end
  end
end
