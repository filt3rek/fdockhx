
<!-- saved from url=(0068)https://raw.githubusercontent.com/filt3rek/fbuilder/master/README.md -->
<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"><style type="text/css"></style></head><body><pre style="word-wrap: break-word; white-space: pre-wrap;"># FBuilder

It's a light tool written in [Haxe](http://haxe.org) that uses [SWHX](http://haxe.org/com/libs/swhx) and that helps to work on multiple targets with several build scripts.

It displays buttons for the targets defined in your **xml** project file and when clicked, it runs the defined script, written in [hscript](https://code.google.com/p/hscript/).
	
![Screenshot 1](http://mromecki.fr/blog/post/58/screen1.jpg)
	
## Project xml file

A project file looks like that :
	
	&lt;!--&lt;fbuilder always-on-top="false" taskbar="true" stick-edge="50"&gt;--&gt;
	&lt;fbuilder&gt;
		&lt;target name="hss" color="#FFFF00"&gt;&lt;![CDATA[
			execute( "hss.exe", [ "-output", "www/css/", "src/hss/default.hss" ] );
		]]&gt;&lt;/target&gt;
		&lt;target name="templo" color="#00FF00"&gt;&lt;![CDATA[
			var err	= "";
			var out	= "";
			for( i in [ "login", "shell", "news", "media", "album", "picture", "live" ] ){
				var p	= new sys.io.Process( "temploc2.exe", [ i + ".mtt", "-cp", "src/mtt", "-output", "www/tpl", "-macros", "macro.mtt" ] );
				out	+= p.stdout.readAll().toString();
				err	+= p.stderr.readAll().toString();
			}
			{ out : out, err : err }
		]]&gt;&lt;/target&gt;
		&lt;target name="neko" color="#FF0000"&gt;&lt;![CDATA[
			execute( "haxe", [ "neko.hxml" ] );
		]]&gt;&lt;/target&gt;
		&lt;target name="js" color="#0000FF"&gt;&lt;![CDATA[
			execute( "haxe", [ "js.hxml" ] );
		]]&gt;&lt;/target&gt;
		&lt;target name="notepad" color="#FF00FF"&gt;&lt;![CDATA[
			command( "c:/Windows/notepad.exe", [] );
		]]&gt;&lt;/target&gt;
		&lt;target name="test" color="#FFFFFF"&gt;&lt;![CDATA[
			"The last line in the script is the console output ! :)";
		]]&gt;&lt;/target&gt;
		&lt;target name="test2" color="#999999"&gt;&lt;![CDATA[
			var rd	= sys.FileSystem.readDirectory( "." );
			var a	= [];
			for( i in rd ){
				if( StringTools.endsWith( i, ".log" ) ){
					sys.io.File.copy( i, "_old_" + i );
					a.push( i );
				}
			}
			a;
		]]&gt;&lt;/target&gt;
	&lt;/fbuilder&gt;
	
## Scripting

Inside the CData node, you write your **hscript** that will be executed once the button clicked.

These things are available in the **hscript context** :

 * StringTools
 * Sys
 * sys.FileSystem
 * sys.io.File
 * sys.io.Process
 
And 3 shortcut functions :

 * process( cmd : String, args : Array&lt;String&gt; ) : { out : String, err : String }
 * execute( cmd : String, args : Array&lt;String&gt; ) : { out : String, err : String }
 * command( cmd : String, args : Array&lt;String&gt;, keepPrompt = false ) : Void
 
The **process** and **execute** functions are the same. They run a background process and display stdout &amp; stderr.

The **command** function launches a program in a separated Thread with or without the prompt. It was not done for that at the begining but it can help anyway.

## How to use it

Yu must specify a project file as argument so the program must be called from command line like that :
	
	FBuilder project.fbxml

### Windows installation

Edit **install-file-extension.reg** and modify the location of the binary. Then Launch the **.reg** to register **.fbxml** as **FBuilder project file**. So you'll be able to **open** and **build** your **.fbxml** project from Windows' explorer.

## Building from sources

You'll need to modify a bit the SWHX, Systools and hscript libs to make it compiling right for Haxe 3.
</pre></body></html>