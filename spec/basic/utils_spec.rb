require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FastDB::Utils do
  describe "preprocess_query" do
    def r(*a); FastDB::Utils.preprocess_query(*a); end

    it "returns query unchanged if no params there" do
      ['select', "select * from something where a = 'b' and c = 'd' or i = 3 || % blah blah"].each do |s|
        r(s, {}).should == [s+"\0", "", ""]
      end
    end

    it "replaces query named param with null char" do
      r("select * from something where name = :name", {:name => "test"}).should == ["select * from something where name = \0\t\0", "\t", "test\000"]
      r("select * from something where name = :name and :a = :b", {:name => 'a', :a => 1, :b => 2}).should == ["select * from something where name = \000\t and \000\004 = \000\004\000", "\t\004\004", "a\000\000\000\000\001\000\000\000\002"]
      r("select * from something where name = :_id", {:_id => "test"}).should == ["select * from something where name = \0\t\0", "\t", "test\000"]
    end
  end

  describe "extract_table_name" do
    def r(*a); FastDB::Utils.extract_table_name(*a) ; end

    it "returns table name from query" do
      r("select * from sometable where a = :b").should == 'sometable'
      r("piece of crap").should == nil
      r("select * from table").should == 'table'
    end
  end
end