var pe;

function request_update()
{
    if ($('requestid').value)
	new Ajax.Request('queue-download.cgi', {
		parameters: { q: $('requestid').value },
		    onSuccess: function(transport) {
		    json_response = transport.responseText.evalJSON();
		    process_response(json_response);
		}
	});
}

function download_button()
{
    new Ajax.Request('queue-download.cgi', {
	    parameters: { q: $('url').value },
	    onSuccess: function(transport) {
		json_response = transport.responseText.evalJSON();
		process_response(json_response);
	    }
    });
    pe = new PeriodicalExecuter(request_update, 2);
}

function addexisting_button()
{
    new Ajax.Request('add-to-session.cgi', {
	    parameters: { q: $('hash').value }
    });
}

function process_response(json_response) {
    if(json_response) {
	if(json_response.stop)
	    pe.stop();
	if(json_response.requestid) {
	    $('requestid').value = json_response.requestid;
	    if(json_response.message) {
		$('info_content').update(json_response.message);
		$('info_window').style.display = 'block';
		return;
	    }
	}
    }
    $('info_window').style.display = 'none';
}

window.onload = function() {
    new Ajax.PeriodicalUpdater('mystuff', 'ajax-mystuff.cgi', {
	    method: 'get', frequency: 5
	});
};
