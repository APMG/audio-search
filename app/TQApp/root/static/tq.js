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

TQ.SPINNER = null;

TQ.getMedia = function(el, user, pg) {
    if (!user) user = TQ.User;
    if (!pg)   pg   = 1;

    // cache the contents of the 'loading' img/message the first time
    if (!TQ.SPINNER) {
        TQ.SPINNER = $('#media .panel-body').html();
    }

    // pull all the media for the user
    var mediaUri =  TQ.APIBase+'/media/search/';
        mediaUri += '?cxc-minimal=1&cxc-order=updated_at+DESC&cxc-page_size=10&cxc-page='+pg;
    $.getJSON(mediaUri, function(resp) {
        //console.log(resp); 
        var media = '<table class="table table-striped">';
            media += '<tr><th>Name</th><th>URI</th><th>Status</th><th>Last Modified</th></tr>';
        $.each(resp.results, function(idx, m) {
            //console.log(m);
            var n    = m.name ? m.name : m.uuid;
            var link = '<a href="#" data-uuid="'+m.uuid+'" onclick="TQ.showMedia($(this))">'+n+'</a>';
            var d    = m.updated_at;
            var stat = TQ.STATUS[m.status];
            var row = '<tr><td class="tq-uuid">'+link+'</td><td class="tq-uri">'+m.uri+'</td><td>'+stat+'</td><td>'+d+'</td></tr>';
            media += row;
        });
        media += '</table>';

        el.html(media);
        TQ.makeMediaPager(el, user, resp);  // call after .html() because it appends

        // reload again in 30 seconds
        /*
        TQ.MEDIA_RELOADER = setTimeout( function() { 
            //el.html(TQ.SPINNER);
            TQ.getMedia(el,user);
        }, 30000);
        */
    });

}

TQ.makeMediaPager = function(parentEl, user, resp) {

// http://getbootstrap.com/components/#pagination
    console.log(resp);
    var pgSize = parseInt(resp.query.limit);
    var pager = '<div id="media-pager"></div>';
    parentEl.append(pager);
    $('#media-pager').wPaginate({
        spread: 4,
        total: parseInt(resp.count),
        limit: pgSize,
        index: parseInt(resp.query.offset),
        prev: null,
        next: null,
        //first: null,
        //last: null,
        url: function(idx) {
            var newPg = idx+1;
            //clearTimeout(TQ.MEDIA_RELOADER); // reset reloader
            parentEl.html(TQ.SPINNER);
            TQ.getMedia(parentEl, user, newPg);
        },  
        ajax: true
    });
}

TQ.createMedia = function(btn, el, user) {
    if (!user) user = TQ.User;
    var uri = $('[name="uri"]').val();
    var mname = $('[name="name"]').val();
    var mediaUri = TQ.APIBase + '/user/' + user.guid + '/media';
    var payload = { uri : uri, name: mname };
    var alerts = $('#create-media-alerts');

    if (!uri) {
        TQ.setAlert("URI value is required", alerts);
        return;
    }

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
            TQ.setAlert('Success! Your media has been queued and you will receive email with details.', alerts, 'info');
            btn.attr('disabled', false);
            btn.removeClass('disabled');
            $('[name="uri"]').val(''); // clear
            $('[name="name"]').val(''); // clear
            TQ.getMedia(el, user); // update list
            return;
        },
        error: function(jqXHR) {
            TQ.setAlert('Uh-oh. There was a problem queuing your media. Try again later.', alerts);
            console.log(jqXHR);
            btn.attr('disabled', false);
            btn.removeClass('disabled');
            return;
        }
    });

}

TQ.showMedia = function(link, user) {
    var uuid = link.data('uuid');
    if (!user) user = TQ.User;
    //console.log('uuid=', uuid);

    // set title
    $('#mediaModal').html(uuid);

    // set progress
    var modal = $('#media-modal');
    $('#media-modal-body').html(TQ.SPINNER);

    // details link
    $('#media-modal .media-details-link').attr('href', TQ.UriBase + 'media/' + uuid);

    // preview player
    var playerUri = TQ.UriBase + 'media/player/' + uuid;
    var player = $('#media-modal .modal-footer iframe');

    // fetch details
    var uri = TQ.APIBase + '/media/' + uuid + '/keywords'; 
    $.getJSON(uri, function(resp) {
        //console.log(resp);
        var details = '<h4>Keywords</h4> <ul class="tq-keywords"><li>' + resp.keywords.slice(0,10).join("</li><li>") + '</li></ul>';
        $('#media-modal-body').html(details);

        // activate the player only if the media is http: accessible
        if (resp && resp.uri && resp.uri.match(/^https?:/)) {
            player.attr('src', playerUri);
            player.show();
        }
        else {
            player.hide();
        }
    });    

    // show modal
    modal.modal({ });

}

