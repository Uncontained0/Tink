export enum TokenType {
	Class = "@class",
	Prop = "@prop",
	Method = "@method",
	Function = "@function",
	Type = "@type",
	Param = "@param",
	Return = "@return",
}

export class Token<T extends TokenType> {}

function noCarriageReturn(text: string) {
	return text.replaceAll("\r", "");
}

function getComments(text: string) {
	const comments = [];

	let inComment = false;
	let tabs = 0;

	for (const line of text.split("\n")) {
		if (inComment) {
			if (line.includes("]=]")) {
				inComment = false;
			} else {
				comments.push(line.slice(tabs));
			}
		}

		tabs = 0;
		while (line[tabs] === "\t") {
			tabs++;
		}

		if (line.includes("--[=[")) {
			tabs++;
			inComment = true;
		}

		if (line.trimStart().startsWith("--- ")) {
			comments.push(line.trimStart().slice(4));
		}
	}

	return comments;
}

export function tokenize(text: string) {
	const comments = getComments(noCarriageReturn(text));
}