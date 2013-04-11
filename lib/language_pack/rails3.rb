require "language_pack"
require "language_pack/rails2"

# Rails 3 Language Pack. This is for all Rails 3.x apps.
class LanguagePack::Rails3 < LanguagePack::Rails2
  # detects if this is a Rails 3.x app
  # @return [Boolean] true if it's a Rails 3.x app
  def self.use?
    if gemfile_lock?
      rails_version = LanguagePack::Ruby.gem_version('railties')
      rails_version >= Gem::Version.new('3.0.0') && rails_version < Gem::Version.new('4.0.0') if rails_version
    end
  end

  def name
    "Ruby/Rails"
  end

  def default_process_types
    # let's special case thin here
    web_process = gem_is_bundled?("thin") ?
                    "bundle exec thin start -R config.ru -e $RAILS_ENV -p $PORT" :
                    "bundle exec rails server -p $PORT"

    super.merge({
      "web" => web_process,
      "console" => "bundle exec rails console"
    })
  end

private

  def plugins
    super.concat(%w( rails3_serve_static_assets )).uniq
  end

  # runs the tasks for the Rails 3.1 asset pipeline
  def run_assets_precompile_rake_task
    log("assets_precompile") do
      setup_database_url_env

      if rake_task_defined?("adaptive:all")
        topic("Building Adaptive Lab assets")
        ENV["RAILS_GROUPS"] ||= "assets"
        ENV["RAILS_ENV"]    ||= "production"

        puts "Running: rake adaptive:all"
        require 'benchmark'
        time = Benchmark.realtime { pipe("env PATH=$PATH:bin bundle exec rake adaptive:all 2>&1") }

        if $?.success?
          log "adaptivelab_compile", :status => "success"
          puts "Adaptive Lab compilation completed (#{"%.2f" % time}s)"
        else
          log "adaptivelab_compile", :status => "failure"
          puts "Adaptive Lab compilation failed"
        end
      end
    end
  end

  # setup the database url as an environment variable
  def setup_database_url_env
    ENV["DATABASE_URL"] ||= begin
      # need to use a dummy DATABASE_URL here, so rails can load the environment
      scheme =
        if gem_is_bundled?("pg")
          "postgres"
        elsif gem_is_bundled?("mysql")
          "mysql"
        elsif gem_is_bundled?("mysql2")
          "mysql2"
        elsif gem_is_bundled?("sqlite3") || gem_is_bundled?("sqlite3-ruby")
          "sqlite3"
        end
      "#{scheme}://user:pass@127.0.0.1/dbname"
    end
  end
end
