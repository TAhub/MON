package game
{
	public class Item
	{
		public var type:uint;
		public var id:uint;
		public var number:uint;
		
		public function Item(i:uint = 0, n:uint = 1):void
		{
			id = i;
			type = Main.data.items[id][3];
			number = n;
		}
		
		private function get maxStack():uint
		{
			switch(type)
			{
			case 0: //attacks stack up to 1
				return 1;
			default:
				return Main.data.items[id][2];
			}
		}
		
		private function get nameLine():uint
		{
			switch(type)
			{
			case 0:
				return Main.data.attacks[id][9];
			default:
				return Main.data.items[id][1];
			}
		}
		
		public function get description():String
		{
			return Main.data.lines[nameLine + 1];
		}
		
		public function get name():String
		{
			var baseName:String = Main.data.lines[nameLine];
			if (number > 1)
				baseName += " x" + number;
			return baseName;
		}
		
		public function stack(other:Item):Boolean
		{
			if (other.type == type && other.id == id)
			{
				while (other.number < other.maxStack)
				{
					other.number += 1;
					number -= 1;
					if (number == 0)
						return true; //you have exhausted yourself stacking into them
				}
			}
			return false; //there is still some of your stuff left after stacking, or this isnt something you can stack with
		}
		
		public function save(saveTo:Array):void
		{
			saveTo.push(type);
			saveTo.push(id);
			saveTo.push(number);
		}
		
		public function fromAttack(att:uint):void
		{
			type = 0;
			id = att;
		}
		
		public function load(loadFrom:Array, p:uint):uint
		{
			type = loadFrom[p++];
			id = loadFrom[p++];
			number = loadFrom[p++];
			return p;
		}
	}

}