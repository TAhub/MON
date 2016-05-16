package game 
{
	import flash.net.SharedObject;
	
	public class Saver 
	{
		public static const SAVEPREFIX:String = "ryavis/mon/";
		private static var profileName:String;
		private static var profile:SharedObject;
		
		public static function openProfile(name:String):void
		{
			profileName = name;
			profile = SharedObject.getLocal(SAVEPREFIX + profileName + "/profile");
			if (!profile.data.valid)
			{
				//wipe everything
				trace("Wiping profile " + profileName);
				
				profile.data.contents = new Array();
			}
			profile.data.valid = false;
		}
		
		public static function get newProfileContents():Array
		{
			profile.data.contents = new Array();
			return profile.data.contents;
		}
		
		public static function get profileContents():Array
		{
			return profile.data.contents;
		}
		
		public static function closeProfile():void
		{
			profile.data.valid = true;
			profile.close();
			profile = null;
		}
	}

}