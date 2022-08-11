let myImage = document.querySelector('img');

myImage.onclick = function() {
	let mySrc = myImage.getAttribute('src');
	if(mySrc === './images/LOGO-ver-04.png') {
		myImage.setAttribute('src', './images/LOGO-ver-03.png');
	} else {
		myImage.setAttribute('src', './images/LOGO-ver-04.png');
	}
}
