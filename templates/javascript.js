<script>

$(function() {
	
	if (document.getElementById("iconwebui")) {
		interval = window.setInterval(function(){ servicestatus(); }, 2000);
		servicestatus();
	}
	if (document.getElementById("debmaticinfo")) {
		debmaticinfo();
	}
	if (document.getElementById("hmport")) {
		getconfig();
	}

});

// SERVICE STATE

function servicestatus(update) {

	if (update) {
		$("#iconwebui").html("<img src='./images/unknown_20.png'>");
		$("#iconrfd").html("<img src='./images/unknown_20.png'>");
		$("#iconhmserver").html("<img src='./images/unknown_20.png'>");
		$("#iconmultimacd").html("<img src='./images/unknown_20.png'>");
		$("#iconregahss").html("<img src='./images/unknown_20.png'>");
		$("#iconcuxd").html("<img src='./images/unknown_20.png'>");
	}

	$.ajax( { 
			url:  'ajax.cgi',
			type: 'POST',
			data: { 
				action: 'servicestatus'
			}
		} )
	.fail(function( data ) {
		console.log( "Servicestatus Fail", data );
		$("#iconwebui").html("<img src='./images/unknown_20.png'>");
		$("#iconrfd").html("<img src='./images/unknown_20.png'>");
		$("#iconhmserver").html("<img src='./images/unknown_20.png'>");
		$("#iconmultimacd").html("<img src='./images/unknown_20.png'>");
		$("#iconregahss").html("<img src='./images/unknown_20.png'>");
		$("#iconcuxd").html("<img src='./images/unknown_20.png'>");
	})
	.done(function( data ) {
		console.log( "Servicestatus Success", data );
		if (data.status.lighttpd == "0") {
			$("#iconwebui").html("<img src='./images/check_20.png'>");
		} else {
			$("#iconwebui").html("<img src='./images/error_20.png'>");
		}
		if (data.status.rfd == "0") {
			$("#iconrfd").html("<img src='./images/check_20.png'>");
		} else {
			$("#iconrfd").html("<img src='./images/error_20.png'>");
		}
		if (data.status.hmserver == "0") {
			$("#iconhmserver").html("<img src='./images/check_20.png'>");
		} else {
			$("#iconhmserver").html("<img src='./images/error_20.png'>");
		}
		if (data.status.multimacd == "0") {
			$("#iconmultimacd").html("<img src='./images/check_20.png'>");
		} else {
			$("#iconmultimacd").html("<img src='./images/error_20.png'>");
		}
		if (data.status.regahss == "0") {
			$("#iconregahss").html("<img src='./images/check_20.png'>");
		} else {
			$("#iconregahss").html("<img src='./images/error_20.png'>");
		}
		if (data.status.cuxd == "0") {
			$("#iconcuxd").html("<img src='./images/check_20.png'>");
		} else {
			$("#iconcuxd").html("<img src='./images/error_20.png'>");
		}
	})
	.always(function( data ) {
		console.log( "Servicestatus Finished", data );
	});
}

// SERVICE RESTART

function servicerestart() {

	clearInterval(interval);
	$("#iconwebui").html("<img src='./images/unknown_20.png'>");
	$("#iconrfd").html("<img src='./images/unknown_20.png'>");
	$("#iconhmserver").html("<img src='./images/unknown_20.png'>");
	$("#iconmultimacd").html("<img src='./images/unknown_20.png'>");
	$("#iconregahss").html("<img src='./images/unknown_20.png'>");
	$("#iconcuxd").html("<img src='./images/unknown_20.png'>");
	$("#btnservicerestart").addClass("ui-state-disabled");
	$("#btnservicestop").addClass("ui-state-disabled");
	$.ajax( { 
			url:  'ajax.cgi',
			type: 'POST',
			data: { 
				action: 'servicerestart'
			}
		} )
	.fail(function( data ) {
		console.log( "Servicerestart Fail", data );
	})
	.done(function( data ) {
		console.log( "Servicerestart Success", data );
		servicestatus(1);
	})
	.always(function( data ) {
		console.log( "Servicerestart Finished", data );
		$("#btnservicerestart").removeClass("ui-state-disabled");
		$("#btnservicestop").removeClass("ui-state-disabled");
		interval = window.setInterval(function(){ servicestatus(); }, 2000);
	});
}

// SERVICE STOP

function servicestop() {

	clearInterval(interval);
	$("#iconwebui").html("<img src='./images/unknown_20.png'>");
	$("#iconrfd").html("<img src='./images/unknown_20.png'>");
	$("#iconhmserver").html("<img src='./images/unknown_20.png'>");
	$("#iconmultimacd").html("<img src='./images/unknown_20.png'>");
	$("#iconregahss").html("<img src='./images/unknown_20.png'>");
	$("#iconcuxd").html("<img src='./images/unknown_20.png'>");
	$("#btnservicerestart").addClass("ui-state-disabled");
	$("#btnservicestop").addClass("ui-state-disabled");
	$.ajax( { 
			url:  'ajax.cgi',
			type: 'POST',
			data: { 
				action: 'servicestop'
			}
		} )
	.fail(function( data ) {
		console.log( "Servicestop Fail", data );
	})
	.done(function( data ) {
		console.log( "Servicestop Success", data );
		servicestatus(1);
	})
	.always(function( data ) {
		console.log( "Servicestop Finished", data );
		$("#btnservicerestart").removeClass("ui-state-disabled");
		$("#btnservicestop").removeClass("ui-state-disabled");
		interval = window.setInterval(function(){ servicestatus(); }, 2000);
	});
}

// DEBMATIC INFO

function debmaticinfo() {

	$("#debmaticinfo").attr("style", "background:#dfdfdf").html("<TMPL_VAR "COMMON.HINT_UPDATING">");

	$.ajax( { 
			url:  'ajax.cgi',
			timeout: 9000, // sets timeout to 3 seconds
			type: 'POST',
			data: { 
				action: 'debmaticinfo'
			}
		} )
	.fail(function( data ) {
		console.log( "Debmaticinfo Fail", data );
		$("#debmaticinfo").attr("style", "background:#dfdfdf; color:red").html("<TMPL_VAR "COMMON.HINT_FAILED">");
	})
	.done(function( data ) {
		console.log( "Debmaticinfo Success", data );
		$("#debmaticinfo").attr("style", "color:black; text-align: left").html( "<pre>"+data.output+"</pre>");
	})
	.always(function( data ) {
		console.log( "Debmatic Finished", data );
	});
}


// GET CONFIG

function getconfig() {

	$("#btnssave").addClass("ui-state-disabled");
	// Ajax request
	$.ajax({ 
		url:  'ajax.cgi',
		type: 'POST',
		data: {
			action: 'getconfig'
		}
	})
	.fail(function( data ) {
		console.log( "getconfig Fail", data );
	})
	.done(function( data ) {
		console.log( "getconfig Success", data );

		// Settings
		$("#hmport").val(data.hmport);
		$("#nrport").val(data.nrport);
	})
	.always(function( data ) {
		console.log( "getconfig Finished" );
		$("#btnssave").removeClass("ui-state-disabled");
	})
}


// SAVE CONFIG

function saveconfig() {

	$("#btnssave").addClass("ui-state-disabled");
	$("#savinghint_settings").attr("style", "color:blue").html("<TMPL_VAR "COMMON.HINT_SAVING">");
	// Ajax request
	$.ajax({ 
		url:  'ajax.cgi',
		type: 'POST',
		data: {
			action: 'saveconfig',
			hmport: $("#hmport").val(),
			nrport: $("#nrport").val()
		}
	})
	.fail(function( data ) {
		console.log( "saveconfig Fail", data );
		$("#savinghint_settings").attr("style", "color:red").html("<TMPL_VAR "COMMON.HINT_SAVING_FAILED">" + " Error: " + jsonresp.error + " (Statuscode: " + data.status + ").");
	})
	.done(function( data ) {
		console.log( "saveconfig Success", data );
		$("#hmport").val(data.hmport);
		$("#nrport").val(data.nrport);
		$("#savinghint_settings").attr("style", "color:green").html("<TMPL_VAR "COMMON.HINT_SAVING_SUCCESS">" + ".");
	})
	.always(function( data ) {
		console.log( "saveconfig Finished" );
		$("#btnssave").removeClass("ui-state-disabled");
	})
}

</script>
