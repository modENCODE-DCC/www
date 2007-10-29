
if (isOldIE()) window.attachEvent("onload", correctPNG);

function setActiveLink(section) {
    /* currently disabled for IE until I can
       get access to windows */
    //    if (document.all && !window.opera) return false;
    var id = section + 'Link';
    YAHOO.util.Dom.setStyle(id,'color','red');
}

// Force IE5-6 to render transparent PNG images properly
// correctPNG taken from from http://homepage.ntlworld.com/bobosola/pngtestfixed.htm
function correctPNG() // correctly handle PNG transparency in Win IE 5.5 & 6.
{
    if (!isOldIE()) return false;
   var arVersion = navigator.appVersion.split("MSIE")
   var version = parseFloat(arVersion[1])
   if ((version >= 5.5) && (document.body.filters))
   {
      for(var i=0; i<document.images.length; i++)
      {
         var img = document.images[i]
         var imgName = img.src.toUpperCase()
         if (imgName.substring(imgName.length-3, imgName.length) == "PNG")
         {
            var imgID = (img.id) ? "id='" + img.id + "' " : ""
            var imgClass = (img.className) ? "class='" + img.className + "' " : ""
            var imgTitle = (img.title) ? "title='" + img.title + "' " : "title='" + img.alt + "' "
            var imgStyle = "display:inline-block;" + img.style.cssText
            if (img.align == "left") imgStyle = "float:left;" + imgStyle
            if (img.align == "right") imgStyle = "float:right;" + imgStyle
            if (img.parentElement.href) imgStyle = "cursor:hand;" + imgStyle
            var strNewHTML = "<span " + imgID + imgClass + imgTitle
            + " style=\"" + "width:" + img.width + "px; height:" + img.height + "px;" + imgStyle + ";"
            + "filter:progid:DXImageTransform.Microsoft.AlphaImageLoader"
            + "(src=\'" + img.src + "\', sizingMethod='scale');\"></span>"
            img.outerHTML = strNewHTML
            i = i-1
         }
      }
   }
}



// test for internet explorer
function isIE() {
    return document.all && !window.opera;
}


// test for internet explorer (but not IE7)
function isOldIE() {
    if (navigator.appVersion.indexOf("MSIE") == -1) return false;
    var temp=navigator.appVersion.split("MSIE");
    return parseFloat(temp[1]) < 7;
}

// automatically adjust iframe height to reflect contents
function iFrameHeight(id) {
    var iframe, height;
    if (isIE()) {
	iframe = document.frames[id];
	height = iframe.document.body.scrollHeight;
    }
    else {
	iframe = document.getElementById(id);
	height = iframe.contentDocument.body.scrollHeight;
    }

    height = typeof(height) == 'number' ? height + 50 : 400;
    YAHOO.util.Dom.setStyle(id,'height',height+'px');
}
