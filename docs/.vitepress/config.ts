import { defineConfig } from "vitepress";

export default defineConfig({
	title: "Tink",
	themeConfig: {
		nav: [
			{
				text: "Version",
				items: [
					{ text: "0.1.x", link: "/0.1/" },
				]
			}
		],

		sidebar: {
			"/0.1/": [
				{
					text: "Guide",
					items: [
						{ text: "What is Tink?", link: "/0.1/guide/what-is-tink" },
						{ text: "Getting Started", link: "/0.1/guide/getting-started" },
						{ text: "Singletons", link: "/0.1/guide/singletons" },
						{ text: "Bindings", link: "/0.1/guide/bindings" },
						{ text: "The Network", link: "/0.1/guide/network" },
					],
				},
				{
					text: "API",
					items: [
						{ text: "Tink", link: "/0.1/api/tink" },
					],
				},
			],
		},

		socialLinks: [
			{ icon: "github", link: "https://github.com/Uncontained0/Tink" },
		],

		outline: 'deep',
	}
});