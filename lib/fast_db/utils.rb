module FastDB
  module Utils
    extend self
    include Constants

    def pack_type(val, hint = nil)
      type, ret = nil, nil
      case val
      when Float
        type = CliReal8
        ret = [val].pack("G")
      when -2147483648..2147483647
        type = CliInt4
        ret = [val].pack("N")
      when -9223372036854775808...-2147483648, 2147483648..9223372036854775807
        type = CliInt8
        ret = [val >> 32, val & 0xffff_ffff].pack("NN")
      when Integer
        raise TypeError, "#{val} is too big to store in fastdb"
      when false, true
        type = CliBool
        ret = [val ? 1 : 0].pack("c")
      when nil
        case hint
        when CliInt1, CliInt2, CliInt4, CliInt8
          type = CliInt1
          ret = [0].pack("N")
        when CliReal8, CliReal4
          type = CliReal4
          ret = [0.0].pack("g")
        when CliAsciiz
          type = CliAsciiz
          ret = [1, ""].pack("NZ*")
        when :param
          type = CliAsciiz
          ret = "\0"
        end
      when String
        case hint || CliAsciiz
        when :param
          ret = [val].pack("Z*")
          hint = nil
        when CliAsciiz
          ret = [bytesize_or_length(val) + 1, val].pack("NZ*")
        when CliArrayOfInt1
          ret = [bytesize_or_length(val), val].pack("NA*")
        else
          raise "String for string-incompatible field"
        end
        type = hint || CliAsciiz
      when :auto_increment
        type = CliAutoincrement
        ret = ""
      end
      [type, ret]
    end

    def pack_types(schema, data)
      defs, vals  = "", ""
      data.each do |key, val|
        raise "#{key} is not found in #{schema.name}" unless schema[key]
        type, val = pack_type(val, schema[key].type)
        vals << val
        defs << [type, key.to_s].pack("cZ*")
      end
      [data.size, defs, vals]
    end

    def preprocess_query(statement, options)
      types, vals = "", ""
      statement = statement.gsub(/(:?):([a-zA-Z0-9_]+)/) do
        name = $2
        type, val = pack_type(options[name.to_sym], :param)
        types << [type].pack("c")
        vals << val
        [0, type].pack("cc")
      end
      statement << "\0" unless statement[-1, 1] == "\0"
      [statement, types, vals]
    end

    def extract_table_name(query)
      $1 if query =~ /\sfrom\s+(\w+)(?:\s|$)/i
    end

    def make_signed(i, bitnum)
      i > (1 << (bitnum - 1)) - 1 ? i - (1 << bitnum) : i
    end

    def unpack_row(schema, binary_string)
      pos = 0
      schema.raw_fields.inject({}) do |ret, field|
        name = field.name.to_sym

        type = binary_string.unpack("@#{pos}c")[0]
        unpack_type = case type
        when CliInt1   then "c"
        when CliInt2   then "n"
        when CliInt4   then "N"
        when CliInt8   then "N2"
        when CliReal4  then "g"
        when CliReal8  then "G"
        when CliBool   then "c"
        when CliAsciiz then "NZ*"
        when CliAutoincrement then "N"
        else
          raise "not supported field type #{type}"
        end
        val = binary_string.unpack("@#{pos + 1}#{unpack_type}")

        case type
        when CliInt1
          ret[name] = make_signed(val[0], 8)
          pos += 1
        when CliInt2
          ret[name] = make_signed(val[0], 16)
          pos += 2
        when CliInt4, CliAutoincrement
          ret[name] = make_signed(val[0], 32)
          pos += 4
        when CliReal4
          ret[name] = val[0]
          pos += 4
        when CliReal8
          ret[name] = val[0]
          pos += 8
        when CliInt8
          ret[name] = make_signed((val[0] << 32) + val[1], 64)
          pos += 8
        when CliBool
          ret[name] = val[0] == 0 ? false : true
          pos += 1
        when CliAsciiz
          ret[name] = val[1]
          pos += val[0] + 4
        end
        pos += 1

        ret
      end
    end

    def bytesize_or_length(str)
      str.respond_to?(:bytesize) ? str.bytesize : str.length
    end
  end
end