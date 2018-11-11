package crazyflie.web;

import js.Browser.document;
import js.Browser.navigator;
import js.Browser.window;
import js.Promise;
import js.USBDevice;
import js.html.ArrayBuffer;
import js.html.DataView;
import js.html.Element;
import js.html.DivElement;
import js.html.Gamepad;
import haxe.Timer;

class App {

	static var radio : Crazyradio;
	static var gamepad : Gamepad;
	static var logElement : Element;

	static function update() {

		var gamepads = navigator.getGamepads();
		if( gamepad == null ) {
			for( gp in gamepads ) {
				if( gp != null ) {
					gamepad = gp;
					break;
				}
			}
		}

		var pitch = 0.0;
		var roll = 0.0;
		var yaw = 0.0;
		var thrust = 0;

		if( gamepad != null ) {
			roll = gamepad.axes[2] * 30;
	    	pitch = gamepad.axes[3] * 30;
	    	yaw = gamepad.axes[0] * 200;
			thrust = Std.int( gamepad.axes[1] * - 55000 );
		}

		if( thrust < 500 ) thrust = 0;

		//info.textContent = ''+thrust;

		radio.sendSetpoint( roll, pitch, yaw, thrust );
	}

	static function rampMotors() {

		var roll = 0.0;
		var pitch = 0.0;
		var yaw = 0.0;
		var thrust = 20000;
		var thrust_mult = 1;
		var thrust_step = 500;

		radio.sendSetpoint( 0, 0, 0, 0 );

		var timer = new Timer( 30 );
		timer.run = function(){

			trace(thrust);
			radio.sendSetpoint( roll, pitch, yaw, thrust );
			if( thrust >= 25000 )
				thrust_mult = -1;
			thrust += thrust_step * thrust_mult;
			if( thrust < 20000 ) {
				trace( "end" );
				timer.stop();
				radio.sendSetpoint( 0, 0, 0, 0 );

				Timer.delay( function() {
					radio.close().then( function(e){
						trace("DONE");
					});
				}, 100 );
			}
		}
	}

	static function log( msg : String ) {
		var now = Date.now();
		var time = now.getHours()+':'+now.getMinutes()+':'+now.getSeconds();
		logElement.textContent += '[$time] '+msg+'\n';
	}

	static function main() {

		window.onload = function(){

			logElement = document.getElementById( 'log' );

			log( "Searching radio devices ..." );

			Crazyradio.findDevices().then( function(devices:Array<USBDevice>) {
				if( devices.length == 0 ) {
					//info.textContent = 'No crazyradio device found';
				} else {
					for( dev in devices ) {
						var btn = document.createButtonElement();
						btn.textContent = 'RADIO [${dev.serialNumber}]';
						document.body.appendChild( btn );
						btn.onclick = function(){
							radio = new Crazyradio( dev );
							radio.open().then( function(_){
								log( "Radio connected" );
								btn.classList.add( 'connected' );
								radio.scanChannel(80).then( function(_){
									trace(">");
									//rampMotors();
									var timer = new Timer( 30 );
									timer.run = update;
								});
								/*
								radio.setChannel(80).then( function(_){
									trace(">");
									//rampMotors();
								});
								*/
							});
						}
					}
				}
			} );
		}
	}
}
