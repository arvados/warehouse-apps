function showsavebutton(datahash)
{
    $('save-'+datahash).innerHTML = 'Save';
    $('save-'+datahash).disabled = false;
    $('save-'+datahash).style.display = 'inline';
}
function hidesavebutton(pe)
{
    var datahash = pe.datahash;
    pe.stop();
    if ($('save-'+datahash).disabled == true) {
	$('save-'+datahash).style.display = 'none';
    }
}
function do_save(datahash)
{
    new Ajax.Request ('admin-save.cgi', {
	    method: 'post',
	    parameters: { datahash: datahash, comment: $(datahash).value },
	    onSuccess:
	    function(response)	{
		var datahash = response.request.parameters.datahash;
		if (response.responseText == $(datahash).value) {
		    $('save-'+datahash).disabled = true;
		    $('save-'+datahash).innerHTML = 'Saved';
		    var pe = new PeriodicalExecuter (hidesavebutton, 3);
		    pe.datahash = datahash;
		} else {
		    $('save-'+datahash).disabled = false;
		    $('save-'+datahash).innerHTML = 'Save';
		}
	    }
    });
}

