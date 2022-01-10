
console.log("hello from webcomponent js6");

class WordCount extends HTMLElement {
    constructor() {
	super();

	const parent = this.parentNode;
	console.log(parent);
	
	const shadow = this.attachShadow({ mode: "open" });
	const text = document.createElement('span');
	text.textContent = `Word Count: ${this.countWords(parent)}`;
	shadow.appendChild(text);

	setInterval(() => {
	    text.textContent = `Word Count: ${this.countWords(parent)}`;
	}, 200);
    }

    countWords(node) {
	const text = node.innerText || node.textContnt;
	return text.split(/\s+/g).length; 
    }
};

const StreamActions = {
    update(element) {
	const target = document.getElementById(element.target);
	console.log(target);
	target.innerHTML = "";
	target.append(element.template.content);
    }
};

class StreamElement extends HTMLElement {
    constructor () {
	super();
	console.log("starting stream");
	console.log(this.action);
	console.log(this.target);
	console.log(this.template);
	StreamActions[this.action](this);
	this.remove();
    }

    get action() {
	return this.getAttribute("action");
    }

    get target() {
	return this.getAttribute("target");
    }
    
    get template() {
	return this.firstElementChild;
    }
};

customElements.define("word-count", WordCount);
customElements.define("turbo-stream", StreamElement);

let template = document.getElementById("tabbed-custom-element");

globalThis.customElements.define(template.id, class extends HTMLElement {
    constructor() {
	super();
	console.log("found template id " + template.id);
	this.attachShadow({ mode: "open" });
	this.shadowRoot.appendChild(template.content);

	let tabs = [];
	let children = this.shadowRoot.children;

	for(let elem of children) {
	    if(elem.getAttribute('part')) {
		tabs.push(elem);
	    }
	}

	tabs.forEach((tab) => {
	    tab.addEventListener('click', (e) => {
		tabs.forEach((tab) => {
		    tab.part = 'tab';
		})
		e.target.part = 'tab active';
	    })

	    console.log(tab.part);
	})
    }
});


