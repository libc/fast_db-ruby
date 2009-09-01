require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FastDB::Connection do
  before :all do
    @port = setup_database
  end

  describe "initialize method" do
    it "connects to the database" do
      lambda do
        FastDB::Connection.new('localhost', @port).close
      end.should_not raise_error
    end
  end

  describe "create_table" do
    it "creates table and returns true" do
      fc = FastDB::Connection.new('localhost', @port)
      fc.create_table("test", :name => FastDB::Connection::CliAsciiz).should == true
      fc.list_tables.include?('test').should == true
      fc.drop_table('test').should == true
    end
  end

  describe "insert" do
    before :all do
      @fc = FastDB::Connection.new('localhost', @port)
      @fc.create_table('test', :name => FastDB::Connection::CliAsciiz)
    end

    it "returns a number" do
      @fc.insert('test', :name => 'neat string').is_a?(Integer).should == true
    end

    it "inserted string become selectable" do
      @fc.insert('test', :name => 'another neat string')
      @fc.select('select * from test').include?(:name => 'another neat string').should == true
    end

    it "magically handles auto_increment" do
      @fc.create_table('auto_increment_test', :id => FastDB::Connection::CliAutoincrement)
      3.times { @fc.insert('auto_increment_test') }
      @fc.select('select * from auto_increment_test').all? { |a| a[:id] == 0 }.should == false
      @fc.drop_table('auto_increment_test')
    end

    after :all do
      @fc.drop_table('test')
      @fc.commit
    end
  end

  describe "select" do
    before :all do
      @fc = FastDB::Connection.new('localhost', @port)
      @fc.create_table('test', :id => FastDB::Connection::CliAutoincrement, :name => FastDB::Connection::CliAsciiz)
    end

    it "works without parameters" do
      @fc.insert('test', :name => 'text1')
      @fc.select('select * from test').any? do |a|
        a[:name] == 'text1'
      end.should == true
    end

    it "works with string parameter" do
      @fc.insert('test', :name => 'text1')
      @fc.insert('test', :name => 'text2')

      array = @fc.select('select * from test where name = :text', :text => 'text2')
      array.any? { |a| a[:name] == 'text2' }.should == true
      array.any? { |a| a[:name] == 'text1' }.should == false
    end

    it "works with numeric parameter" do
      @fc.insert('test', :name => 'text3')
      id = @fc.select('select * from test where name = :text', :text => 'text3')[0][:id]

      array = @fc.select('select * from test where id = :id', :id => id)
      array.size.should == 1
      array[0][:name].should == 'text3'
    end

    it "works with several parameters" do
      @fc.insert('test', :name => "text4")
      @fc.select('select * from test where name = :name and id > :id1 and id < :id2', :name => "text4", :id1 => 100, :id2 => 100).should == []
    end

    after :all do
      @fc.drop_table('test')
      @fc.commit
    end
  end

  describe "delete" do
    before :all do
      @fc = FastDB::Connection.new('localhost', @port)
      @fc.create_table('test', :id => FastDB::Connection::CliAutoincrement, :name => FastDB::Connection::CliAsciiz)
    end

    it "deletes all records if query is not specified" do
      3.times { @fc.insert('test') }
      @fc.select('select * from test').size.should == 3
      @fc.delete('test')
      @fc.select('select * from test').size.should == 0
    end

    it "deletes by id if a number passed as the parameter" do
      3.times { @fc.insert('test') }
      ids = @fc.select('select * from test').map { |a| a[:id] }
      @fc.delete('test', ids.pop)
      @fc.select('select * from test').map { |a| a[:id] }.should == ids
      @fc.delete('test')
    end

    it "deletes by id if a number passed as the parameter" do
      3.times { |i| @fc.insert('test', :name => "text#{i}") }
      @fc.delete('test', "name = :name", :name => 'text1')
      @fc.select('select * from test').map { |a| a[:name] }.should == ["text0", "text2"]
      @fc.delete('test')
    end

    after :all do
      @fc.drop_table('test')
      @fc.commit
    end
  end

  describe "insert/select (for variety of types)" do
    before :all do
      @fc = FastDB::Connection.new('localhost', @port)
      @fc.create_table('test', :string => FastDB::Connection::CliAsciiz,
                               :int1   => FastDB::Connection::CliInt1,
                               :int2   => FastDB::Connection::CliInt2,
                               :int4   => FastDB::Connection::CliInt4,
                               :int8   => FastDB::Connection::CliInt8,
                               :real4  => FastDB::Connection::CliReal4,
                               :real8  => FastDB::Connection::CliReal8,
                               :bool   => FastDB::Connection::CliBool)
    end

    it "casts null to zero and ''" do
      @fc.insert('test', {})
      @fc.select('select * from test').
          include?(:string => '', :int1 => 0, :int2 => 0,
                   :int4 => 0,    :int8 => 0, :real4 => 0.0, 
                   :real8 => 0.0, :bool => false).should == true
    end

    it "saves different kinds of values" do
      obj = {:string => 'a string', :int1 => 10,
             :int2 => 1000, :int4 => 1_000_000,
             :int8 => 1_000_000_000_000,
             :real4 => 1.0, :real8 => 1.0,
             :bool => true}
      @fc.insert('test', obj)
      @fc.insert('test', :real4 => 3.14159265, :real8 => 2.71828183)

      @fc.select('select * from test').
        include?(obj).should == true
      @fc.select('select * from test').any? do |a|
        (3.14..3.15).include?(a[:real4]) && 
          (2.71..2.72).include?(a[:real8])
      end.should == true
    end

    it "supports negative values" do
      obj = {:string => 'a string', :int1 => -10,
             :int2 => -1000, :int4 => -1_000_000,
             :int8 => -1_000_000_000_000,
             :real4 => -1.0, :real8 => -1.0,
             :bool => false}
      @fc.insert('test', obj)
      @fc.select('select * from test').
        include?(obj).should == true
    end

    after :all do
      @fc.drop_table('test')
      @fc.commit
    end
  end

  describe "update" do
    before :all do
      @fc = FastDB::Connection.new('localhost', @port)
      @fc.create_table('test', :id => FastDB::Connection::CliAutoincrement, :key => FastDB::Connection::CliAsciiz, :value => FastDB::Connection::CliAsciiz)
    end

    it "updates values by query" do
      3.times { |i| @fc.insert('test', :key => "key#{i}", :value => "value#{i}") }
      @fc.select('select * from test where key = :key', :key => "key1").first[:value].should == 'value1'
      @fc.update('test', {:value => 'updated value'}, "key = :key", {:key => 'key1'})
      @fc.select('select * from test where key = :key', :key => "key1").first[:value].should == 'updated value'
    end

    after :all do
      @fc.drop_table('test')
      @fc.commit
    end
  end

  after :all do
    teardown_database
  end
end