let myImage = document.querySelector('img');

myImage.onclick = function() {
	let mySrc = myImage.getAttribute('src');
	if(mySrc === './images/LOGO-ver-04.png') {
		myImage.setAttribute('src', './images/LOGO-ver-03.png');
	} else {
		myImage.setAttribute('src', './images/LOGO-ver-04.png');
	}
}

// let myButton = document.querySelector('button');
// let myHeading = document.querySelector('h1');

// function setUserName() {
// 	let myName = prompt('Please enter your name: ');
// 	if(!myName) {
// 		setUserName();
// 	} else {
// 		localStorage.setItem('name', myName);
// 		myHeading.textContent = 'Welcome to the wild, ' + myName + '!';
// 	}
// }

// if(!localStorage.getItem('name')) {
// 	setUserName();
// } else {
// 	let storedName = localStorage.getItem('name');
// 	myHeading.textContent = 'Welcome to the wild, ' + storedName + '!';
// }

// myButton.onclick = setUserName;