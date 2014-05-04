require 'minitest/autorun'

require 'rack/test'
require 'sprockets/rails/environment'
require 'sprockets/rails/helper'

Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

class EnvironmentTest < Minitest::Test
  include Rack::Test::Methods

  ROOT = File.expand_path("../../tmp/app", __FILE__)
  FIXTURES_PATH = File.expand_path("../fixtures", __FILE__)

  def setup
    @digests = Hash.new
    fixture_files = Dir.entries(FIXTURES_PATH).select { |f| !File.directory? File.join(FIXTURES_PATH, f) }
    fixture_files.each { |f| @digests[f] = app.assets[f].digest }
  end

  def rails_app
    require 'sprockets/railtie'
    require 'rails'

    ENV['RAILS_ENV'] = 'test'

    FileUtils.mkdir_p ROOT
    Dir.chdir ROOT

    app = Class.new(Rails::Application)
    app.config.secret_key_base = "3b7cd727ee24e8444053437c36cc66c4"
    app.config.eager_load = false

    app.assets = @assets = Sprockets::Rails::Environment.new
    @assets.append_path FIXTURES_PATH
    @assets.context_class.class_eval do
      include ::Sprockets::Rails::Helper
    end

    ActionView::Base # load ActionView
    app.initialize!
  end

  def app
    @app ||= rails_app
  end

  def test_assets_with_digest
    get "/assets/foo.js"
    # get "/assets/foo-#{@digests['foo.js']}.js"
    assert_equal 200, last_response.status
  end

  def test_assets_with_no_digest
    # should throw error
  end

  def test_assets_with_wrong_digest
    # should redirect to correct asset
  end
end
