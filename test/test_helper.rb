require 'minitest/autorun'

require 'action_view'
require 'sprockets'
require 'sprockets/rails/helper'

Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

class HelperTest < Minitest::Test
  FIXTURES_PATH = File.expand_path("../fixtures", __FILE__)

  def setup
    assets = @assets = Sprockets::Environment.new
    @assets.append_path FIXTURES_PATH
    @assets.context_class.class_eval do
      include ::Sprockets::Rails::Helper
    end

    @view = ActionView::Base.new
    @view.extend ::Sprockets::Rails::Helper
    @view.assets_environment = @assets
    @view.assets_prefix      = "/assets"

    # Rails 2.x
    unless @view.respond_to?(:config)
      @view.class_eval { attr_accessor :config }
      @view.config = Struct.new(:asset_host).new
    end

    @assets.context_class.assets_prefix = @view.assets_prefix
    @assets.context_class.config        = @view.config

    Sprockets::Rails::Helper.raise_runtime_errors = false

    @digests = Hash.new
    fixture_files = Dir.entries(FIXTURES_PATH).select { |f| !File.directory? File.join(FIXTURES_PATH, f) }
    fixture_files.each { |f| @digests[f] = @assets[f].digest }
  end

  def test_truth
  end
end

class NoHostHelperTest < HelperTest
  def test_javascript_include_tag
    assert_equal %(<script src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static")
    assert_equal %(<script src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static.js")
    assert_equal %(<script src="/javascripts/static.js"></script>),
      @view.javascript_include_tag(:static)

    assert_equal %(<script src="/elsewhere.js"></script>),
      @view.javascript_include_tag("/elsewhere.js")
    assert_equal %(<script src="/script1.js"></script>\n<script src="/javascripts/script2.js"></script>),
      @view.javascript_include_tag("/script1.js", "script2.js")

    assert_equal %(<script src="http://example.com/script"></script>),
      @view.javascript_include_tag("http://example.com/script")
    assert_equal %(<script src="http://example.com/script.js"></script>),
      @view.javascript_include_tag("http://example.com/script.js")
    assert_equal %(<script src="//example.com/script.js"></script>),
      @view.javascript_include_tag("//example.com/script.js")

    assert_equal %(<script defer="defer" src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static", :defer => "defer")
    assert_equal %(<script async="async" src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static", :async => "async")
  end

  def test_stylesheet_link_tag
    assert_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("static")
    assert_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("static.css")
    assert_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:static)

    assert_equal %(<link href="/elsewhere.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("/elsewhere.css")
    assert_equal %(<link href="/style1.css" media="screen" rel="stylesheet" />\n<link href="/stylesheets/style2.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("/style1.css", "style2.css")

    assert_equal %(<link href="http://www.example.com/styles/style" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("http://www.example.com/styles/style")
    assert_equal %(<link href="http://www.example.com/styles/style.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("http://www.example.com/styles/style.css")
    assert_equal %(<link href="//www.example.com/styles/style.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("//www.example.com/styles/style.css")

    assert_equal %(<link href="/stylesheets/print.css" media="print" rel="stylesheet" />),
      @view.stylesheet_link_tag("print", :media => "print")
    assert_equal %(<link href="/stylesheets/print.css" media="&lt;hax&gt;" rel="stylesheet" />),
      @view.stylesheet_link_tag("print", :media => "<hax>")
  end

  def test_javascript_path
    assert_equal "/javascripts/xmlhr.js", @view.javascript_path("xmlhr")
    assert_equal "/javascripts/xmlhr.js", @view.javascript_path("xmlhr.js")
    assert_equal "/javascripts/super/xmlhr.js", @view.javascript_path("super/xmlhr")
    assert_equal "/super/xmlhr.js", @view.javascript_path("/super/xmlhr")

    assert_equal "/javascripts/xmlhr.js?foo=1", @view.javascript_path("xmlhr.js?foo=1")
    assert_equal "/javascripts/xmlhr.js?foo=1", @view.javascript_path("xmlhr?foo=1")
    assert_equal "/javascripts/xmlhr.js#hash", @view.javascript_path("xmlhr.js#hash")
    assert_equal "/javascripts/xmlhr.js#hash", @view.javascript_path("xmlhr#hash")
    assert_equal "/javascripts/xmlhr.js?foo=1#hash", @view.javascript_path("xmlhr.js?foo=1#hash")
  end

  def test_stylesheet_path
    assert_equal "/stylesheets/bank.css", @view.stylesheet_path("bank")
    assert_equal "/stylesheets/bank.css", @view.stylesheet_path("bank.css")
    assert_equal "/stylesheets/subdir/subdir.css", @view.stylesheet_path("subdir/subdir")
    assert_equal "/subdir/subdir.css", @view.stylesheet_path("/subdir/subdir.css")

    assert_equal "/stylesheets/bank.css?foo=1", @view.stylesheet_path("bank.css?foo=1")
    assert_equal "/stylesheets/bank.css?foo=1", @view.stylesheet_path("bank?foo=1")
    assert_equal "/stylesheets/bank.css#hash", @view.stylesheet_path("bank.css#hash")
    assert_equal "/stylesheets/bank.css#hash", @view.stylesheet_path("bank#hash")
    assert_equal "/stylesheets/bank.css?foo=1#hash", @view.stylesheet_path("bank.css?foo=1#hash")
  end
end

class RelativeHostHelperTest < HelperTest
  def setup
    super

    @view.config.asset_host = "assets.example.com"
  end

  def test_javascript_path
    assert_equal "//assets.example.com/javascripts/xmlhr.js", @view.javascript_path("xmlhr")
    assert_equal "//assets.example.com/javascripts/xmlhr.js", @view.javascript_path("xmlhr.js")
    assert_equal "//assets.example.com/javascripts/super/xmlhr.js", @view.javascript_path("super/xmlhr")
    assert_equal "//assets.example.com/super/xmlhr.js", @view.javascript_path("/super/xmlhr")

    assert_equal "//assets.example.com/javascripts/xmlhr.js?foo=1", @view.javascript_path("xmlhr.js?foo=1")
    assert_equal "//assets.example.com/javascripts/xmlhr.js?foo=1", @view.javascript_path("xmlhr?foo=1")
    assert_equal "//assets.example.com/javascripts/xmlhr.js#hash", @view.javascript_path("xmlhr.js#hash")
    assert_equal "//assets.example.com/javascripts/xmlhr.js#hash", @view.javascript_path("xmlhr#hash")
    assert_equal "//assets.example.com/javascripts/xmlhr.js?foo=1#hash", @view.javascript_path("xmlhr.js?foo=1#hash")

    assert_equal %(<script src="//assets.example.com/assets/foo-#{@digests['foo.js']}.js"></script>),
      @view.javascript_include_tag("foo")
    assert_equal %(<script src="//assets.example.com/assets/foo-#{@digests['foo.js']}.js"></script>),
      @view.javascript_include_tag("foo.js")
    assert_equal %(<script src="//assets.example.com/assets/foo-#{@digests['foo.js']}.js"></script>),
      @view.javascript_include_tag(:foo)
  end

  def test_stylesheet_path
    assert_equal "//assets.example.com/stylesheets/bank.css", @view.stylesheet_path("bank")
    assert_equal "//assets.example.com/stylesheets/bank.css", @view.stylesheet_path("bank.css")
    assert_equal "//assets.example.com/stylesheets/subdir/subdir.css", @view.stylesheet_path("subdir/subdir")
    assert_equal "//assets.example.com/subdir/subdir.css", @view.stylesheet_path("/subdir/subdir.css")

    assert_equal "//assets.example.com/stylesheets/bank.css?foo=1", @view.stylesheet_path("bank.css?foo=1")
    assert_equal "//assets.example.com/stylesheets/bank.css?foo=1", @view.stylesheet_path("bank?foo=1")
    assert_equal "//assets.example.com/stylesheets/bank.css#hash", @view.stylesheet_path("bank.css#hash")
    assert_equal "//assets.example.com/stylesheets/bank.css#hash", @view.stylesheet_path("bank#hash")
    assert_equal "//assets.example.com/stylesheets/bank.css?foo=1#hash", @view.stylesheet_path("bank.css?foo=1#hash")

    assert_equal %(<link href="//assets.example.com/assets/foo-#{@digests['foo.css']}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo")
    assert_equal %(<link href="//assets.example.com/assets/foo-#{@digests['foo.css']}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo.css")
    assert_equal %(<link href="//assets.example.com/assets/foo-#{@digests['foo.css']}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:foo)
  end

  def test_asset_url
    assert_equal "var url = '//assets.example.com/assets/foo-#{@digests['foo.js']}.js';\n", @assets["url.js"].to_s
    assert_equal "p { background: url(//assets.example.com/assets/logo-#{@digests['logo.png']}.png); }\n", @assets["url.css"].to_s
  end
end


class DigestHelperTest < NoHostHelperTest
  def test_javascript_include_tag
    super

    assert_equal %(<script src="/assets/foo-#{@digests['foo.js']}.js"></script>),
      @view.javascript_include_tag("foo")
    assert_equal %(<script src="/assets/foo-#{@digests['foo.js']}.js"></script>),
      @view.javascript_include_tag("foo.js")
    assert_equal %(<script src="/assets/foo-#{@digests['foo.js']}.js"></script>),
      @view.javascript_include_tag(:foo)
  end

  def test_stylesheet_link_tag
    super

    assert_equal %(<link href="/assets/foo-#{@digests['foo.css']}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo")
    assert_equal %(<link href="/assets/foo-#{@digests['foo.css']}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo.css")
    assert_equal %(<link href="/assets/foo-#{@digests['foo.css']}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:foo)
  end

  def test_javascript_path
    super

    assert_equal "/assets/foo-#{@digests['foo.js']}.js", @view.javascript_path("foo")
  end

  def test_stylesheet_path
    super

    assert_equal "/assets/foo-#{@digests['foo.css']}.css", @view.stylesheet_path("foo")
  end

  def test_asset_digest
    assert_equal @digests['foo.js'], @view.asset_digest("foo.js")
    assert_equal @digests['foo.css'], @view.asset_digest("foo.css")
  end

  def test_asset_digest_path
    assert_equal "foo-#{@digests['foo.js']}.js", @view.asset_digest_path("foo.js")
    assert_equal "foo-#{@digests['foo.css']}.css", @view.asset_digest_path("foo.css")
  end

  def test_asset_url
    assert_equal "var url = '/assets/foo-#{@digests['foo.js']}.js';\n", @assets["url.js"].to_s
    assert_equal "p { background: url(/assets/logo-#{@digests['logo.png']}.png); }\n", @assets["url.css"].to_s
  end
end

class DebugHelperTest < NoHostHelperTest
  def setup
    super
    @view.debug_assets = true
  end

  def test_javascript_include_tag
    super

    assert_equal %(<script src="/assets/foo-#{@digests['foo.js']}.js?body=1"></script>),
      @view.javascript_include_tag(:foo)
    assert_equal %(<script src="/assets/foo-#{@digests['foo.js']}.js?body=1"></script>\n<script src="/assets/bar-#{@digests['bar.js']}.js?body=1"></script>),
      @view.javascript_include_tag(:bar)
    assert_equal %(<script src="/assets/dependency-#{@digests['dependency.js']}.js?body=1"></script>\n<script src="/assets/file1-#{@digests['file1.js']}.js?body=1"></script>\n<script src="/assets/file2-#{@digests['file2.js']}.js?body=1"></script>),
      @view.javascript_include_tag(:file1, :file2)
  end

  def test_stylesheet_link_tag
    super

    assert_equal %(<link href="/assets/foo-#{@digests['foo.css']}.css?body=1" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:foo)
    assert_equal %(<link href="/assets/foo-#{@digests['foo.css']}.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/bar-#{@digests['bar.css']}.css?body=1" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:bar)
    assert_equal %(<link href="/assets/dependency-#{@digests['dependency.css']}.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/file1-#{@digests['file1.css']}.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/file2-#{@digests['file2.css']}.css?body=1" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:file1, :file2)
  end

  def test_javascript_path
    super

    assert_equal "/assets/foo-#{@digests['foo.js']}.js", @view.javascript_path("foo")
  end

  def test_stylesheet_path
    super

    assert_equal "/assets/foo-#{@digests['foo.css']}.css", @view.stylesheet_path("foo")
  end
end

class ManifestHelperTest < NoHostHelperTest
  def setup
    super

    @manifest = Sprockets::Manifest.new(@assets, FIXTURES_PATH)
    @manifest.assets["foo.js"] = "foo-#{@digests['foo.js']}.js"
    @manifest.assets["foo.css"] = "foo-#{@digests['foo.css']}.css"

    @view.assets_environment = nil
    @view.assets_manifest = @manifest
  end

  def test_javascript_include_tag
    super

    assert_equal %(<script src="/assets/foo-#{@digests['foo.js']}.js"></script>),
      @view.javascript_include_tag("foo")
    assert_equal %(<script src="/assets/foo-#{@digests['foo.js']}.js"></script>),
      @view.javascript_include_tag("foo.js")
    assert_equal %(<script src="/assets/foo-#{@digests['foo.js']}.js"></script>),
      @view.javascript_include_tag(:foo)
  end

  def test_stylesheet_link_tag
    super

    assert_equal %(<link href="/assets/foo-#{@digests['foo.css']}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo")
    assert_equal %(<link href="/assets/foo-#{@digests['foo.css']}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo.css")
    assert_equal %(<link href="/assets/foo-#{@digests['foo.css']}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:foo)
  end

  def test_javascript_path
    super

    assert_equal "/assets/foo-#{@digests['foo.js']}.js", @view.javascript_path("foo")
  end

  def test_stylesheet_path
    super

    assert_equal "/assets/foo-#{@digests['foo.css']}.css", @view.stylesheet_path("foo")
  end

  def test_absolute_asset_path_error
    Sprockets::Rails::Helper.raise_runtime_errors = true
    @view.assets_environment = @assets

    assert_equal "/assets/foo-#{@digests['foo.js']}.js", @view.asset_path("foo.js")
    assert_raises(Sprockets::Rails::Helper::AbsoluteAssetPathError) do
      @view.asset_path("/assets/foo.js")
    end

    assert_equal "/unknown.js", @view.asset_path("unknown.js")
    assert_equal "/assets/unknown.js", @view.asset_path("/assets/unknown.js")

    Sprockets::Rails::Helper.raise_runtime_errors = false
    assert_equal "/assets/foo.js", @view.asset_path("/assets/foo.js")
  end

  def test_asset_digest_path
    assert_equal "foo-#{@digests['foo.js']}.js", @view.asset_digest_path("foo.js")
    assert_equal "foo-#{@digests['foo.css']}.css", @view.asset_digest_path("foo.css")
  end

  def test_asset_digest
    assert_equal @digests['foo.js'], @view.asset_digest("foo.js")
    assert_equal @digests['foo.css'], @view.asset_digest("foo.css")
  end
end

class PrecompileHelperTest < HelperTest
  def setup
    super

    Sprockets::Rails::Helper.raise_runtime_errors = true
  end

  def test_public_folder_fallback_works_correctly
    @view.asset_path("asset-does-not-exist-foo.js")
    @view.asset_url("asset-does-not-exist-foo.js")
    @view.stylesheet_link_tag("asset-does-not-exist-foo.js")
    @view.javascript_include_tag("asset-does-not-exist-foo.js")
  end

  def test_asset_not_precompiled_error
    Sprockets::Rails::Helper.precompile = [ lambda {|logical_path| false } ]

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.asset_path("foo.js")
    end

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.asset_url("foo.js")
    end

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.javascript_path("foo")
    end

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.javascript_url("foo")
    end

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.javascript_include_tag("foo.js")
    end

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.javascript_include_tag("foo")
    end

    error = assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.javascript_include_tag(:foo)
    end

    Sprockets::Rails::Helper.precompile = ['foo.js']

    @view.asset_path("foo.js")
    @view.asset_url("foo.js")
    @view.javascript_path("foo")
    @view.javascript_url("foo")
    @view.javascript_include_tag("foo.js")
    @view.javascript_include_tag("foo")
    @view.javascript_include_tag(:foo)

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.stylesheet_path("foo")
    end

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.stylesheet_url("foo")
    end

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.stylesheet_link_tag("foo")
    end

    Sprockets::Rails::Helper.precompile = ['foo.css']

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.javascript_include_tag("foo")
    end

    @view.stylesheet_path("foo")
    @view.stylesheet_url("foo")
    @view.stylesheet_link_tag("foo")

    Sprockets::Rails::Helper.precompile = [ lambda {|logical_path| true } ]

    @view.asset_path("foo.js")
    @view.asset_url("foo.js")
    @view.javascript_path("foo")
    @view.javascript_url("foo")
    @view.javascript_include_tag("foo.js")
    @view.javascript_include_tag("foo")
    @view.javascript_include_tag(:foo)
    @view.stylesheet_path("foo")
    @view.stylesheet_url("foo")
    @view.stylesheet_link_tag("foo")
  end

  def test_debug_mode
    @view.debug_assets = true

    Sprockets::Rails::Helper.precompile = [ lambda {|logical_path| false } ]

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.javascript_include_tag("bar")
    end

    Sprockets::Rails::Helper.precompile = ['bar.js']

    @view.javascript_include_tag("bar")
  end

  def test_non_javascripts_and_stylesheets
    loose_app_assets = lambda do |filename|
      !%w(.js .css).include?(File.extname(filename))
    end
    Sprockets::Rails::Helper.precompile = [loose_app_assets, /(?:\/|\\|\A)application\.(css|js)$/]

    @view.asset_path("logo.png")
  end
end

class AutomaticDependenciesFromHelpersTest < HelperTest
  def test_dependency_added
    assert_equal ["logo.png", "url.css.erb"], @assets['url.css'].send(:dependency_paths).map {|d| File.basename(d.pathname) }.sort
  end

  def test_ignores_missing_dependencies
    assert_equal ["missing.css.erb"], @assets['error/missing.css'].send(:dependency_paths).map {|d| File.basename(d.pathname) }.sort
  end

end
