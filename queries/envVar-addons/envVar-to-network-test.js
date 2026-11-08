
function HttpURL_Test() {
    // source
    const key = process.env.API_KEY;

    // sink
    const http = require("http");
    const req = http.request(
        "http://example.com/?key=" + key,
        { method: "GET" });
    req.end();
}

// ----------------

function HttpRequest_Test_Host() {
    // source
    const host = process.env.API_HOST;

    // sink
    const http = require("http");
    const req = http.request({
        hostname: host,
        path: "/",
        method: "GET"
    });
    req.end();
}

function HttpRequest_Test_URL() {
    // source
    const url = process.env.API_URL;

    // sink
    const http = require("http");
    const req = http.request(url, { method: "GET" });
    req.end();
}

function HttpRequest_Test_Path() {
    // source
    const key = process.env.API_KEY;

    // sink
    const http = require("http");
    const req = http.request({
        hostname: "example.com",
        path: "/?key=" + key,
        method: "GET"
    });
    req.end();
}

function HttpRequest_Test_Get() {
    // source
    const key = process.env.API_KEY;

    // sink
    const http = require("http");
    http.get("http://example.com/?url=" + key);
}

// ----------------

function HttpResponse_Test_Send() {
    // source
    const key = process.env.API_KEY;

    // sink
    const express = require("express");
    const app = express();
    app.get("/", (req, res) => {
        res.send(key);
    });
}

function HttpResponse_Test_Json() {
    // source
    const key = process.env.API_KEY;

    // sink
    const express = require("express");
    const app = express();
    app.get("/json", (req, res) => {
        res.json({ apiKey: key });
    });
}
