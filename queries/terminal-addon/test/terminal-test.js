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
