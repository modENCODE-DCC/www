// Bag of tricks for modencode pages

var content = '';
var activeSection = '';
var header = true;

// Load and external library for cookies
document.write('<script type="text/javascript" src="/js/xCookie.js"></script>');

function getContents(section,page) {
    if (!section) {
	section = xGetCookie('currentSection') || 'Introduction';
    }

    var url  = '/cgi-bin/contents.pl';
    var pars = 'section='+section;
    if (page) pars += ';url='+page;

    var ajaxError = '\
    <h2>Uh oh,  there seems to be some kind of network problem or AJAX error\
    <br><br>Please contact the <a href="mailto:mckays@cshl.edu">webmaster</a>\
    and report the error code (if any) below:<br><br>';    

    var failure = section != 'Banner' ? function(t){ updateResult(ajaxError+t.statusText) } : null;

    var ajax  = new Ajax.Request( url,
				  { method:   'get',
				    asynchronous: false,
				    parameters:  pars,
				    onSuccess: function(t) { updateResult(t.responseText) },
				    onFailure: failure 
				  });
    ajax.section = section;

    setActiveLink(section);

    // a short-lived cookie to remember what section is open    
    if (section != 'Banner') xSetCookie('currentSection',section,null,null);
    
    // header toogles to false after one use
    header = false;
}

function updateResult(text) {
    var target = header ? 'Banner' : 'main';
    var main = document.getElementById(target);
    main.innerHTML = text;
}

function setActiveLink(section) {
    if (!section || section == 'Banner' || section == 'Introduction') return false;
    if (activeSection) {
      YAHOO.util.Dom.setStyle(activeSection,'color','blue');
      //YAHOO.util.Dom.setStyle(activeSection,'font-size','85%');
    }
    YAHOO.util.Dom.setStyle(section,'color','red');
    //YAHOO.util.Dom.setStyle(section,'font-size','90%');
    activeSection = section;
}

// Boilerplate
function printBanner () {
    document.write('<div id="Banner"></div>');
    getContents('Banner','common');
}


