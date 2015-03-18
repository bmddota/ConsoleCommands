package {
	import flash.display.MovieClip;

	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.net.LocalConnection;
	
	public class ConsoleCommands extends MovieClip{
		
		//these three variables are required by the engine
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		public var socket:Socket;
		public var socketReady:Boolean = false;
		public var socketInit:Boolean = false;
		public var count:uint = 0;
		
		public var curObj:Object = null;
		
		
		//constructor, you usually will use onLoaded() instead
		public function ConsoleCommands() : void {
			trace("[ConsoleCommands] ConsoleCommands UI Constructed!");
			//socket= new Socket();

			//socket.connect("127.0.0.1", 29000);
			//socket.addEventListener(Event.CONNECT, socketConnect);
		}
		
		//this function is called when the UI is loaded
		public function onLoaded() : void {
			this.gameAPI.SubscribeToGameEvent("console_command", this.onConsoleCommand);
		}
		
		public function socketConnect(e:Event){
			trace("CONNECTED");
			socketReady = true;
			socket.removeEventListener(Event.CONNECT, socketConnect);
			
			var pID:int = this.globals.Players.GetLocalPlayer();
			var isPlayer:Boolean = (pID >= 0 && pID <= 9)
			
			trace(pID);
			trace(isPlayer);
			
			var id = curObj.pid;
			if (id == -1 || pID == id || (id == -2 && isPlayer) || (id == -3 && !isPlayer)){
				trace("WRITING");
				writeToConsole(curObj.command);
			}
		}
		
		public function onConsoleCommand(obj:Object){
			trace("[ConsoleCommands] ConsoleCommand received: " + obj.pid + " -- " + obj.command);
			
			curObj = obj;
			if (!socketInit){
				socketInit = true;
				socket= new Socket();

				socket.connect("127.0.0.1", 29000);
				socket.addEventListener(Event.CONNECT, socketConnect);
				return;
			}
			
			var pID:int = this.globals.Players.GetLocalPlayer();
			var isPlayer:Boolean = (pID >= 0 && pID <= 9)
			
			trace(pID);
			trace(isPlayer);
			
			var id = obj.pid;
			if (id == -1 || pID == id || (id == -2 && isPlayer) || (id == -3 && !isPlayer)){
				trace("WRITING");
				writeToConsole(obj.command);
			}
		}
		
		public function writeToConsole(command:String){
			var dataRead:Function = (function(command:String, socket:Socket) {
				return function(e:Event){
					var ba:ByteArray = new ByteArray();
					socket.readBytes(ba, 0, ba.bytesAvailable);
					count += ba.length;
				};
			})(command, socket);
			
			if (!socketReady){
				trace("Socket Not Ready.  Not executing the command.");
				return;
			}

			var ba:ByteArray = new ByteArray();
			var len:uint = command.length + 13;
			
			ba.writeUTFBytes("CMND");
			ba.writeUnsignedInt(0x00d20000);
			ba.writeShort(len);
			ba.writeShort(0x0000);
			ba.writeUTFBytes(command);
			ba.writeByte(0x00);

			socket.writeBytes(ba, 0, ba.length);
			socket.flush();
			trace("WRITTEN");
		}
		
		public function onResize(re:ResizeManager) : * {
			
		}
	}
}