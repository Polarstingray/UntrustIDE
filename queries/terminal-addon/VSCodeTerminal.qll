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
