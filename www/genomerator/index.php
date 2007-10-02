<?php

$dsid = ereg_replace ("[^-_a-zA-Z0-9]", "", $_REQUEST["dsid"]);

?><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>Genomerator 1.0</title>
<meta name="language" content="en" />
<meta name="description" content="Personal Genome Project" />
<meta name="keywords" content="Personal Genome Project, PGP" />
<link href="style.css" rel="stylesheet" type="text/css" />

<script language="javascript" type="text/javascript">
little_box_w	= 7;
little_box_h	= 7;

num_boxes_w		= 50;
num_boxes_h		= 50;

no_move			= 0;
grid_data		= new Array();

function retrieve_index_of(test_array,value) {
	for(var o=0;o<test_array.length;o++) {
		if(test_array[o] == value) {
			return o;
		}
	}
	return false;
}


function retrieve_grid_location(frame_num) {

	// Retrieve the Index
	
	var index	= retrieve_index_of(grid_data,frame_num);
	
	// Get the base positions
	var	y	= 	(index > 0) ? Math.floor(index/num_boxes_w) : "0";
	var x	= 	(index > 0) ? index % num_boxes_w : "0";

	// Calculate the final positions
		x	=  little_box_w * x;
	y	= y * little_box_h;
	move_to_position(x,y);
}


function check_all_boxes(status) {
	var i=0;
	var id_field = document.download.checkbox;
	var id_options = id_field.length;
	
	for(i=0;i<id_options;i++) {
		id_field[i].checked = status;
	}
}

function load_frame_data() {
	var xml_tunnel	= window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Msxml2.XMLHTTP");
	xml_tunnel.open('GET','/framegrid.cgi?dsid=<?=$dsid?>;gridw=50;gridh=50',true);
	xml_tunnel.setRequestHeader("Content-Type", "application/x-www-form-urlencoded"); 
	xml_tunnel.onreadystatechange = function() {
		if(xml_tunnel.readyState == 4 && xml_tunnel.status == 200) {
			var incoming = xml_tunnel.responseText;
			grid_data	= incoming.split("\n");
		}
	}
	
	xml_tunnel.send(null);
}

function move_little_box(x,y) {
	var little_box	= document.getElementById("little_box");
	little_box.style.width	= Number(little_box_w) + "px";
	little_box.style.height	= Number(little_box_h) + "px";

	little_box.style.display	= "block";
	little_box.style.left		= Number(x)+"px";
	little_box.style.top		= Number(y)+"px";
}

function update_framelist(frame) {
	
}

function move_to_position(final_x,final_y) {
	if(!no_move || no_move != 1) {
		
		var wrapper	= document.getElementById("wrap");
		var grid	= document.getElementById("grid_image");
		var left	= document.getElementById("left");

			// Get the Frame Number
			var line_number = ((final_x+little_box_w)/little_box_w) + (((final_y)/little_box_h)*(grid.clientWidth/little_box_w));
			if(grid_data.length >= line_number) {
				line_data		= grid_data[(line_number-1)]
			} else {
				line_data		= "-1";
			}
			
			
			if(line_data != '-1') {
				var location_box = document.getElementById("location_box");
				var frame_number	=	document.getElementById("frame_number");
				frame_number.innerHTML	= line_data;
				location_box.innerHTML	= "Location: X:" + final_x + "px  Y:" + final_y + "px   -  Frame Number: " +line_data;
			
				move_little_box(final_x,final_y);
			}
	}
	no_move = 0;
}

function display_elements(e) {
	var x	= (e.x) ? e.x : e.layerX;
	var y	= (e.y) ? e.y : e.layerY+2;
	
	var wrapper	= document.getElementById("wrap");
	var grid	= document.getElementById("grid_image");
	var left	= document.getElementById("left");

	var offset_y	= Number(wrapper.offsetTop) + Number(left.offsetTop);
	var offset_x	= wrapper.offsetLeft + left.offsetLeft;
	
	y	= y - offset_y;

	if(y < 0) y=0;
	if(x >= grid.clientWidth) x = Number(grid.clientWidth)-Number(little_box_w);
	
	final_x	= Number(Math.round((x-(little_box_w/2))/little_box_w)*little_box_w);
	final_y	= Number(Math.round((y-(little_box_h/2))/little_box_h)*little_box_h);

	move_to_position(final_x,final_y);
}

function load_grid_image(location) {
	document.getElementById('grid_image').style.backgroundImage= "url('" +location+"')";
}

function squak_mouse_pos(event){
	var location_box = document.getElementById("location_box");
	location_box.innerHTML	= "Location: " + document.location.search;
} 

function flag_no_move() {
	no_move 	= 1;
}

function do_nothing() {}
</script>
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
	background-image: url('/framegrid.cgi?dsid=<?=$dsid?>;gridw=50;gridh=50;imagew=350;imageh=350;format=png');
}
</style>
</head>

<body onload="load_grid_image('/framegrid.cgi?dsid=<?=$dsid?>;gridw=50;gridh=50;imagew=350;imageh=350;format=png'); load_frame_data();">
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
    <td width="75"><input name="goto_frame" id="goto_frame" type="text" size="8" /></td>
    <td><img src="images/go.png" width="26" height="23" onClick="JavaScript: retrieve_grid_location(document.getElementById('goto_frame').value);" /></td>
  </tr>
</table></div>
    <h1> <span id="location_box">Location: </span>Frame <span id="frame_number">0</span> - example genome</h1>
		 <div id="leftbody">
		   <div id="menu">
          <p><strong>Click on an image to see below:</strong></p>
		  <form method="post" name="download" action="#">
          <table  width="260" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td class="blocks" width="30"><input type="checkbox" id="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">000</td>
              <td class="blocks" height="28"><img src="images/1block.png" width="33" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" id="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">998</td>
              <td class="blocks" height="28"><img src="images/1block.png" width="33" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" id="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">999</td>
              <td class="blocks" height="28"><img src="images/1block.png" width="33" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" id="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm1</td>
              <td class="blocks" height="28"><img src="images/4blocks4.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" id="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm2</td>
              <td class="blocks" height="28"><img src="images/4blocks3.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" id="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm3</td>
              <td class="blocks" height="28"><img src="images/4blocks4.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" id="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm4</td>
              <td class="blocks" height="28"><img src="images/4blocks2.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" id="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm4b</td>
              <td class="blocks" height="28"><img src="images/4blocks3.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" id="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm5</td>
              <td class="blocks" height="28"><img src="images/4blocks4.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm6</td>
              <td class="blocks" height="28"><img src="images/4blocks2.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm7</td>
              <td class="blocks" height="28"><img src="images/4blocks4.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm7b</td>
              <td class="blocks" height="28"><img src="images/4blocks3.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm8</td>
              <td class="blocks" height="28"><img src="images/4blocks4.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm9</td>
              <td class="blocks" height="28"><img src="images/4blocks2.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm9b</td>
              <td class="blocks" height="28"><img src="images/4blocks2.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm10</td>
              <td class="blocks" height="28"><img src="images/4blocks3.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm10</td>
              <td class="blocks" height="28"><img src="images/4blocks4.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm10</td>
              <td class="blocks" height="28"><img src="images/4blocks2.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm10</td>
              <td class="blocks" height="28"><img src="images/4blocks3.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm10</td>
              <td class="blocks" height="28"><img src="images/4blocks4.png" width="106" height="25" /></td>
            </tr>
			 <tr>
			   <td class="blocks" width="30"><input type="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm8</td>
              <td class="blocks" height="28"><img src="images/4blocks4.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm9</td>
              <td class="blocks" height="28"><img src="images/4blocks2.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm9b</td>
              <td class="blocks" height="28"><img src="images/4blocks2.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm10</td>
              <td class="blocks" height="28"><img src="images/4blocks3.png" width="106" height="25" /></td>
            </tr>
            <tr>
              <td class="blocks" width="30"><input type="checkbox" name="checkbox" value="checkbox" /></td>
              <td class="blocks" width="70" height="28">dm10</td>
              <td class="blocks" height="28"><img src="images/4blocks4.png" width="106" height="25" /></td>
            </tr>
          </table>
		  </form>
        </div>
	    </div>
         <div id="rightbody">
		   <p>Stuff You Can Do:</p>
		   
           <img src="images/select_all.png" alt="Select All" width="90" height="30" onclick="JavaScript: check_all_boxes(true);" /><br />
           <br />
         <img src="images/select_none.png" alt="Select None" width="90" height="30" onclick="JavaScript: check_all_boxes(false);"/><br />
         <br />
    <img src="images/download.png" alt="Dowload Selected" width="135" height="30" /></div>
      </div>
      <div id="footer">
      </div>
	  
</div>
</body>
</html>

