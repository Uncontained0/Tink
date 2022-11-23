#!/user/bin/env node
import { tokenize } from "./tokenizer";
import { readFileSync } from "fs";
import path from "path";

// load testfile.lua
const text = readFileSync(path.join(__dirname, "../testfile.lua"), "utf8");

console.log(tokenize(text));