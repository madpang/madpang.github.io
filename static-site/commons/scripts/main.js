/*
	@file:   pd-wysheid/common/scripts/main.js
	@brief:  the main script for the website
	@details:
	- currently this script implements a theme switcher button, together with the `common/styles/style.css`
	@author: madpang
	@date: [created: 2024-08-25, updated: 2026-01-03]
*/

document.addEventListener("DOMContentLoaded", function () {
	console.log("DOM fully loaded and parsed");

	/* =========================
		Theme switch
		========================= */

	const swTheme = document.getElementById("btn-toggle-theme");
	if (swTheme) {
		console.log("Theme switch button found!");

		swTheme.addEventListener("click", function () {
			document.body.classList.toggle("pd-dark-theme");

			const theme = document.body.classList.contains("pd-dark-theme") ? "dark" : "light";

			localStorage.setItem("theme", theme);
			console.log("Theme set to:", theme);
		});

		// restore theme
		const savedTheme = localStorage.getItem("theme");
		if (savedTheme === "dark") {
			console.log("Applying saved theme:", savedTheme);
			document.body.classList.add("pd-dark-theme");
		}
	} else {
		console.log("Theme switch button not found!");
	}

	/* =========================
		Button-based navigation
		========================= */

	document.addEventListener("click", function (e) {
		navigateFromButtonEvent(e);
	});
});

function navigateFromButtonEvent(e) {
	const btn = e.target.closest("button[data-href]");
	if (!btn) return false;

	const href = btn.dataset.href;
	if (!href) return false;

	// optional: ignore modified clicks (future-proof)
	if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return false;

	window.location.href = href;
	return true;
}
