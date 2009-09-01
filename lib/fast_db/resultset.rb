module FastDB
  class Resultset
    include Enumerable

    def initialize(connection, schema, statement_id)
      @connection = connection
      @schema = schema
      @statement_id = statement_id
    end

    attr_reader :object

    def first
      send_command FastDB::Connection::CliCmdGetFirst
      unpack_object
    end

    def next
      send_command FastDB::Connection::CliCmdGetNext
      unpack_object
    end

    def unpack_object
      begin
        len = @connection.request_response
      rescue FastDB::Connection::RecordNotFound
        return @object = nil
      end

      oid = @connection.recv(4)

      @object = FastDB::Utils.unpack_row(@schema, @connection.recv(len - 8))
    end
    private :unpack_object

    def send_command(cmd)
      @connection.send_command(cmd, "", @statement_id)
    end

    def each
      if first
        yield object
        yield object while self.next
      end
    end

    def delete_all
      send_command FastDB::Connection::CliCmdRemove
      @connection.simple_response
    end

    def update_all(fields)
      fields = fields.inject({}) { |h, (k, v)| h.update :"#{k}" => v }
      each do |object|
        @connection.update_implementation @schema, object.merge(fields), @statement_id
      end
    end
  end
end