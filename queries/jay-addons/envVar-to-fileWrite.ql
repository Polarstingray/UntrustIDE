import javascript
import DataFlow::PathGraph

// Check for dataflow from an environment variable to a file write.
// This could be harmful if a piece of code tries to send a private piece of
// information (an environment variable) to an attacker via a shared file.
class FileWrite extends TaintTracking::Configuration{
  FileWrite() { this = "FileWrite" }

    // A node is a source if it reads an environment variable
    override predicate isSource(DataFlow::Node source) {
        source = DataFlow::globalVarRef("process").getAPropertyRead("env").getAPropertyRead()
    }

    // A node is a sink if it is a used as part of a file write, including the data or path
    override predicate isSink(DataFlow::Node sink) { 
        exists(FileSystemWriteAccess write | sink = write.getADataNode() or sink = write.getAPathArgument()) 
    }
}

// Select results using the class defined above
from
  FileWrite write,
  DataFlow::PathNode source,
  DataFlow::PathNode sink
where
  write.hasFlowPath(source, sink)
select
  source, sink, "environment variable to file write"
