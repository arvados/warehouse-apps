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
	    $('selectpipelinetype_'+(i-1)).value = '';
	    select_selectors(i-1);
	    pipeline_request(i-1);
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
	{
	    layout.push ({
		    id: $('pipeline_id_'+i).innerHTML,
		    position: i
			});
	    var ptype = $('selectpipelinetype_'+i).value.split (":");
	    layout[i].pipelinetype = ptype[0];
	    for (var what=1; what<ptype.length; what+=2)
		layout[i][ptype[what]] = $('selected'+ptype[what]+'_'+i).value;
	}
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
		$('layout_link').innerHTML = '&nbsp; &nbsp; <a href=\"./?'+response.responseText+'\">Link to this layout</a> &nbsp; - &nbsp; <a href=\"./download.cgi/'+response.responseText+'\">Download input+output tarball</a>';
	    }});
}

function pipeline_submit(position)
{
    var ptype = $('selectpipelinetype_'+position).value.split (":");
    for (var what=1; what<ptype.length; what+=2)
	$('selected'+ptype[what]+'_'+position).value = $('select'+ptype[what]+'_'+position).value;
    pipeline_layout_stash();
    pipeline_request(position);
}

function pipeline_request(position)
{
    var ptype = $('selectpipelinetype_'+position).value.split (":");
    var parameters = { position: position, pipeline: $('selectpipelinetype_'+position).value };

    $('pipeline_id_'+position).update();
    $('result_content_'+position).update();
    $('renderhash_'+position).value = '';
    $('pipeline_download_'+position).update();
    $('pipeline_message_'+position).update();

    if (!ptype[0].length)
	return;

    for (var what=1; what<ptype.length; what+=2)
	if ($('selected'+ptype[what]+'_'+position).value)
	    parameters[ptype[what]] = $('selected'+ptype[what]+'_'+position).value;
    new Ajax.Request('ajax-add-pipeline.cgi', {
	    parameters: parameters,
	    onSuccess: function(response) {
		var json = response.responseText.evalJSON();
		var position = response.request.parameters.position;
		$('pipeline_id_'+position).update (json.workflow.id);
		pipeline_update (response);
	    }
    });
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
    var renderhash = sha1Hash (response.responseText);
    var json = response.responseText.evalJSON();
    var position = response.request.parameters.position;
    if (json && json.workflow.id) {
	$('pipeline_id_'+position).update (json.workflow.id);
	if (json.workflow.downloadall)
	    $('pipeline_download_'+position).update ('<BR /><A href="download.cgi/'+json.workflow.downloadall+'.tar">download input+output tarball</A>');
	else
	    $('pipeline_download_'+position).update ('<BR />&nbsp;');

	if (json.workflow.message)
	    $('pipeline_message_'+position).update (json.workflow.message);
	else
	    $('pipeline_message_'+position).update ();
	pipeline_render (position, json, renderhash);
    }
}

function enable_updatebutton(position)
{
    $('updatebutton_'+position).disabled=false;
}

function select_selectors(position)
{
    var ptype = $('selectpipelinetype_'+position).value.split (":");
    var selectors = '';
    for (var i=1; i<ptype.length; i+=2)
	{
	    selectors += '<select id="select'+ptype[i]+'_'+position+'" name="'+ptype[i]+'_'+position+'" size="1" onclick="select_populate('+position+', \''+ptype[i]+'\', \''+ptype[i+1]+'\');" onchange="enable_updatebutton('+position+');"><option value="">Select '+ptype[i]+'</option></select><br />';
	    selectors += '<input type="hidden" id="selected'+ptype[i]+'_'+position+'" name="selected'+ptype[i]+'_'+position+'" />';
	}
    $('selectors_'+position).update (selectors);
}

function home_update(pe)
{
    for (var i=0;
	 $('pipeline_id_'+i)
	     && $('pipeline_cell_'+i).style.display != 'none';
	 i++)
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

function select_populate(position, what, withwhat, defaultvalue)
{
    var widget = 'select'+what+'_'+position;
    var stash = 'selected'+what+'_'+position;
    if (!$(stash) || !$(widget))
	return;
    if (!$(stash).value && defaultvalue)
	$(stash).value = defaultvalue;
    if ($(widget).value)
	defaultvalue = $(widget).value;
    new Ajax.Request ('ajax-get.cgi', {
	    method: 'post',
	    parameters: { what: withwhat, widget: widget, as: 'select', value: defaultvalue },
	    onSuccess:
	    function(response)	{
		var widget = response.request.parameters.widget;
		$(widget).innerHTML = response.responseText;
		$(widget).value = response.request.parameters.value;
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
	    if (!layout[i].pipelinetype &&
		layout[i].pipelinetype != '' &&
		layout[i].reads != '' &&
		layout[i].genome != '') {
		layout[i].pipelinetype = 'maq';
	    }
	    var wanttype = '' + layout[i].pipelinetype + ':';
	    var ptype_string = undefined;
	    for (var oi=0;
		 !ptype_string
		     && oi < $('selectpipelinetype_'+i).options.length;
		 oi++)
		if ($('selectpipelinetype_'+i).options[oi].value.substr
		    (0, wanttype.length)
		    == wanttype)
		    ptype_string = $('selectpipelinetype_'+i).options[oi].value;
	    if (ptype_string) {
		$('selectpipelinetype_'+i).value = ptype_string;
		select_selectors (i);
		var ptype = ptype_string.split(':');
		for (var s=1; s<ptype.length; s+=2)
		    select_populate(i, ptype[s], ptype[s+1], layout[i][ptype[s]]);
		pipeline_request(i);
		$('pipeline_cell_'+i).style.display = '';
	    }
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
