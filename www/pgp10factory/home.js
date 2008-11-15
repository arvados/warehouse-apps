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

function fewerpipelines()
{
    for (var i=1;
	 i<999 && $('pipeline_cell_'+i);
	 i++)
	if ($('pipeline_cell_'+i).style.display == 'none') {
	    $('pipeline_cell_'+(i-1)).style.display = 'none';
	    break;
	}
    pipeline_layout_stash();
}

function morepipelines()
{
    for (var i=0;
	 i<999 && $('pipeline_cell_'+i);
	 i++)
	if ($('pipeline_cell_'+i).style.display == 'none') {
	    $('pipeline_cell_'+i).style.display = '';
	    break;
	}
    pipeline_layout_stash();
}

function pipeline_layout_stash()
{
    var layout = [];
    for (var i = 0;
	 i < 999 &&
	     $('pipeline_cell_'+i) &&
	     $('pipeline_cell_'+i).style.display != 'none';
	 i++)
	layout.push ({
		reads: $('selectedreads_'+i).value,
		genome: $('selectedgenome_'+i).value,
		position: i
		    });
    var newjson = layout.toJSON();
    if (newjson != $('layout_stash').value) {
	$('layout_stash').value = newjson;
	$('layout_save').innerHTML = 'Save this layout';
	$('layout_save').disabled = false;
	$('layout_link').update ('');
    }
}

function pipeline_layout_save()
{
    pipeline_layout_stash();
    new Ajax.Request('ajax-add-layout.cgi', {
	    parameters: { layout: $('layout_stash').value },
	    onSuccess: function(response) {
		$('layout_save').disabled = true;
		$('layout_link').innerHTML = '&nbsp; &nbsp; <a href=\"./home.cgi?'+response.responseText+'\">Link to this layout</a> &nbsp; - &nbsp; <a href=\"./download.cgi/'+response.responseText+'\">Download input+output tarball</a>';
	    }});
}

function pipeline_submit(position)
{
    $('selectedreads_'+position).value = $('selectreads_'+position).value;
    $('selectedgenome_'+position).value = $('selectgenome_'+position).value;
    pipeline_layout_stash();
    pipeline_request(position);
}

function pipeline_request(position)
{
    new Ajax.Request('ajax-add-pipeline.cgi', {
	    parameters: {
		reads: $('selectedreads_'+position).value,
		genome: $('selectedgenome_'+position).value,
		position: position
		    },
	    onSuccess: function(response) {
		var json = response.responseText.evalJSON();
		var position = response.request.parameters.position;
		$('pipeline_id_'+position).update (json.workflow.id);
		pipeline_update (response);
	    }
    });
    $('result_content_'+position).update();
    $('renderhash_'+position).value = '';
}

function pipeline_check(pe, position)
{
    if ($('pipeline_id_'+position).innerHTML) {
	    new Ajax.Request('post.cgi', {
		    parameters: {
			q: $('pipeline_id_'+position).innerHTML,
			position: position },
		    onSuccess: function(req) {
			pipeline_update (req);
		    }
	    });
    }
}

function pipeline_update(response)
{
    var json = response.responseText.evalJSON();
    var position = response.request.parameters.position;
    if (json && json.workflow.id) {
	$('pipeline_id_'+position).update (json.workflow.id);
	if (json.workflow.downloadall)
	    $('pipeline_id_'+position).insert ('<BR /><A href="download.cgi/'+json.workflow.downloadall+'.tar">download input+output tarball</A>');
	else
	    $('pipeline_id_'+position).insert ('<BR />&nbsp;');

	if (json.workflow.message)
	    $('pipeline_message_'+position).update (json.workflow.message);
	else
	    $('pipeline_message_'+position).update ();
	pipeline_render (position, json, sha1Hash(response.responseText));
    }
}

function enable_updatebutton(position)
{
    $('updatebutton_'+position).disabled=false;
}

function home_update(pe)
{
    for (var i=0; $('pipeline_id_'+i); i++)
	pipeline_check(pe, i);
    download_check(pe);
    if (!pe.save_buttons_showing)
	new Ajax.Request('ajax-mystuff.cgi', {
	    onSuccess: function(req) { $('mystuff').update(req.responseText); }
	});
}

function panel_showhide(id)
{
    var panels = Array ('download', 'manage', 'build');
    for (i=0; i<panels.length; i++) {
	$('panel_'+panels[i]).style.display = (panels[i] == id ? 'block' : 'none');
	$('tab_'+panels[i]).style.backgroundColor = (panels[i] == id ? '#fff' : '#ddd');
    }
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

function select_populate(position, withwhat)
{
    var widget = 'select'+withwhat+'_'+position;
    var stash = 'selected'+withwhat+'_'+position;
    if ($(widget).value != '')
	return;
    new Ajax.Request ('ajax-get.cgi', {
	    method: 'post',
	    parameters: { what: withwhat, widget: widget, stash: stash, as: 'select' },
	    onSuccess:
	    function(response)	{
		var widget = response.request.parameters.widget;
		var stash = response.request.parameters.stash;
		$(widget).innerHTML = response.responseText;
		$(widget).value = $(stash).value;
	    }
    });
}

function initialize_from_layout_stash()
{
    if (!$('layout_stash') || $('layout_stash').value == '')
	return false;
    var layout = $('layout_stash').value.evalJSON();
    for(var i=0;
	i < 999 &&
	    $('pipeline_id_'+i);
	i++) {
	if (i >= layout.length)
	    $('pipeline_cell_'+i).style.display = 'none';
	else {
	    if (layout[i].reads != '' && layout[i].genome != '') {
		$('selectedreads_'+i).value = layout[i].reads;
		$('selectedgenome_'+i).value = layout[i].genome;
		select_populate(i, 'reads');
		select_populate(i, 'genome');
		pipeline_request(i);
	    }
	    $('pipeline_cell_'+i).style.display = '';
	}
    }
    panel_showhide ('build');
    return true;
}

window.onload = function() {
    if (!initialize_from_layout_stash())
	if ($('panel_showhide'))
	    panel_showhide ($('panel_showhide').value);
    pe = new PeriodicalExecuter (home_update, 10);
    home_update(pe);
};
