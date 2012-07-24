// ==UserScript==
// @name        linkazza
// @version     0.0.1
// @namespace   http://meh.paranoid.pk
// @description Turn plain text URLs into links.
// @updateURL   http
// @include     *
// ==/UserScript==

var exclude = [
  'a', 'head', 'noscript', 'option', 'script', 'style', 'title', 'textarea'
];

var xpath =
  './/text()[not(ancestor::' + exclude.join(') and not(ancestor::') + ')]';

var regexes = [
  /\b([a-z][-a-z9-9+.]+:\/\/|www\.)[^\s'"<>()]+/gi,
  /\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}\b/gi,
]

var observer = new (this.MutationObserver || this.MozMutationObserver || this.WebKitMutationObserver)(function (mutations) {
	mutations.forEach(function (mutation) {
		if (mutation.type == "childList") {
			for (var i = 0; i < mutation.addedNodes.length; i++) {
				linkazza(mutation.addedNodes[i]);
			}
		}
		else {
			linkazza(mutation.target);
		}
	});
});

observer.observe(document.body, { childList: true, characterData: true });
defer(linkazza, document.body);

function linkazza (node) {
  if (node.nodeType == Node.ELEMENT_NODE) {
    var i = 0;
    var result = document.evaluate(xpath, node, null,
      XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null);

    defer(interleave, function () {
      if (i >= result.snapshotLength) {
        return false;
      }

      linkazza(result.snapshotItem(i++));
    });

    return;
  }

  if (!node.textContent) {
    return;
  }

  var container;
  var text     = node.textContent;
  var position = 0;

  for (var i = 0, match; i < regexes.length; i++) {
    while (match = regexes[i].exec(text)) {
      container = container || document.createElement('span');
      container.appendChild(document.createTextNode(
        text.substring(position, match.index)));

      var link = match[0].replace(/\.*$/, '')
      var a    = document.createElement('a');

      a.className = 'linkazza';
      a.appendChild(document.createTextNode(link));

      if (link.indexOf(':/') < 0) {
        if (link.indexOf('@') > 0) {
          a.setAttribute('href', 'mailto:' + link);
        }
        else {
          a.setAttribute('href', 'http://' + link);
        }
      }
      else {
        a.setAttribute('href', link);
      }

      position = match.index + link.length;

      container.appendChild(a);
    }
  }

  if (container) {
    container.appendChild(document.createTextNode(text.substring(position, text.length)));

    while (container.firstChild) {
      node.parentNode.insertBefore(container.firstChild, node)
    }

    node.parentNode.removeChild(node);
  }
}

function interleave (func, times) {
  times = times || 50;

  for (var i = 0; i < times; i++) {
    if (func() === false) {
      return;
    }
  }

  defer(interleave, func, times);
}

function defer (func) {
  if (arguments.length > 1) {
    var rest = Array.prototype.slice.call(arguments, 1);

    setTimeout(function () {
      func.apply(null, rest);
    }, 0);
  }
  else {
    setTimeout(func, 0);
  }
}
