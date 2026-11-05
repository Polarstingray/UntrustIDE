import javascript
import DataFlow::PathGraph

// Checks for dataflows that are potential (not guaranteed) vulnerabilities from
// the read of an environment variable to the transfer of data via a network connection

// Check for dataflow from an environment variable to a string that contains 'http://'
class HttpURL extends TaintTracking::Configuration{
  HttpURL() { this = "HttpURL" }

  // A node is a source if it reads an environment variable
  override predicate isSource(DataFlow::Node source) {
    source = DataFlow::globalVarRef("process").getAPropertyRead("env").getAPropertyRead()
  }

  // A node is a sink if it is a string (or a concatenation of a string) containing 'http://'
  override predicate isSink(DataFlow::Node sink){
    exists(StringLiteral str | str.getStringValue().matches("%http://%") | sink = str.flow())
    or exists(StringOps::Concatenation str | str.getAnOperand().getStringValue().matches("%http://%") | sink = str)
  }
}

// Check for dataflow from an environment variable to an HTTP network request.
// This could be harmful if a malicious piece of code tries to send a private piece of
// information (an environment variable) to an attacker over the network via an HTTP request.
class HttpRequest extends TaintTracking::Configuration{
  HttpRequest() { this = "HttpRequest" }

  // A node is a source if it reads an environment variable
  override predicate isSource(DataFlow::Node source) {
    source = DataFlow::globalVarRef("process").getAPropertyRead("env").getAPropertyRead()
  }

  // A node is a sink if it is a used as part of an HTTP request,
  // including the destination host, URL, or request path
  override predicate isSink(DataFlow::Node sink) {
    exists(ClientRequest r |
      sink = r.getHost()
      or sink = r.getUrl()
      or sink = r.getOptionArgument(0, "host") or sink = r.getOptionArgument(0, "hostname")
      or sink = r.getOptionArgument(0, "path") or sink = r.getOptionArgument(0, "pathname")
    )
  }
}

// Check for dataflow from an environment variable to an HTTP network response.
// This could be harmful if a malicious piece of code tries to send a private piece of
// information (an environment variable) to an attacker over the network via an HTTP response.
class HttpResponse extends TaintTracking::Configuration {
  HttpResponse() { this = "HttpResponse" }

  // A node is a source if it reads an environment variable
  override predicate isSource(DataFlow::Node source) {
    source = DataFlow::globalVarRef("process").getAPropertyRead("env").getAPropertyRead()
  }

    // A node is a sink if it is a used as part of an HTTP response,
    // including the body of the response body or the values stored
    // in objects passed to res.json() or res.send()
    override predicate isSink(DataFlow::Node sink) {
      exists(Http::ResponseBody body | sink = body)
      or exists(DataFlow::ObjectLiteralNode obj, DataFlow::PropWrite write, DataFlow::MethodCallNode call
        | write = obj.getAPropertyWrite() and sink = write.getRhs()
        and (call.getMethodName() = "json" or call.getMethodName() = "send")
        and call.getArgument(0) = obj)
  }
}

// Select results using the classes defined above
from
  HttpURL url,
  HttpRequest request,
  HttpResponse response,
  DataFlow::PathNode source,
  DataFlow::PathNode sink
where
  url.hasFlowPath(source, sink)
  or request.hasFlowPath(source, sink)
  or response.hasFlowPath(source, sink)
select
  source, sink, "dataflow from environment variable to network"

