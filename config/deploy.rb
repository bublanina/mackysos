# -*- encoding : utf-8 -*-
require "bundler/capistrano"

set :default_environment, {
 'PATH' => "/usr/local/rvm/gems/ruby-1.9.2-p290/bin:/usr/local/rvm/gems/ruby-1.9.2-p290@global/bin:/usr/local/rvm/rubies/ruby-1.9.2-p290/bin:/usr/local/rvm/bin:$PATH",
 'RUBY_VERSION' => 'ruby-1.9.2-p290',
 'GEM_HOME'     => '/usr/local/rvm/gems/ruby-1.9.2-p290',
 'GEM_PATH'     => '/usr/local/rvm/gems/ruby-1.9.2-p290:/usr/local/rvm/gems/ruby-1.9.2-p290@global',
 'LANG' => 'en_US.UTF-8'
}

#default_run_options[:pty] = true
set :application, "mackysos"
set :repository, "git@github.com:bublanina/mackysos.git"
set :scm, "git"

role :web, "server8.railshosting.cz"
role :app, "server8.railshosting.cz"
role :db,  "server8.railshosting.cz", :primary => true

set :deploy_to, "/home/mackysos/app/"
set :user, "mackysos"
#set :branch, "master"
#set :scm_verbose, true
#set :deploy_via, :remote_cache

set :use_sudo, false

task :after_update_code, :roles => [:app, :db] do
  run "ln -nfs #{shared_path}/config/database2.yml #{release_path}/config/database2.yml"
end


namespace :deploy do
  task :start, :roles => :app do
  end
end

namespace :deploy do
  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
end


#  namespace :deploy do
#    desc "Update the crontab file"
#    task :update_crontab, :roles => :db, :only => { :primary => true } do
#    rails_env = fetch(:rails_env, "staging")
#    send(run_method, "cd #{current_path} && whenever -f #{'config/
#schedules/' + rails_env + '.rb'} --update-crontab #{current_path}/
#config/schedule.rb")
#  end
#  end

