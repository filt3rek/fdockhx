/**
* FDockHx
* written by Michel Romecki (contact@mromecki.fr, filt3r@free.fr)
* 
* Haxe 3 Compatible : flash/openFL/SWHX
*/

package ftb.app.fdockhx;

import haxe.remoting.Context;

import sys.io.Process;

import neko.vm.Thread;

import systools.win.Tray;
import systools.win.Menus;
import systools.win.Events;
import systools.Display;
import systools.Dialogs;

import swhx.Application;
import swhx.Window;
import swhx.Flash;
import swhx.Connection;

class App {
	static var _iconTray	: Tray;		// Instance of the icon tray object (windows only)
	static var _window		: Window;	// Main _window's instance
	static var _swf			: Flash;	// Flash instance
	
	// Function called from client (Flash) to lauch an external application
	static function launch( path : String )	{
		command( path, [] );
	}
	
	static var _cmd		: String;
	static var _args	: Array<String>;
	static function command( cmd : String, args : Array<String>, keepPrompt = false ) {
		_args	= args;
		_args.unshift( cmd );
		if ( keepPrompt ) {
			_args.unshift( "/k" );
			_cmd	= "cmd";
		}else {
			_args.unshift( "/B" );
			_cmd	= "start";
		}
		
		Thread.create( _command );
	}
	static function _command() {
		Sys.command( _cmd, _args );	
	}
	
	static function createPopupMenu() {
		var menu = new Menus( true );
		menu.addItem( "Exit", 1 );
		_window.onRightClick = function() {
			switch( menu.showPopup( _window.handle ) )	{
				case 1	:	exit();
			}
			return false;
		}
	}
	
	static function createIconTray() {	
		// Sets the icon's tray picture
		_iconTray = new Tray( _window, "fdockhx.ico", "FDockHxSWHX" );
			
		var trayMenu = new Menus( true );
		trayMenu.addItem( "Exit", 1 );
		
		var trayHook = _window.addMessageHook( untyped Events.TRAYEVENT );
		trayHook.setNekoCallback( function () {
			if ( Std.string( trayHook.p2 ) == Std.string( Events.RBUTTONUP ) )	{
				switch( trayMenu.showPopup( _window.handle ) )	{
					case 1	:	exit();
				}
			}
			return 0;
		});
	}
	
	static function exit()	{	
		if( _iconTray != null ){
			_iconTray.dispose();
		}
		Application.exitLoop();
		//Application.cleanup();
	}
	
	static function onFlashInitialized() {
		var cnx = Connection.flashConnect( _swf );
		_window.show( true );
		createPopupMenu();
		createIconTray();
	}
	
	static function main()	{
		try	{
			Application.init();
			
			var screenSize 	= Display.getScreenSize();
			_window 		= new Window( "FDockHxSWHX", screenSize.w, screenSize.h, Window.WF_ALWAYS_ONTOP + Window.WF_TRANSPARENT + Window.WF_NO_TASKBAR );
						
			var context = new Context();
			context.addObject( "App", App );
			
			_swf = new Flash( _window, context );
			_swf.setAttribute( "src", "FDockHxSWHX.swf" );
			_swf.start();
			
			Application.loop();
			Application.exitLoop();
			//Application.cleanup();

		}catch ( e : String ) {
			Dialogs.message( "Error", e, true );
			exit();
		}
    }
}