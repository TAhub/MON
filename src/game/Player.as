package game 
{
	import flash.geom.Point;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	
	public class Player 
	{
		//spacing constants
		private static const ATTNAMEHEIGHT:uint = 100;
		
		private var creatureOn:uint;
		private var attackOn:uint;
		
		public function Player() 
		{
			reset();
		}
		
		public function reset():void
		{
			creatureOn = 0;
			attackOn = 0;
		}
		
		private function applyCAdd(cAdd:int, creatures:Array):void
		{
			if (cAdd == -1 && creatureOn == 0)
				creatureOn = creatures.length - 1;
			else if (cAdd == 1 && creatureOn == creatures.length - 1)
				creatureOn = 0;
			else
				creatureOn += cAdd;
				
			if (cAdd != 0)
				attackOn = 0;
		}
		
		public function render(creatures:Array):void
		{
			var c:Creature = creatures[creatureOn];
			var attacks:Array = c.validAttacks;
			var att:uint = attacks[attackOn];
			
			var asIt:Item = new Item();
			asIt.fromAttack(att);
			
			var y:uint = FP.height - ATTNAMEHEIGHT;
			y = drawLine(asIt.name, 0, y);
			y = drawLine(getAutoDesc(c, att), 0, y);
			drawLine(asIt.description, 0, y);
		}
		
		private function drawLine(str:String, x:uint, y:uint):uint
		{
			var str2:String = "";
			
			while (true)
			{
				var tx:Text = new Text(str);
				if (tx.width < FP.width - x)
				{
					if (str.length == 0)
					{
						trace("Cutting error");
						return 0;
					}
					tx.render(FP.buffer, new Point(x, y), FP.camera);
					if (str2.length > 0) //draw str2 also
						return drawLine(str2, x, y + tx.height);
					else
						return y + tx.height;
				}
				else
				{
					//remove a word from str and move it into str2
					
					var cutPoint:uint;
					var hasAdded:Boolean = false;
					for (var i:uint = str.length - 1; i >= 0; i--)
					{
						if (str.charAt(i)== " " && hasAdded)
						{
							cutPoint = i + 1;
							break;
						}
						str2 = str.charAt(i) + str2;
						hasAdded = true;
						if (i == 0)
							cutPoint = 0;
					}
					str = str.substr(0, cutPoint);
				}
			}
			return 0;
		}
		
		public static function getAutoDesc(c:Creature, att:uint):String
		{
			var aD:String = "";
			
			var damage:uint = c.getAttackDamage(att);
			if (damage > 0)
				aD += damage + " damage";
				
			var cost:uint = Main.data.attacks[att][5];
			if (cost != 0)
			{
				if (aD.length > 0)
					aD += ", ";
				aD += cost + " cost";
			}
				
			var specials:String = "";
			for (var i:uint = 6; i <= 7; i++)
			{
				var sp:uint = Main.data.attacks[att][i];
				if (sp != Database.NONE)
				{
					var line:uint = Main.data.specials[sp][Main.data.specials[sp].length - 1];
					if (specials.length != 0)
						specials += ", ";
					specials += Main.data.lines[line];
				}
			}
			
			if (specials.length > 0)
			{
				if (aD.length > 0)
					aD += " ";
				aD += "(" + specials + ")";
			}
				
			return aD;
		}
		
		public function update(creatures:Array):void
		{
			//change creature input
			var cAdd:int = 0;
			if (Input.pressed(Key.UP))
				cAdd -= 1;
			if (Input.pressed(Key.DOWN))
				cAdd += 1;
				
			applyCAdd(cAdd, creatures);
			
			//in case you have a dead person selected
			while (creatures[creatureOn].dead)
			{
				if (cAdd == 0)
					cAdd = 1;
					
				applyCAdd(cAdd, creatures);
			}
			
			//change attack input
			var mAdd:int = 0;
			if (Input.pressed(Key.LEFT))
				mAdd -= 1;
			if (Input.pressed(Key.RIGHT))
				mAdd += 1;
			
			var c:Creature = creatures[creatureOn];
			c.highlight();
			var attacks:Array = c.validAttacks;
			if (mAdd == -1 && attackOn == 0)
				attackOn = attacks.length - 1;
			else if (mAdd == 1 && attackOn == attacks.length - 1)
				attackOn = 0;
			else
				attackOn += mAdd;
				
			if (Input.check(Key.SPACE))
				c.chooseAttack(attacks[attackOn]);
		}
	}

}