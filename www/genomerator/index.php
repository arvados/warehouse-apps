<?php

if (isset ($_SERVER["DSID"])) {
  $dsid = $_SERVER["DSID"];
}
else if (isset ($_ENV["DSID"]))
{
  $dsid = $_SERVER["DSID"];
}
else
{
  $dsid = ereg_replace ("[^-_a-zA-Z0-9]", "", $_REQUEST["dsid"]);
}

?><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>Genomerator 1.0</title>
<meta name="language" content="en" />
<meta name="description" content="Personal Genome Project" />
<meta name="keywords" content="Personal Genome Project, PGP" />
<link href="style.css" rel="stylesheet" type="text/css" />

<script language="javascript" type="text/javascript" src="genomerator.js"></script>
<style>
#location_box {
	float: right;
	clear: none;
	width: 200px;
	text-align: right;
	height: 20px;
	font-size: 10px;
	color: #CCC;
}

#little_box {
	border: 1px solid #5FACEF;
	background: #5FACEF;
	display: none;
	position: relative;
	font-size: 6px;
}

#grid_image {
	width: 350px;
	height: 350px;
	margin: 0px;
	padding: 0px;
	cursor:crosshair;
}

#footer {
	height: 200px;
}
</style>
</head>

<body onload="load_grid_image('/framegrid.cgi?dsid=<?=$dsid?>;gridw=50;gridh=50;imagew=350;imageh=350;format=png'); load_frame_data('<?=$dsid?>'); load_cycle_list('<?=$dsid?>');">
<div id="wrap">
    <div id="head"></div>
 <div id="left">
   <div id="grid_image" onmousedown="JavaScript: display_elements(event);">
	<span id="little_box" onmousedown="JavaScript: flag_no_move();"></span>
   </div>
  </div>
  <div id="right">
        <div id="goto">
		<table width="300" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td width="80">Go to Frame</td>
    <td width="75"><input name="goto_frame" id="goto_frame" type="text" size="8" onChange="JavaScript: retrieve_grid_location(document.getElementById('goto_frame').value);"/></td>
    <td><img src="images/go.png" width="26" height="23" onClick="JavaScript: retrieve_grid_location(document.getElementById('goto_frame').value);" /></td>
  </tr>
</table></div>
    <h1> <span id="location_box">Location: </span>Frame <span id="frame_number">1</span> from <?=$dsid?> images</h1>
		 <div id="leftbody">
		   <div id="menu">
          <p><strong>Click on an image to see below:</strong></p>
		  <form method="post" name="download" action="/downloadimages.cgi">
		  <input type="hidden" id="dsid" name="dsid" value="<?=$dsid?>" />
		  <input type="hidden" id="frame_id" name="frame_id" value="1" />
		  <div id="cycle_list">
		  </div>       
		  </form>
        </div>
	    </div>
         <div id="rightbody">
		   <p>Stuff You Can Do:</p>
		   
           <img src="images/select_all.png" alt="Select All" width="90" height="30" onclick="JavaScript: check_all_boxes(true);" /><br />
           <br />
         <img src="images/select_none.png" alt="Select None" width="90" height="30" onclick="JavaScript: check_all_boxes(false);"/><br />
         <br />
    <img src="images/download.png" alt="Dowload Selected" width="135" height="30" onclick="JavaScript: document.download.submit();" /></div>
      </div>
      <div id="footer">
      </div>
	  
</div>
</body>
</html>

