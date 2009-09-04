require File.expand_path(File.join(File.dirname(__FILE__), "/../helper"))

begin
  require "xml/dom/builder"
  require "net/http"

  module Johnson
    class BrowserTest < Johnson::TestCase
      def setup
        super
        @runtime.evaluate('Johnson.require("johnson/browser");')
      end

      def test_set_location_returns_location
        filename = "file://#{File.expand_path(__FILE__)}"

        @runtime.evaluate("window.location = '#{filename}'")

        uri = URI.parse(filename)
        assert_equal(uri.to_s, @runtime.evaluate('window.location').to_s)
      end

      def test_set_location_with_url
        file = File.expand_path(__FILE__) + "/../../assets/index.html"
        filename = "file://#{File.expand_path(file)}"
        @runtime.evaluate("window.location = '#{filename}'")
        doc = @runtime.evaluate('window.document')
        assert_not_nil(doc)
      end
    end
  end
rescue LoadError
  # Yehuda is teh lame.
end
