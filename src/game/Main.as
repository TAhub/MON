package game 
{
	import flash.geom.Rectangle;
	import net.flashpunk.Engine;
	import net.flashpunk.FP;
	
	public class Main extends Engine
	{
		public static const data:Database = new Database();
		private static const TYPECOLORVARIATION:Number = 0.1;
		private static const TYPECOLORCHANGERATE:Number = 1.5;
		private static const TYPECOLORCHANGERATEVARIATION:Number = 0.6;
		private var variations:Array;
		
		private var map:Map;
		
		public function Main() 
		{
			super(800, 600);
			
			loadMap(null);
			
			//type color variations
			variations = new Array();
			for (var i:uint = 0; i < 3; i++)
			{
				variations.push(1);
				variations.push(TYPECOLORCHANGERATE);
			}
		}
		
		public function loadMap(pl:Walker, difficulty:uint = 1):void
		{
			map = new Map(pl, difficulty);
			FP.world = map;
		}
		
		public function returnToMap(partyAddition:Creature = null):void
		{
			FP.world = map;
			if (partyAddition)
				map.addPartyMember(partyAddition);
		}
		
		public function variateColor(c:uint):uint
		{
			var r:uint = FP.getRed(c);
			var g:uint = FP.getGreen(c);
			var b:uint = FP.getBlue(c);
			r *= variations[0];
			g *= variations[2];
			b *= variations[4];
			if (r > 255)
				r = 255;
			if (g > 255)
				g = 255;
			if (b > 255)
				b = 255;
			return FP.getColorRGB(r, g, b);
		}
		
		public override function update():void
		{
			//update type color variations
			for (var i:uint = 0; i < 3; i++)
			{
				variations[i * 2] += variations[i * 2 + 1] * FP.elapsed;
				if (variations[i * 2] > 1 + TYPECOLORVARIATION)
				{
					variations[i * 2] = 1 + TYPECOLORVARIATION;
					variations[i * 2 + 1] = -TYPECOLORCHANGERATE *
									((Math.random() * TYPECOLORCHANGERATEVARIATION * 2) + 1 - TYPECOLORCHANGERATEVARIATION);
				}
				if (variations[i * 2] < 1 - TYPECOLORVARIATION)
				{
					variations[i * 2] = 1 - TYPECOLORVARIATION;
					variations[i * 2 + 1] = TYPECOLORCHANGERATE *
									((Math.random() * TYPECOLORCHANGERATEVARIATION * 2) + 1 - TYPECOLORCHANGERATEVARIATION);
				}
			}
			
			super.update();
		}
		
		public static function getImmuneTo(special:uint, defenseType:uint):Boolean
		{
			for (var i:uint = data.types.length + 2; i < data.types[defenseType].length; i++)
				if (data.types[defenseType][i] == special)
					return true;
			return false;
		}
		
		public static function getDamagePercent(attackType:uint, defenseType:uint):uint
		{
			return data.damageMults[data.types[attackType][defenseType + 2]][1];
		}
		
		public static function drawImmuneChart(x:Number, y:Number):void
		{
			for (var i:uint = 0; i < data.specials.length; i++)
				for (var j:uint = 0; j < data.types.length; j++)
				{
					var c:uint;
					if (getImmuneTo(i, j))
						c = 0xFF0000;
					else
						c = 0x00FF00;
					FP.buffer.fillRect(new Rectangle(x + i * 50, y + j * 50, 50, 50), c);
				}
		}
		
		public static function drawTypeChart(x:Number, y:Number):void
		{
			for (var i:uint = 0; i < data.types.length; i++)
				for (var j:uint = 0; j < data.types.length; j++)
				{
					var c:uint = FP.colorLerp(0xFF0000, 0x00FF00, getDamagePercent(i, j) / 200.0);
					FP.buffer.fillRect(new Rectangle(x + j * 50, y + i * 50, 50, 50), c);
				}
		}
	}

}