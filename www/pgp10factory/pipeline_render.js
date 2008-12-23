function pipeline_render(id, json, renderhash) {
    if(json.workflow && renderhash != $('renderhash_'+id).value) {
	$('renderhash_'+id).value = renderhash;
	$('result_content_'+id).update();
	for(i=0;i<json.workflow.pipeline.length;i++) {
	    var cur_line = json.workflow.pipeline[i];
	    $('result_content_'+id).insert({bottom: '<div id=\"pipeline_'+id+'_'+i+'\" class=\"pipeline\" style=\"text-align: center;\"><h2>'+cur_line.label+'</h2></div>'});

	    // Now check for jobs
	    if(cur_line.job.length > 0) {
		$('pipeline_'+id+'_'+i).insert({bottom: '<table id=\"pipelinejobs_'+id+'_'+i+'\" align=\"center\"></table>'});
		for(o=0;o<cur_line.job.length;o++) {
		    var cur_job = cur_line.job[o];
		    var image_tag = '';

		    // Set the image file
		    if(!cur_job.status) {
			image_tag = '';
		    } else {
			image_tag = '<img src=\"images/'+cur_job.status+'.gif\" width=\"20\" height=\"20\" />';
		    }

		    if(cur_job.id) var job_id = '&nbsp;&nbsp;'+cur_job.id;
		    else var job_id = '';
						
		    // Check for Output files
		    var output_files = '';
		    if(cur_job.outputfiles && cur_job.outputfiles.length > 0) {
			for(n=0;n<cur_job.outputfiles.length;n++) {
			    output_files += cur_job.outputfiles[n] + '<br />';
			}
		    }
						
		    $('pipelinejobs_'+id+'_'+i).insert({bottom: '<tr><td width=\"35\" align=\"left\" height=\"30\">'+image_tag+'</td><td align=\"left\">'+cur_job.label+'</td><td>'+job_id+'</td><td align=left style=\"padding-left: 4px;\">'+output_files+'</td></tr>'});
		}
	    }
	    if (cur_line.image)
		$('pipeline_'+id+'_'+i).insert({bottom: '<img style=\"border: 1px solid #000; margin-bottom: 5px; margin-top: 5px;\" src=\"cache/'+cur_line.image+'\" />'});
	    if (cur_line.html)
		$('pipeline_'+id+'_'+i).insert({bottom: cur_line.html});
	}
    }
}

function pipeline_retryjob(id)
{
    new Ajax.Request('ajax-retryjob.cgi', { parameters: { id: id } });
    $('retry-'+id).disabled = true;
}
