package game 
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	
	public class Walker 
	{
		//position
		private var _x:uint;
		private var _y:uint;
		private var oldX:uint;
		private var oldY:uint;
		
		//animation
		private var anim:Number;
		private static const ANIMSPEED:Number = 5.5;
		
		//control
		private var lastH:Boolean;
		private var lastV:Boolean;
		
		//combat
		private var party:Array;
		
		//inventory
		private var inventory:Array;
		private var inventoryControl:Array;
		private static const MAXINVENTORY:uint = 10;
		
		//menu order
		private static const M_CONTROL:uint = 0;
		private static const M_MAIN:uint = 1;
		private static const M_ITEM:uint = 2;
		private static const M_ACTION:uint = 3;
		private static const M_CHAR:uint = 4;
		private static const M_ATTACK:uint = 5;
		
		private static var M_MAIN_P:uint = 0;
		private static const M_MAIN_INVENTORY:uint = M_MAIN_P++;
		private static const M_MAIN_CHARACTER:uint = M_MAIN_P++;
		private static const M_MAIN_CAMP:uint = M_MAIN_P++;
		
		private static var M_ACTION_INVENTORY_P:uint = 0;
		private static const M_ACTION_INVENTORY_USE:uint = M_ACTION_INVENTORY_P++;
		private static const M_ACTION_INVENTORY_DISCARD:uint = M_ACTION_INVENTORY_P++;
		
		private static var M_ACTION_MENU_P:uint = 0;
		private static const M_ACTION_MENU_BIO:uint = M_ACTION_MENU_P++;
		private static const M_ACTION_MENU_ATTACKS:uint = M_ACTION_MENU_P++;
		
		public function Walker(x:uint, y:uint, level:uint = 1, good:Boolean = false, loadedParty:Array = null, encounter:uint = 0)
		{
			teleportTo(x, y);
			
			lastH = false;
			lastV = false;
			
			inventory = new Array();
			inventoryControl = null;
			
			if (loadedParty)
				party = loadedParty;
			else
				party = Battle.makeEncounter(good, level, encounter);
		}
		
		public function teleportTo(x:uint, y:uint):void
		{
			_x = x;
			_y = y;
			oldX = x;
			oldY = y;
			anim = -1;
		}
		
		public function inventoryAdd(it:Item):void
		{
			for (var i:uint = 0; i < inventory.length; i++)
			{
				var it2:Item = inventory[i];
				if (it.stack(it2))
					return; //the item was exhausted, so you are done here
			}
			inventory.push(it); //the item is still there, so stick it in
		}
		
		public static function load(loadFrom:Array, p:uint, walkerArray:Array):uint
		{
			var x:uint = loadFrom[p++];
			var y:uint = loadFrom[p++];
			var party:Array = new Array();
			p = Battle.loadGroup(loadFrom, p, party);
			var w:Walker = new Walker(x, y, 1, false, party);
			var inventoryL:uint = loadFrom[p++]
			for (var i:uint = 0; i < inventoryL; i++)
			{
				var it:Item = new Item();
				p = it.load(loadFrom, p);
				w.inventoryAdd(it);
			}
			walkerArray.push(w);
			return p;
		}
		
		public function addPartyMember(cr:Creature):void
		{
			party.push(cr);
		}
		
		public function get partySize():uint
		{
			return party.length
		}
		
		public function save(saveTo:Array):void
		{
			saveTo.push(_x);
			saveTo.push(_y);
			Battle.saveGroup(saveTo, party);
			saveTo.push(inventory.length);
			for (var i:uint = 0; i < inventory.length; i++)
				(inventory[i] as Item).save(saveTo);
		}
		
		public function get animating():Boolean { return anim != -1; }
		public function get x():uint { return _x; }
		public function get y():uint { return _y; }
		public function get xS():Number { return Math.floor((_x - mX) * Map.tileWidth); }
		public function get yS():Number { return Math.floor((_y - mY) * Map.tileHeight); }
		private function get mX():Number
		{
			if (anim != -1)
				return _x * anim + oldX * (1 - anim);
			else
				return _x;
		}
		private function get mY():Number
		{
			if (anim != -1)
				return _y * anim + oldY * (1 - anim);
			else
				return _y;
		}
		
		private function typeMax(type:uint):uint
		{
			switch(type)
			{
			case M_ITEM: //pick item
				if (inventoryControl[M_MAIN] == M_MAIN_CAMP)
					return foodInventory.length;
				else
					return inventory.length;
			case M_ACTION: //pick action
				switch(inventoryControl[M_MAIN])
				{
				case M_MAIN_INVENTORY: //inventory
					return M_ACTION_INVENTORY_P;
				case M_MAIN_CHARACTER: //character
					return M_ACTION_MENU_P;
				default:
					return 0;
				}
			case M_CHAR: //pick target
				return party.length;
			case M_ATTACK: //pick attack
				if (inventoryControl[M_MAIN] == 0)
					return Math.min(Creature.MAXATTACKS, selectedPartyMember.attackList.length + 1); //so you can add new attacks
				else
					return selectedPartyMember.attackList.length; //you can't remove empty slots
			case M_MAIN: //main menu
				return M_MAIN_P;
			default:
				return 0;
			}
		}
		
		private function get foodInventory():Array
		{
			var fI:Array = new Array();
			for (var i:uint = 0; i < inventory.length; i++)
			{
				var it:Item = inventory[i];
				if (it.type == 1)
					fI.push(i);
			}
			return fI;
		}
		
		public function useOne(i:uint):void
		{
			var it:Item = inventory[i];
			it.number -= 1;
			
			if (it.number == 0)
			{
				var newInv:Array = new Array();
				for (var j:uint = 0; j < inventory.length; j++)
					if (j != i)
						newInv.push(inventory[j]);
				inventory = newInv;
			}
		}
		
		private function useCamp():void
		{
			var fI:uint = foodInventory[inventoryControl[M_ITEM]];
			var it:Item = inventory[fI];
			useOne(fI); //consume the food
			
			for (var i:uint = 0; i < party.length; i++)
			{
				var c:Creature = party[i];
				
				c.rest(it);
			}
		}
		
		private function get validUse():Boolean
		{
			switch(inventoryControl[M_MAIN])
			{
			case M_MAIN_INVENTORY: //inventory
				var it:Item = inventory[inventoryControl[M_ITEM]];
				switch(it.type)
				{
				case 0:
					return selectedPartyMember.canUseAttack(it.id);
				case 1:
					return false; //can't use food items like that
				case 2:
					return !selectedPartyMember.powerMax; //can only drink when necessary
				default:
					return false; //who knows what this is, but you cant use it
				}
				break;
			case M_MAIN_CHARACTER: //character
				switch(inventoryControl[M_ACTION])
				{
				case M_ACTION_MENU_ATTACKS: //remove attack
					return inventory.length < MAXINVENTORY;
				}
				break;
			case M_MAIN_CAMP: //camp
				return true;
			}
			return false; //who knows what this is
		}
		
		public function getParty():Array { return party; }
		
		private function useItem():void
		{
			var it:Item = inventory[inventoryControl[M_ITEM]];
			useOne(inventoryControl[M_ITEM]); //this may or may not destroy that inventory item, so no longer refer to it
			switch(inventoryControl[M_ACTION])
			{
			case M_ACTION_INVENTORY_USE: //use
				switch(it.type)
				{
				case M_ACTION_MENU_ATTACKS: //attack
					var oldAtt:Item = null;
					if (inventoryControl[M_ATTACK] != selectedPartyMember.attackList.length)
					{
						oldAtt = new Item();
						oldAtt.fromAttack(selectedPartyMember.attackList[inventoryControl[M_ATTACK]]);
					}
					
					selectedPartyMember.attackList[inventoryControl[M_ATTACK]] = it.id;
					
					if (oldAtt)
						inventoryAdd(oldAtt);
					break;
				case 2: //drink
					selectedPartyMember.useDrink(it);
					break;
				}
				break;
			case M_ACTION_INVENTORY_DISCARD: //discard
				break;
			}
		}
		
		private function useCharacter():void
		{
			switch(inventoryControl[M_ACTION])
			{
			case M_ACTION_MENU_ATTACKS: //remove attack
				var asIt:Item = new Item();
				var lst:Array = selectedPartyMember.attackList;
				asIt.fromAttack(lst[inventoryControl[M_ATTACK]]);
				selectedPartyMember.removeAttack(lst[inventoryControl[M_ATTACK]]);
				inventoryAdd(asIt);
				break;
			}
		}
		
		private function inventoryInput():void
		{
			var toChange:uint = inventoryChain[inventoryControl[M_CONTROL]];
			var max:uint = typeMax(toChange);
			
			if (Input.pressed(Key.SPACE) && inventoryControl[M_CONTROL] == inventoryChain.length - 1 && validUse)
			{
				switch(inventoryControl[M_MAIN])
				{
				case M_MAIN_INVENTORY: //use as item
					useItem();
					break;
				case M_MAIN_CHARACTER: //character
					useCharacter();
					break;
				case M_MAIN_CAMP:
					useCamp();
					break;
				}
				
				inventoryControl = null; //done using the inventory
				return;
			}
			
			
			var iAdd:int = 0;
			if (Input.pressed(Key.UP))
				iAdd -= 1;
			if (Input.pressed(Key.DOWN))
				iAdd += 1;
				
			if (iAdd != 0)
			{
				if (iAdd == -1 && inventoryControl[toChange] == 0)
					inventoryControl[toChange] = max - 1;
				else if (iAdd == 1 && inventoryControl[toChange] == max - 1)
					inventoryControl[toChange] = 0;
				else
					inventoryControl[toChange] += iAdd;
			}
			else
			{
				var pAdd:int = 0;
				if (Input.pressed(Key.LEFT))
					pAdd -= 1;
				if (Input.pressed(Key.RIGHT))
					pAdd += 1;
				
				if (pAdd != 0)
				{
					if (pAdd == -1 && inventoryControl[M_CONTROL] != 0)
					{
						inventoryControl[M_CONTROL] -= 1;
					}
					else if (pAdd == 1 && inventoryControl[M_CONTROL] < inventoryChain.length - 1)
					{
						inventoryControl[M_CONTROL] += 1;
						inventoryControl[inventoryChain[inventoryControl[M_CONTROL]]] = 0;
					}
				}
			}
		}
		
		public function renderInventory():void
		{
			if (!inventoryControl)
				return;
			
			var lists:Array = new Array();
			var listHeights:Array = new Array();
			for (var i:uint = 0; i < inventoryChain.length && i <= inventoryControl[M_CONTROL]; i++)
			{
				var list:Array = new Array();
				var totalHeight:Number = 0;
				var max:uint = typeMax(inventoryChain[i]);
				var hitSel:Boolean = false;
				for (var j:uint = 0; j < max; j++)
				{
					var contents:String;
					switch(inventoryChain[i])
					{
					case M_ITEM:
						var it:Item;
						if (inventoryControl[M_MAIN] == M_MAIN_CAMP)
							it = inventory[foodInventory[j]];
						else
							it = inventory[j];
						contents = it.name;
						break;
					case M_ACTION:
						switch(inventoryControl[M_MAIN])
						{
						case M_MAIN_INVENTORY: //inventory
							switch(j)
							{
							case M_ACTION_INVENTORY_USE:
								contents = "Use";
								break;
							case M_ACTION_INVENTORY_DISCARD:
								contents = "Discard";
								break;
							}
							break;
						case M_MAIN_CHARACTER:
							switch(j)
							{
							case M_ACTION_MENU_BIO:
								contents = "Bio";
								break;
							case M_ACTION_MENU_ATTACKS:
								contents = "Attack";
								break;
							}
							break;
						}
						break;
					case M_CHAR:
						contents = (party[j] as Creature).name;
						break;
					case M_ATTACK:
						if (j < selectedPartyMember.attackList.length)
						{
							var asIt:Item = new Item();
							asIt.fromAttack(selectedPartyMember.attackList[j]);
							contents = asIt.name;
						}
						else
							contents = "Empty";
						break;
					case M_MAIN:
						switch(j)
						{
						case M_MAIN_INVENTORY:
							contents = "Inventory";
							break;
						case M_MAIN_CHARACTER:
							contents = "Characters";
							break;
						case M_MAIN_CAMP:
							contents = "Camp";
							break;
						}
						break;
					}
					
					var tx:Text = new Text(contents);
					var selected:Boolean = j == inventoryControl[inventoryChain[i]];
					if (selected)
					{
						hitSel = true;
						tx.color = PartyGen.TEXTSELECTEDCOLOR;
					}
					else
						tx.color = PartyGen.TEXTNEUTRALCOLOR;
						
					list.push(tx);
					if (!hitSel)
						totalHeight += tx.height;
				}
				
				lists.push(list);
				listHeights.push(totalHeight);
			}
			
			var x:Number = 0;
			for (i = 0; i < lists.length; i++)
			{
				list = lists[i];
				var y:Number = FP.halfHeight - listHeights[i];
				var biggestW:Number = 0;
				for (j = 0; j < list.length; j++)
				{
					tx = list[j];
					tx.render(FP.buffer, new Point(x, y), new Point(0, 0));
					y += tx.height;
					if (tx.width > biggestW)
						biggestW = tx.width;
				}
				x += biggestW;
			}
		}
		
		private function get inventoryChain():Array
		{
			var chain:Array = new Array();
			chain.push(M_MAIN); //the main menu is always at the bottom
			switch(inventoryControl[M_MAIN])
			{
			case M_MAIN_INVENTORY: //inventory
				chain.push(M_ITEM); //you always must select an item
				chain.push(M_ACTION); //you always must select an action
				var it:Item = inventory[inventoryControl[M_ITEM]];
				var action:uint = inventoryControl[M_ACTION];
				switch(it.type)
				{
				case 0: //it's an attack
					if (action == M_ACTION_INVENTORY_USE)
					{
						chain.push(M_CHAR); //pick a target
						chain.push(M_ATTACK); //pick an attack to replace
					}
					break;
				case 2: //it's a drink
					if (action == M_ACTION_INVENTORY_USE)
						chain.push(M_CHAR); //pick a target
					break;
				}
				break;
			case M_MAIN_CHARACTER: //characters
				chain.push(M_CHAR); //pick a character to examine
				chain.push(M_ACTION); //then pick an action
				switch(inventoryControl[M_ACTION])
				{
				case M_ACTION_MENU_ATTACKS: //attack
					chain.push(M_ATTACK); //pick an attack to remove
					break;
				}
				break;
			case M_MAIN_CAMP: //camping
				chain.push(M_ITEM); //pick something to eat
				break;
			}
			return chain;
		}
		
		private function get selectedPartyMember():Creature
		{
			return party[inventoryControl[M_CHAR]];
		}
		
		public function playerInput():void
		{
			if (anim != -1)
				return;
			
			if (Input.pressed(Key.M))
			{
				if (inventoryControl)
					inventoryControl = null;
				else
					inventoryControl = [0, 0, 0, 0, 0, 0];
			}
			
			if (inventoryControl)
			{
				inventoryInput();
				return;
			}
				
			var xA:int = 0;
			var yA:int = 0;
			if (Input.check(Key.LEFT))
				xA -= 1;
			if (Input.check(Key.RIGHT))
				xA += 1;
			if (Input.check(Key.UP))
				yA -= 1;
			if (Input.check(Key.DOWN))
				yA += 1;
				
			if (xA == 0 && yA == 0)
			{
				lastH = false;
				lastV = false;
			}
			else if (!lastH || !lastV)
			{
				if (xA == 0 && yA != 0)
					lastV = true;
				else if (xA != 0 && yA == 0)
					lastH = true;
				else if (xA != 0 && yA != 0)
				{
					if (lastH)
						yA = 0;
					else if (lastV)
						xA = 0;
					else
						lastH = true;
				}
			}
			
			if (xA != 0 || yA != 0)
				move(xA, yA);
		}
		
		private function battle(other:Walker):void
		{
			FP.world = new Battle(party, other.party);
		}
		
		public function get dead():Boolean
		{
			for (var i:uint = 0; i < party.length; i++)
				if (!party[i].dead)
					return false;
			return true;
		}
		
		private function move(xA:int, yA:int):void
		{
			if ((_x == 0 && xA == -1) || (_y == 0 && yA == -1))
				return;
			if (xA != 0 && yA != 0)
				return;
			var nX:uint = _x + xA;
			var nY:uint = y + yA;
			var wAt:Walker = (FP.world as Map).walkerAt(nX, nY);
			if (wAt)
			{
				battle(wAt);
				return;
			}
			if ((FP.world as Map).tryMove(_x, _y, nX, nY))
			{
				anim = 0;
				_x = nX;
				_y = nY;
			}
		}
		
		public function update():void
		{
			if (anim != -1)
			{
				anim += FP.elapsed * ANIMSPEED;
				if (anim >= 1)
				{
					(FP.world as Map).finishMove(oldX, oldY);
					anim = -1;
					oldX = _x;
					oldY = _y;
				}
			}
		}
		
		public function render():void
		{
			var hNum:Number = (FP.world as Map).getHeightNum(_x, _y);
			if (anim != -1 && anim < 0.5)
				hNum = (FP.world as Map).getHeightNum(oldX, oldY);
			
			var dX:Number = mX * Map.tileWidth;
			var dY:Number = mY * Map.tileWidth;
			dY -= hNum;
			
			var firstC:Creature = null;
			for (var i:uint = 0; i < party.length; i++)
				if (!party[i].dead)
				{
					firstC = party[i];
					break;
				}
			if (firstC)
				firstC.renderAt(dX, dY, 1, Map.tileWidth);
		}
	}
}