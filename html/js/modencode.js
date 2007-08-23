function setActiveLink(section) {
    /* currently disabled for IE until I can
       get access to windows */
    if (document.all && !window.opera) return false;
    var id = section + 'Link';
    YAHOO.util.Dom.setStyle(id,'color','red');
}