require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

class ExportTest < Johnson::NodeTestCase
  def test_export
    assert_sexp([[:export, [[:name, "name1"], [:name, "name2"]]]],
      @parser.parse('export name1, name2;'))
  end
end