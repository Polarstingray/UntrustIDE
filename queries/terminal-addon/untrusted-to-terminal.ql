/**
 * @name untrusted data to VS Code terminal
 * @description data form workspace file, network res, 
 *              web request, or workspace settings reaching the terminal.sendText() 
 *              and running as shell command
 * @kind path-problem
 * @problem.severity error
 * @id js/untrustide/untrusted-to-terminal
 */

import javascript
import DataFlow::PathGraph
import VSCodeTerminal

// source is untrusted input, and kind is where its from
predicate untrustedSource(DataFlow::Node source, string kind) {
  // untrusted sources
  exists(FileSystemReadAccess r | source = r.getADataNode()) and kind = "file read" or
  exists(ClientRequest r | source = r.getAResponseDataNode()) and kind = "network response" or
  exists(Http::RouteHandler rh | source = rh.getARequestNode()) and kind = "web server request" or

  // workspace file .vscode/settings.json is controlled by the extension
  source =
    API::moduleImport("vscode")
        .getMember("workspace")
        .getMember("getConfiguration")
        .getReturn()
        .getMember("get")
        .getReturn()
        .asSource() and
  kind = "workspace setting"
}

// configuration
class UntrustedToTerminal extends TaintTracking::Configuration {
  UntrustedToTerminal() {
    this = "UntrustedToTerminal"
  }

  override predicate isSource(DataFlow::Node source) { 
    untrustedSource(source, _) 
  }
  
  override predicate isSink(DataFlow::Node sink) { 
    sink instanceof TerminalSendTextSink 
  }
}

// query
from UntrustedToTerminal cfg, DataFlow::PathNode source, DataFlow::PathNode sink, string kind
where
  cfg.hasFlowPath(source, sink) and
  untrustedSource(source.getNode(), kind)
select sink.getNode(), source, sink, "Terminal command depends on a $@.", source.getNode(), kind
