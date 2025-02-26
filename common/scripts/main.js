/*
	@file:   common/scripts/main.js
	@brief:  the main script for the website
	@details:
	- currently this script implements a theme switcher button, together with the `common/styles/style.css`
	@author: madpang
	@date:
	- created on 2024-08-25
	- updated on 2024-08-25
*/

document.addEventListener(
	"DOMContentLoaded",
	function() {
		console.log("DOM fully loaded and parsed");
		let sw_theme = document.getElementById("switch-theme-button");
		if (sw_theme) {
			// Add event listener to the theme switch button
			console.log("Theme switch button found!");
			sw_theme.addEventListener(
				"click",
				function() {
					console.log("Theme switch button clicked!");
					document.body.classList.toggle("dark-theme");
					if (document.body.classList.contains('dark-theme')) {
						localStorage.setItem('theme', 'dark');
					} else{
						localStorage.setItem('theme', 'light');
					}
				}
			);
			// Apply the theme from local storage if it exists
			let theme = localStorage.getItem('theme');
			if (theme === 'dark') {
				console.log("Applying saved theme:", theme);
				document.body.classList.add('dark-theme');
			}
		} else {
			console.log("Theme switch button not found!");
		}
	}
);
