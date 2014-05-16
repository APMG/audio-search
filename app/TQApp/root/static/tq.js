/* TQApp Javascript */

TQ = {};

"use strict";

TQ.setAlert = function(msg, where, type) {
    if (!$(where) || !$(where).length) {
        where = '#alerts';
    }
    if (!type) type = 'danger';
    
    var div = '<div class="alert alert-'+type+' alert-dismissable">';
    div += '<button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>';
    div += msg;
    div += '</div>';
    $(where).html(div);
}

TQ.getMedia = function(el, user) {
    // pull all the media for the user


}
