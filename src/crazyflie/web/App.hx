package crazyflie.web;

import haxe.Timer;
import js.Browser.console;
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
import crazyflie.Test;

class App {

	static var radio : Crazyradio;
	static var gamepad : Gamepad;
	static var flightControl : FlightControl;

	static var logElement : Element;
	static var thrustElement : Element;
	static var yawElement : Element;
	static var pitchElement : Element;
	static var rollElement : Element;

	static function update() {

		var gamepads = navigator.getGamepads();
		if( gamepad == null ) {
			for( gp in gamepads ) {
				if( gp != null ) {
					gamepad = gp;
					log( 'Gamepad connected [${gamepad.id}]' );
					break;
				}
			}
		}

		var pitch = 0.0;
		var roll = 0.0;
		var yaw = 0.0;
		var thrust = 0;

		if( gamepad != null ) {
			thrust = Std.int( gamepad.axes[1] * - 55000 );
			yaw = gamepad.axes[0] * 200;
			pitch = gamepad.axes[3] * 30;
			roll = gamepad.axes[2] * 30;
		}

		if( thrust < 500 ) thrust = 0;

		//thrust = Math.min( thrust, flightControl.maxThrust );
		yaw = Math.min( yaw, flightControl.maxYaw );

		//log( roll+' '+pitch+' '+yaw+' '+thrust );

		thrustElement.textContent = 'Thrust: $thrust';
		yawElement.textContent = 'Yaw: $yaw';
		pitchElement.textContent = 'Pitch: $pitch';
		rollElement.textContent = 'Roll: $roll';

		if( radio != null ) {
			radio.sendSetpoint( roll, pitch, yaw, thrust );
		}
	}

	static function log( msg : String ) {
		console.log( msg );
		var time = DateTools.format( Date.now(), "%H:%M:%S" );
		logElement.textContent += '[$time] '+msg+'\n';
		logElement.scrollTop = logElement.scrollHeight;
	}

	static function main() {

		window.onload = function() {

			flightControl = new FlightControl();

			logElement = document.getElementById( 'log' );

			var inputElement = document.getElementById( 'input' );
			thrustElement = inputElement.querySelector( '.thrust' );
			yawElement = inputElement.querySelector( '.yaw' );
			pitchElement = inputElement.querySelector( '.pitch' );
			rollElement = inputElement.querySelector( '.roll' );

			var timer = new Timer( 30 );
			timer.run = update;

			log( "Searching radio devices …" );

			Crazyradio.findDevices().then( function(devices:Array<USBDevice>) {
				if( devices.length == 0 ) {
					log( 'No crazyradio device found' );
				} else {
					for( dev in devices ) {
						var btn = document.createButtonElement();
						btn.textContent = 'RADIO [${dev.serialNumber}]';
						document.getElementById( 'devices' ).appendChild( btn );
						btn.onclick = function(){
							radio = new Crazyradio( dev );
							radio.open().then( function(_){
								log( "Radio connected" );
								btn.classList.add( 'connected' );
								btn.onclick = function(){
									radio.close();
									btn.classList.remove( 'connected' );
								}
								radio.scanChannel(80).then( function(_){
									trace(">");
									//rampMotors();
									//var timer = new Timer( 30 );
									//timer.run = update;
								});
							});
						}
					}
				}
			} );
		}
	}
}
