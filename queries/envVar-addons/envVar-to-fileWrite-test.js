
// environment variable written as file content
function FileWrite_Test_FileContent() {
    // source
    const key = process.env.API_KEY;

    // sink
    const fs = require("fs");
    fs.writeFileSync("output.txt", key);
}

// environment variable used as the file path
function FileWrite_Test_Path1() {
    // source
    const filename = process.env.FILE_NAME;

    // sink
    const fs = require("fs");
    fs.writeFileSync(filename, "test data");
}

function FileWrite_Test_Path2() {
    // source
    const path = process.env.PATH;
    const filename = "example.txt";

    // sink
    const fs = require("fs");
    fs.writeFileSync(path + filename, "test data");
}
