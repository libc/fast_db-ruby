module FastDB
  module Constants
    CliHashed           = 1  # field should be indexed using hash table
    CliIndexed          = 2  # field should be indexed using B-Tree
    CliCascadeDelete    = 8  # perform cascade delete for reference or array of reference fields
    CliAutoincremented  = 16 # field is assigned automatically incremented value

    # Operation result codes
    CliOk                     = 0
    CliBadAddress             = 4294967295 # -1
    CliConnectionRefused      = 4294967294 # -2
    CliDatabaseNotFound       = 4294967293 # -3
    CliBadStatement           = 4294967292 # -4
    CliParameterNotFound      = 4294967291 # -5
    CliUnboundParameter       = 4294967290 # -6

    CliColumnNotFound         = 4294967289 # -7
    CliIncompatibleType       = 4294967288 # -8
    CliNetworkError           = 4294967287 # -9
    CliRuntimeError           = 4294967286 # -10
    CliClosedStatement        = 4294967285 # -11
    CliUnsupportedType        = 4294967284 # -12
    CliNotFound               = 4294967283 # -13
    CliNotUpdateMode          = 4294967282 # -14
    CliTableNotFound          = 4294967281 # -15
    CliNotAllColumnsSpecified = 4294967280 # -16
    CliNotFetched             = 4294967279 # -17
    CliAlreadyUpdated         = 4294967278 # -18
    CliTableAlreadyExists     = 4294967277 # -19
    CliNotImplemented         = 4294967276 # -20
    CliLoginFailed            = 4294967275 # -21
    CliEmptyParameter         = 4294967274 # -22
    CliClosedConnection       = 4294967273 # -23
    CliLastError              = CliClosedConnection


    class RecordNotFound < RuntimeError; end

    ERROR_DESCRIPTIONS = {
      CliBadAddress => "Bad address",
      CliConnectionRefused => "Connection refused",
      CliDatabaseNotFound => "Database not found",
      CliBadStatement => "Bad statement",
      CliParameterNotFound => "Parameter not found",
      CliUnboundParameter => "Unbound parameter",
      CliColumnNotFound => "Column not found",
      CliIncompatibleType => "Incomptaible type",
      CliNetworkError => "Network error",
      CliRuntimeError => "Runtime error",
      CliClosedStatement => "Closed statement",
      CliUnsupportedType => "Unsupported type",
      CliNotFound => [RecordNotFound, "Not found"],
      CliNotUpdateMode => "Not update mode",
      CliTableNotFound => "Table not found",
      CliNotAllColumnsSpecified => "Not all columns specified",
      CliNotFetched => "Not fetched",
      CliAlreadyUpdated => "Already updated",
      CliTableAlreadyExists => "Table already exists",
      CliNotImplemented => "Not implemented",
      CliLoginFailed => "Login failed",
      CliEmptyParameter => "Empty parameter",
      CliClosedConnection => "Closed connection"}

    # Command codes
    CliCmdCloseSession      = 0
    CliCmdPrepareAndExecute = 1
    CliCmdExecute           = 2
    CliCmdGetFirst          = 3
    CliCmdGetLast           = 4
    CliCmdGetNext           = 5
    CliCmdGetPrev           = 6
    CliCmdFreeStatement     = 7
    CliCmdAbort             = 8
    CliCmdCommit            = 9
    CliCmdUpdate            = 10
    CliCmdRemove            = 11
    CliCmdRemoveCurrent     = 12
    CliCmdInsert            = 13
    CliCmdPrepareAndInsert  = 14
    CliCmdDescribeTable     = 15
    CliCmdShowTables        = 16
    CliCmdPrecommit         = 17
    CliCmdSkip              = 18
    CliCmdCreateTable       = 19
    CliCmdDropTable         = 20
    CliCmdAlterIndex        = 21
    CliCmdFreeze            = 22
    CliCmdUnfreeze          = 23
    CliCmdSeek              = 24
    CliCmdAlterTable        = 25
    CliCmdLock              = 26


    # Field type codes
    CliOid            = 0
    CliBool           = 1
    CliInt1           = 2
    CliInt2           = 3
    CliInt4           = 4
    CliInt8           = 5
    CliReal4          = 6
    CliReal8          = 7
    CliDecimal        = 8
    CliAsciiz         = 9
    CliPasciiz        = 10
    CliCstring        = 11
    CliArrayOfOid     = 12
    CliArrayOfBool    = 13
    CliArrayOfInt1    = 14
    CliArrayOfInt2    = 15
    CliArrayOfInt4    = 16
    CliArrayOfInt8    = 17
    CliArrayOfReal4   = 18
    CliArrayOfReal8   = 19
    CliArrayOfDecimal = 20
    CliArrayOfString  = 21
    CliAny            = 22
    CliDatetime       = 23
    CliAutoincrement  = 24
    CliRectangle      = 25
    CliUndefined      = 26

  end
end