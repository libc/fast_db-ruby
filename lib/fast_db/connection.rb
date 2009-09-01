require 'socket'
require 'enumerator'

module FastDB
  class Connection
    include Constants

    def initialize(host = nil, port = nil)
      @schemas = {}
      connect(host, port) if host && port
    end

    def connect(host, port)
      @socket = TCPSocket.new(host, port)
      @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
    end

    def close
      @socket.shutdown
      @socket.close
    end

    def create_table(table_name, fields)
      data = [table_name, fields.size].pack('Z*c')
      fields.each do |name, type|
        data << [type, 0, name.to_s, "", ""].pack("ccZ*Z*Z*")
      end
      transaction do
        send_command CliCmdCreateTable, data
        simple_response
      end
    end

    def list_tables
      send_command CliCmdShowTables
      list_response
    end

    def drop_table(table)
      @schemas[table] = nil

      transaction do
        send_command CliCmdDropTable, "#{table}\0"
        simple_response
      end
    end

    def commit
      send_command CliCmdCommit
      simple_response
    end

    def abort
      send_command CliCmdAbort
      simple_response
    end

    def insert(table, obj = {})
      schema = schema_for_table(table)

      obj = obj.dup
      schema.raw_fields.each do |f|
        obj[f.name] = :auto_increment if f.type == CliAutoincrement && (!obj[f.name.to_s] && !obj[f.name.to_sym])
      end

      n, defs, vals = FastDB::Utils.pack_types(schema.fields, obj)
      transaction do
        send_command CliCmdPrepareAndInsert, "insert into #{table}\0" << n << defs << vals
        id_response
      end
    end

    def select(query, options = {})
      process(query, options).map { |a| a }
    end

    def process(query, options = {}, &block)
      limit      = options.delete :limit
      offset     = options.delete :offset
      for_update = options.delete :for_update

      table_name = FastDB::Utils.extract_table_name(query)
      statement, types, vals = FastDB::Utils.preprocess_query(query, options)

      req = [FastDB::Utils.bytesize_or_length(types), schema_for_table(table_name).raw_fields.length, FastDB::Utils.bytesize_or_length(statement)].pack("ccn")

      req << statement
      schema_for_table(table_name).raw_fields.each do |fld|
        req << [fld.type, fld.name].pack("cZ*")
      end
      req << (for_update ? "\x01" : "\x00")
      req << vals

      statement_id = new_statement_id
      send_command CliCmdPrepareAndExecute, req, statement_id
      count = request_response
      # limit ||= count

      resultset = Resultset.new(self, schema_for_table(table_name), statement_id)
      if block_given?
        resultset.each(&block)
      else
        resultset
      end
    end

    def delete(table, query = "", options = {})
      if Integer === query
        options[:_id] = query
        query = "id = :_id"
      end

      query = query.size > 0 ? " where #{query}" : query
      transaction do
        process("select * from #{table}#{query}", options.merge(:for_update => true)).delete_all
      end
    end

    def update(table, fields, query, options)
      if Integer === query
        options[:_id] = query
        query = "id = :_id"
      end

      query = query.size > 0 ? " where #{query}" : query
      transaction do
        process("select * from #{table}#{query}", options.merge(:for_update => true)).update_all fields
      end
    end

    def describe_table(table)
      send_command CliCmdDescribeTable, "#{table}\0"
      fields = {}
      raw_fields = array_response("ccZ*Z*Z*").map do |item|
        type, flags, name, ref, iref = item
        fields[name.to_s] = fields[name.to_sym] = TableColumn.new(name, type, flags)
      end
      Table.new(table, fields, raw_fields)
    end

    def send_command(cmd, data = "", id = 0)
      a = [4 + 4 + 4 + FastDB::Utils.bytesize_or_length(data), cmd, id].pack("NNN")
      a << data
      send(a)
    end

    def transaction
      if Thread.current[:_fast_db_open_transactions]
        Thread.current[:_fast_db_open_transactions] += 1
      else
        Thread.current[:_fast_db_open_transactions]  = 1
      end

      committed = false
      ret = yield
      commit
      committed = true
      ret
    ensure
      Thread.current[:_fast_db_open_transactions] -= 1
      abort if !committed && Thread.current[:_fast_db_open_transactions] == 0
    end

    def request_response
      error_code = recv(4).unpack("N").first
      raise "unknown error" unless error_code
      if error_code < CliLastError
        error_code
      else
        raise *error_code_to_string(error_code)
      end
    end

    def update_implementation(schema, fields, statement_id)
      n, defs, vals = FastDB::Utils.pack_types(schema.fields, fields)
      send_command CliCmdUpdate, vals, statement_id
      simple_response
    end

  protected
    def send(data)
      @socket.send(data, 0)
    end

    def recv(l)
      @socket.recv(l, 0)
    end
    public :recv # TODO: remove public

    def new_statement_id
      @last_statement_id = (@last_statement_id || 0) + 1
    end

    def schema_for_table(table)
      @schemas[table] ||= describe_table(table)
    end

    def simple_response
      error_code = recv(4).unpack("N").first
      if error_code == CliOk
        true
      else
        raise *error_code_to_string(error_code)
      end
    end
    public :simple_response

    def list_response
      len, n = recv(8).unpack("NN")
      recv(len).unpack("Z*"*n)
    end

    def array_response(unpack_pattern)
      len, n = recv(8).unpack("NN")
      raise *error_code_to_string(n) if n >= CliLastError

      arr = recv(len).unpack(unpack_pattern*n)
      ret = []
      arr.each_slice(arr.size / n) { |s| ret << s }
      ret
    end

    def id_response
      d = recv(12)
      error_code, pk, stmt_id = d.unpack("N3")
      if error_code == CliOk
        stmt_id == 0 ? nil : stmt_id
      else
        raise *error_code_to_string(error_code)
      end
    end

    def error_code_to_string(ec)
      ERROR_DESCRIPTIONS[ec] || "unknown error"
    end
  end
end