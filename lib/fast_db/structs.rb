module FastDB
  class Connection
    TableColumn = Struct.new(:name, :type, :flags)
    Table = Struct.new(:name, :fields, :raw_fields)
  end
end