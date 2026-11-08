place this folder in queries

# untrusted data to vscode integrated terminal

- the function terminal.sendText() allows extensions to run shell commands in vs code integrated terminals. it does so without using child_process so the UntrustedIDE shell command sink misses it
    
- A malicious repository could ship a .vscode/settings.json and set myExt.buildCommand to a malicious shell command. the victim's extension may blindly read the setting and send it to an integrated terminal. opening the repo silently executes the malicious command.
    

&nbsp;

# sink definition

./queries/terminal-addon/VSCodeTerminal.qll

```js
import javascript

// text sent to a VS code terminal
// terminal.sendText(x) runs x as shell command
// obtain a terminal with:
// vscode.window.createTerminal
// vscode.window.activeTerminal
// vscode.window.terminals

class TerminalSendTextSink extends DataFlow::Node {
  TerminalSendTextSink() {
    exists(API::Node window, API::Node terminal |
      window = API::moduleImport("vscode").getMember("window") and
      (
        terminal = window.getMember("createTerminal").getReturn() or
        terminal = window.getMember("activeTerminal") or
        terminal = window.getMember("terminals").getAMember()
      ) and
      this = terminal.getMember("sendText").getParameter(0).asSink()
    )
  }
}
```

- requires 'vscode', obtains a terminal through one of the terminal obtaining methods, and runs sendText() on the terminal
- API::moduleImport is for creating an API graph that follows an object across variables and function returns
- .qll files can be reused with `import VSCodeTerminal`

* * *

&nbsp;

&nbsp;

# untrusted-to-terminal.ql

**./queries/terminal-addon/untrusted-to-terminal.ql:**

### header

```js
/**
 * @name untrusted data to VS Code terminal
 * @description data form workspace file, network res, 
 *              web request, or workspace settings reaching the terminal.sendText() 
 *              and running as shell command
 * @kind path-problem
 * @problem.severity error
 * @id js/untrustide/untrusted-to-terminal
 */
```

read by codeql (copy and pasted from ./queries/source-and-sink/file-read.ql)

- **@kind** path-problem gives us the entire path from source to sink
    - vs code shows a clickable list of the steps the taken
- @id is an identifier for codeql to produce SARIF (file type) output
- the rest are display text

&nbsp;

### imports

```js
import javascript
import DataFlow::PathGraph
import VSCodeTerminal
```

- javascript: entire CodeQL js library
- DataFlow::PathGraph: for "path-problem" queries. provides source - sink steps
- VSCodeTerminal: the VSCodeTerminal.qll above
    - technically, you can just combine the 2 files into one

&nbsp;

### predicate

```js
// if source is untrusted input, and kind is where its from
predicate untrustedSource(DataFlow::Node source, string kind) {
  // UntrustedIDE sources
  exists(FileSystemReadAccess r | source = r.getADataNode()) and kind = "file read" or
  exists(ClientRequest r | source = r.getAResponseDataNode()) and kind = "network response" or
  exists(Http::RouteHandler rh | source = rh.getARequestNode()) and kind = "web server request" or

  // vscode.workspace.getConfiguration(...).get(...)  
  // a workspace's .vscode/settings.json is attacker-controlled
  source =
    API::moduleImport("vscode").getMember("workspace")
        .getMember("getConfiguration").getReturn()
      	.getMember("get").getReturn()
      	.asSource() and
  kind = "workspace setting"
}
```

- a predicate defines the set of all source, kind pairs that make the body true.
    - basically what counts as untrusted input
- file read: anything read from the filesystem
- network response: data coming back from a client request
- web server request: some extensions run local servers/listeners
- and workspace settings, mentioned at the top

&nbsp;

### configuration

```js
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
```

- isSource any node from the unstrustedSource
- isSink anny node that is a TerminalSendTextSink (in VSCodeTerminal.qll)

### query

```sql
from UntrustedToTerminal cfg, DataFlow::PathNode source, DataFlow::PathNode sink, string kind
where
  cfg.hasFlowPath(source, sink) and
  untrustedSource(source.getNode(), kind)
select sink.getNode(), source, sink, "Terminal command depends on a $@.", source.getNode(), kind
```

- find every tainted flow path from source to sink
- kind describes the type of problem for the reporting message
- sink.getNode() is the alert location, source/sink are the endpoints for the graph in the result

* * *

&nbsp;  
&nbsp;

# audit query for finding where sendText was called

```sql
/**
 * @name vs code terminal sendText
 * @description lists every value sent to a vs Code integrated terminal
 * @kind problem
 * @problem.severity recommendation
 * @id js/untrustide/terminal-sendtext
 */

import javascript
import VSCodeTerminal

from TerminalSendTextSink sink
select sink, "text sent to VS Code terminal"
```

- sendText is generally a non issue, this helps you look at where its called and what its being called for.
- an extension may use sendText to install dependencies or it may run a malicious script. this is how you determine what its being used for easily.

* * *
&nbsp;
&nbsp;

# run on sample database (linux terminal)

should work fine through vs code, codeql extension (right clicking the file and running on ) like it shows in the quick start guide

```bash
mv ./terminal-addon /path/to/UntrustIDE/queries/ # move queries to query folder


# I got it on my mac with
brew install codeql
codeql version # test

# but vscode installs codeql cli for me automatically, you can find its binary file with this
# skip this if you did it with brew
find ~ -path '*github.vscode-codeql*' -name codeql -type f
alias codeql=/path/to/codeql
codeql version

# run query
codeql query run queries/terminal-addon/untrusted-to-terminal.ql -d sample-data/jebbs.plantuml-2.17.4 -o /tmp/term.bqrs
# -d /path/to/db
# -o /path/to/output

# you can also create database for testing or using on extensions not provided
codeql database create ./test/terminal-test-db --language=javascript --source-root ./queries/terminal-addon/test --overwrite

# decode the output file
codeql bqrs decode /tmp/term.bqrs --format=text --result-set='#select'
```
***

&nbsp;
# fake extension for testing

### ./queries/terminal-addon/test/terminal-test.js

```js
// test cases for untrusted-to-terminal.ql

const vscode = require("vscode");
const fs = require("fs");
const https = require("https");
const express = require("express");

// should trigger

// workspace file is read and sent to the terminal
function fileRead() {
  const script = fs.readFileSync(".vscode/build.sh", "utf8");
  const term = vscode.window.createTerminal("build");
  term.sendText("bash -c " + script);
}

// workspace settings is controlled by the extension
function setting() {
  const cfg = vscode.workspace.getConfiguration("myext");
  const compiler = cfg.get("compilerPath");
  vscode.window.activeTerminal.sendText(compiler + " main.c");
}

// network response to the terminal
class Runner {
  constructor() {
    this.term = vscode.window.createTerminal("runner");
  }
  run(cmd) {
    this.term.sendText(cmd);
  }
}

function network() {
  const runner = new Runner();
  https.get("https://example.com/", (res) => {
    res.on("data", (chunk) => runner.run(chunk.toString()));
  });
}

// webserver  request to the terminal
function webServer() {
  const app = express();
  app.get("/run", (req, res) => {
    vscode.window.terminals[0].sendText(req.query.cmd);
    res.send("ok");
  });
}


// shouldn't trigger

// constant command npm install
function constant() {
  vscode.window.createTerminal("x").sendText("npm install");
}


// untrusted ls is fine if the contents aren't read
function unused() {
  const data = fs.readFileSync("notes.txt", "utf8");
  console.log(data.length);
  vscode.window.activeTerminal.sendText("ls");
}


// sendtext on non vscode terminal
function notTerminal() {
  const fake = {
    sendText(t) {} 
  };
  fake.sendText(fs.readFileSync("x.txt", "utf8"));
}
```