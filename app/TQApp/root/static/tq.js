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

TQ.STATUS = {
    C : 'Complete',
    A : 'In Process'
};

TQ.getMedia = function(el, user) {
    if (!user) user = TQ.User;

    // pull all the media for the user
    var mediaUri = TQ.APIBase + '/user/' + user.guid + '/media/?tq=' + user.key;
    $.getJSON(mediaUri, function(resp) {
        //console.log(resp); 
        var media = '<table class="table table-striped">';
        $.each(resp, function(idx, m) {
            console.log(m);
            var n    = m.name ? m.name : m.uuid;
            var link = '<a href="#" data-uuid="'+m.uuid+'" onclick="TQ.showMedia($(this))">'+n+'</a>';
            var d    = m.updated_at;
            var stat = TQ.STATUS[m.status];
            var row = '<tr><td>'+link+'</td><td>'+stat+'</td><td>'+d+'</td></tr>';
            media += row;
        });
        media += '</table>';
        el.html(media);
    });

}

TQ.createMedia = function(btn, el, user) {
    if (!user) user = TQ.User;
    var uri = $('[name="uri"]').val();
    var mediaUri = TQ.APIBase + '/user/' + user.guid + '/media';
    var payload = { uri : uri };

    // prevent multi-clicks
    btn.attr('disabled', true);
    btn.addClass('disabled');

    $.ajax({
        type: 'POST',
        url: mediaUri,
        data: JSON.stringify(payload),
        processData: false,
        contentType: 'application/json',
        dataType: 'json',
        success: function(jqXHR) {
            TQ.setAlert('Success! Your media has been queued and you will receive email with details.', null, 'info');
            btn.attr('disabled', false);
            btn.removeClass('disabled');
            $('[name="uri"]').val(''); // clear
            TQ.getMedia(el, user); // update list
            return;
        },
        error: function(jqXHR) {
            TQ.setAlert('Uh-oh. There was a problem queuing your media. Try again later.');
            console.log(jqXHR);
            btn.attr('disabled', false);
            btn.removeClass('disabled');
            return;
        }
    });

}
