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
