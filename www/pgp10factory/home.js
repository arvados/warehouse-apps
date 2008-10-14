var pe;

function download_check(pe)
{
    if ($('requestid').value)
	new Ajax.Request('ajax-add-url.cgi', {
		parameters: { q: $('requestid').value },
		    onSuccess: function(req) {
		    json = req.responseText.evalJSON();
		    download_update(json);
		}
	});
}

function download_button()
{
    new Ajax.Request('ajax-add-url.cgi', {
	    parameters: { q: $('url').value },
	    onSuccess: function(req) {
		json = req.responseText.evalJSON();
		download_update(json);
	    }
    });
}

function addexisting_button()
{
    new Ajax.Request('ajax-add-hash.cgi', {
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

function pipeline_submit()
{
    new Ajax.Request('ajax-add-pipeline.cgi', {
	    parameters: {
		reads: $('selectreads').value,
		genome: $('selectgenome').value
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
    if (!pe.save_buttons_showing)
	new Ajax.Request('ajax-mystuff.cgi', {
	    onSuccess: function(req) { $('mystuff').update(req.responseText); }
	});
}

function panel_showhide(id)
{
    var panels = Array ('download', 'manage', 'build');
    for (i=0; i<panels.length; i++)
	$('panel_'+panels[i]).style.display = (panels[i] == id ? 'block' : 'none');
    $('panel_showhide').value = id;
    return false;
}

function showsavebutton(datahash)
{
    $('save-'+datahash).innerHTML = 'Save';
    $('save-'+datahash).disabled = false;
    $('save-'+datahash).style.display = 'inline';
    if (!pe.save_buttons_showing)
	pe.save_buttons_showing = 0;
    ++pe.save_buttons_showing;
}

function hidesavebutton(save_pe)
{
    var datahash = save_pe.datahash;
    save_pe.stop();
    if ($('save-'+datahash).disabled == true) {
	$('save-'+datahash).style.display = 'none';
	--pe.save_buttons_showing;
    }
}

function comment_save(datahash)
{
    new Ajax.Request ('ajax-save-comment.cgi', {
	    method: 'post',
	    parameters: { datahash: datahash, comment: $(datahash).value },
	    onSuccess:
	    function(response)	{
		var datahash = response.request.parameters.datahash;
		if (response.responseText == $(datahash).value) {
		    $('save-'+datahash).disabled = true;
		    $('save-'+datahash).innerHTML = 'Saved';
		    var save_pe = new PeriodicalExecuter (hidesavebutton, 3);
		    save_pe.datahash = datahash;
		} else {
		    $('save-'+datahash).disabled = false;
		    $('save-'+datahash).innerHTML = 'Save';
		}
	    }
    });
}

function select_populate(id, withwhat)
{
    if ($(id).value != '')
	return;
    new Ajax.Request ('ajax-get.cgi', {
	    method: 'post',
	    parameters: { what: withwhat, id: id, as: 'select' },
	    onSuccess:
	    function(response)	{
		var id = response.request.parameters.id;
		$(id).innerHTML = response.responseText;
	    }
    });
}

window.onload = function() {
    if ($('panel_showhide'))
	panel_showhide ($('panel_showhide').value);
    pe = new PeriodicalExecuter (home_update, 5);
    home_update(pe);
};
