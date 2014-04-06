/**
* FDockHx
* written by Michel Romecki (contact@mromecki.fr, filt3r@free.fr)
* 
* Haxe 3 Compatible : flash/openFL/SWHX
*/

package ftb.app.fdockhx;

import flash.net.URLRequest;
import flash.net.URLLoader;
import flash.display.Loader;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.display.Bitmap;
import flash.display.Sprite;
import flash.Lib;

import ftb.app.fdockhx.Dock;

using StringTools;

typedef Shortcut = { 
	name	: String,	// text displayed on rolling over a picture
	path	: String,	// path to the application to launch
	icon	: String	// path to the picture to download and display
}

#if js @:expose #end
class FDock {
	public static var instance	(default, null)	: FDock;	// store the application instance
	
	#if ( !swhx && flash ) 
		static var _jsCnx	: haxe.remoting.ExternalConnection;
	#elseif swhx
		static var _swhxCnx	: swhx.Connection;
	#end
	
	var _scene				: Sprite;					// root display object
	var _dock				: Dock;						// dock’s instance
	var _loader				: Loader;
	var _config				: DockConfig;				// dock’s configuration object
	var _shortcuts			: Array<Shortcut>;			// array of shortcuts
	var _icons				: Array<DockIcon>;			// array of icons
	var _currentShortcut	: Shortcut;					// used by the image load queue
	
	public function new() {
		if ( instance != null )
			return;
			
		instance = this;
		
		// Initialize the scene
		_scene 					= flash.Lib.current;
		_scene.stage.align 		= flash.display.StageAlign.TOP_LEFT;
		_scene.stage.scaleMode 	= flash.display.StageScaleMode.NO_SCALE;
		
		// Initialize arrays and objects
		_config 	= cast {};
		_shortcuts 	= new Array();
		_icons 		= new Array();
	}
	
	public function run( urlConfig : String ) {
		// Loading of the config XML file
		var ul = new URLLoader();
		ul.addEventListener( Event.COMPLETE, cb_parseXml );
		ul.load( new URLRequest( urlConfig ) );
	}
		
	function cb_parseXml( e : Event ) {
		var ul : URLLoader = e.target;
		ul.removeEventListener( Event.COMPLETE, cb_parseXml );
				
		var xml = Xml.parse( ul.data ).firstChild();
		for ( i in xml.elements() )	{
			// Set the config object
			if ( i.nodeName == "config" ){
				_config.minSize		= Std.parseInt( i.get( "minSize" ) );
				_config.maxSize		= Std.parseInt( i.get( "maxSize" ) );
				_config.spread 		= Std.parseInt( i.get( "spread" ) );
				_config.delay 		= Std.parseInt( i.get( "delay" ) );
				_config.spacing 	= Std.parseInt( i.get( "spacing" ) );
				_config.fontSize 	= Std.parseInt( i.get( "fontSize" ) );
				_config.location 	= Reflect.field( DockLocation, i.get( "location" ) );
				_config.hidden 		= i.get( "hidden" ) == "true" ? true : false;
				_config.background	= switch( i.get( "background" ) ) {
					case 'none'	:
						0x00000000;
					default		:
						Std.parseInt(  i.get( "background" ).replace( '#', '0x' ) );
				}
				_config.border	= switch( i.get( "border" ) ) {
					case 'none'	:
						0x00000000;
					default		:
						Std.parseInt(  i.get( "border" ).replace( '#', '0x' ) );
				}
				_config.hidden 		= i.get( "hidden" ) == "true" ? true : false;
			}
			// Set shortcut's array
			if ( i.nodeName == "shortcuts" ){
				for ( j in i.elements() ) {
					if ( j.nodeName == "shortcut" )	{
						var sc : Shortcut = cast {};
						sc.name = j.get( "name" );
						sc.path = j.get( "path" );
						sc.icon = j.get( "icon" );
						_shortcuts.push( sc );
					}
				}
			}
		}
		// Start pictures' load queue
		loadIcons();
	}
	
	function loadIcons() {
		var loader = new Loader();
		loader.contentLoaderInfo.addEventListener( Event.COMPLETE, onLoadIcon );
		_currentShortcut = _shortcuts.pop();
		loader.load( new URLRequest( _currentShortcut.icon ) );
	}
		
	function onLoadIcon( e : Event ) {
		try{	 // neko ???
			e.target.removeEventListener( Event.COMPLETE, onLoadIcon );
		}catch( e : Dynamic ){}
		var loader 	= e.target.loader;
		
		var bmp : Bitmap = loader.content;
		// Center the picture on coordinates (0,0)
		bmp.x = - bmp.width * .5;
		bmp.y = - bmp.height * .5;
		
		// Much CPU consuming :(
		bmp.smoothing = true;
		
		var icon 	= new DockIcon();
		icon.label	= _currentShortcut.name;
		icon.path	= _currentShortcut.path;
		icon.addChild( bmp );
		
		// Proceed load queue or create the dock when finished loading all the pictures
		_icons.unshift( icon );
		if ( _shortcuts.length > 0 )
			loadIcons();
		else{
			// Create the _dock on the scene
			_dock = new Dock( _icons, _config, click );
			_dock.create( _scene );
		}
	}
	
	// System	
	function click( e : DockIcon ) {
		var path = e.path;
		#if js																			// JS redirection (Ajax or not)
			if ( path.startsWith( 'http://' ) )
				untyped __js__( "document.location.href=path" );
			else
				untyped __js__( "window.parent.SWFAddress.setValue( path )" );
		#elseif ( !swhx && flash ) 														// Flash redirection (Ajax or not)
			if ( path.startsWith( 'http://' ) )
				Lib.getURL( new URLRequest( e.path ) );
			else
				if( flash.external.ExternalInterface.available )
					_jsCnx.SWFAddress.setValue.call( [ e.path ] );
		#elseif swhx																	// SWHX call
			_swhxCnx.App.launch.call( [ path ] );
		#elseif ( sys || neko || cpp )													// Sys call
			try{
				new sys.io.Process( path, [] );
			}catch( e : Dynamic ) {}
		#end
	}
	
	public static function main() {
		// Entry Point
		instance 	= new FDock();
		var url 	= null;
		
		#if ( !swhx && flash )															// Flash without NME
			url		= Lib.current.loaderInfo.parameters.urlConfig;
			if( flash.external.ExternalInterface.available )
				_jsCnx	= haxe.remoting.ExternalConnection.jsConnect( "default" );	
		#elseif swhx																	// Flash using SWHX
			// SWHX Connection
			_swhxCnx = swhx.Connection.desktopConnect();
			_swhxCnx.App.onFlashInitialized.call( [] );
		#elseif ( sys || neko || cpp )													// NME
			var arg = Sys.args()[ 0 ];
			url = arg != null ? arg : "";
		#end
		instance.run( ( url != "" && url != null ) ? url : "fdockhx.xml" );
	}
}