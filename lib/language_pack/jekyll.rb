require "language_pack"
require "language_pack/rack"

# Jekyll Language Pack.
class LanguagePack::Jekyll < LanguagePack::Rack

  # detects if this is a valid Jekyll site by seeing if "_config.yml" exists
  # @return [Boolean] true if it's a Jekyll app
  def self.use?
    super && File.exist?("jekyll/_config.yml")
  end

  def name
    "Jekyll"
  end

  def compile
    super
    allow_git do
      build_jekyll_layout
      generate_jekyll_site
    end
  end

  private

  def build_jekyll_layout
    if rake_task_defined?("jekyll:build_layout")
      topic "Running: rake jekyll:build_layout"
      run("env PATH=$PATH:bin bundle exec rake jekyll:build_layout")
    end
  end

  def generate_jekyll_site
    require 'benchmark'

    topic "Running: jekyll"
    time = Benchmark.realtime { pipe("env PATH=$PATH:bin bundle exec jekyll 2>&1") }

    if $?.success?
      log "jekyll_build", :status => "success"
      puts "Jekyll build completed (#{"%.2f" % time}s)"
    else
      log "jekyll_build", :status => "failure"
      puts "Jekyll build failed"
    end
  end
end