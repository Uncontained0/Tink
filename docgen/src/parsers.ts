import { Token } from "./tokenizer";

class Cursor {
	comments: Token<any>[];
	index: number;

	constructor(comments: Token<any>[]) {
		this.comments = comments;
		this.index = 0;
	}

	next() {
		this.index++;
	}

	peek() {
		return this.comments[this.index];
	}
}

export function parse(comments: Token<any>[]) {
	
}