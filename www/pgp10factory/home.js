var pe;

function download_check(pe)
{
    if ($('requestid').value)
	new Ajax.Request('queue-download.cgi', {
		parameters: { q: $('requestid').value },
		    onSuccess: function(req) {
		    json = req.responseText.evalJSON();
		    download_update(json);
		}
	});
}

function download_button()
{
    new Ajax.Request('queue-download.cgi', {
	    parameters: { q: $('url').value },
	    onSuccess: function(req) {
		json = req.responseText.evalJSON();
		download_update(json);
	    }
    });
}

function addexisting_button()
{
    new Ajax.Request('add-to-session.cgi', {
	    parameters: { q: $('hash').value }
    });
}

function download_update(json) {
    if(json) {
	if(json.stop)
	    $('requestid').value = false;
	if(json.requestid) {
	    $('requestid').value = json.requestid;
	    if(json.message) {
		$('info_content').update(json.message);
		$('info_window').style.display = 'block';
		return;
	    }
	}
    }
    $('info_window').style.display = 'none';
}

function choosereads(hash)
{
    $('wantreads').value = hash;
}

function choosegenome(hash)
{
    $('wantgenome').value = hash;
}

function pipeline_submit()
{
    new Ajax.Request('add-to-pipelines.cgi', {
	    parameters: {
		reads: $('wantreads').value,
		genome: $('wantgenome').value
		    },
	    onSuccess: function(req) {
		json = req.responseText.evalJSON();
		pe.pipeline_id = json.id;
		pipeline_check (pe);
	    }
    });
    $('result_content').update();
}

function pipeline_check(pe)
{
    if (pe.pipeline_id) {
	new Ajax.Request('post.cgi', {
		parameters: { q: pe.pipeline_id },
		    onSuccess: function(req) {
		    pipeline_update (req);
		}
	});
    }
}

function pipeline_update(req)
{
    var json = req.responseText.evalJSON();
    if (json && json.workflow.id) {
	$('pipeline_id').update ('Pipeline id:<br>'+json.workflow.id);
	if (json.workflow.message)
	    $('pipeline_message').update (json.workflow.message);
	pipeline_render (json);
    }
}

function home_update(pe)
{
    pipeline_check(pe);
    download_check(pe);
    new Ajax.Request('ajax-mystuff.cgi', {
	    onSuccess: function(req) { $('mystuff').update(req.responseText); }
    });
}

window.onload = function() {
    pe = new PeriodicalExecuter (home_update, 5);
    home_update(pe);
};
