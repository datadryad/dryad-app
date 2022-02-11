<h1>Our Mission</h1>

<p>The Dryad Digital Repository is a curated resource that makes research data <strong>discoverable, freely reusable, and citable</strong>. Dryad provides a general-purpose home for a wide diversity of data types.</p>
<p>Dryad originated from an initiative among a group of leading journals and scientific societies to adopt a <a href="/docs/JointDataArchivingPolicy.pdf">joint data archiving policy (JDAP)</a> for their publications, and the recognition that <strong>open, easy-to-use, not-for-profit, community-governed data infrastructure</strong> was needed to support such a policy. These remain our guiding principles.</p>
<p>Dryad’s vision is to promote a world where research data is openly available, integrated with the scholarly literature, and routinely re-used to create knowledge.</p>
<p>Our mission is to provide the infrastructure for, and promote the re-use of, data underlying the scholarly literature.</p>

<h2>Key features</h2>
<ul>
<li>Flexible about data format, while encouraging the use and further development of research community standards.</li>
<li>Fits into the manuscript submission workflow of its partner journals, making data submission easy.</li>
<li>Assigns Digital Object Identifiers (DOIs) to data so that researchers can gain professional credit through data citation.</li>
<li>Promotes data visibility through usage and download metrics and by allowing content to be indexed, searched and retrieved.</li>
<li>Promotes data quality by employing professional curators to ensure the validity of the files and descriptive information.</li>
<li>Contents are free to download and re-use under a Creative Commons Zero (CC0) license.</li>
<li>Contents are preserved for the long term to guarantee access to contents indefinitely.</li>
<li>Open source, standards-compliant technology.</li>
</ul>



<h1>Shadow part styling for tabbed custom element</h1>

<template id="tabbed-custom-element">
<style type="text/css">
*, ::before, ::after {
box-sizing: border-box;
padding: 1rem;
}
:host {
display: flex;
}
</style>
<div part="tab active">Tab 1</div>
<div part="tab">Tab 2</div>
<div part="tab">Tab 3</div>
</template>

<tabbed-custom-element></tabbed-custom-element>


<h1>Word Count</h1>

<article contenteditable="">
  <p>1 2 3 4</p>
  <word-count></word-count>
</article>

<h1>TurboStream example </h1>

<div id="abc">
<p>This is sample text to be replaced.</p>
</div>

<turbo-stream action="update" target="abc">
<template>
   hello world
  </template>
</turbo-stream>

<%= javascript_pack_tag 'my_webcomponent_js' %>

<!-- ------------------------------------------------------------------ -->

<script type="text/javascript">

///document.addEventListener('WebComponentsReady', function () {
//  console.log("AAAAAAAAAAAAAAAA Loading config");
//  var comp = document.querySelector('cedar-embeddable-editor');
//  comp.loadConfigFromURL('assets/data/cee-config.json');
//  });

function configCedar() {
  console.log("Loading CEDAR config");
  var comp = document.querySelector('cedar-embeddable-editor');
  comp.loadConfigFromURL('/cedar-embeddable-editor/cee-config.json');
  }

// Wait a second to ensure the page is loaded before initializing the Cedar config
// (we should base this one some better trigger in the future)
setTimeout(configCedar,1000);
</script>

<h1>Test for CEDAR</h1>

 <cedar-embeddable-editor></cedar-embeddable-editor>

<!-- Even though the JavaScript file for CEDAR is fully versioned, webpack -->
<!-- ignores portions of the name after the first dot, so we only include the -->
<!-- major version. -->
<%= javascript_pack_tag 'cedar-embeddable-editor-2' %>


