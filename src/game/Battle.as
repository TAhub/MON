package game 
{
	import net.flashpunk.World;
	import net.flashpunk.FP;
	
	public class Battle extends World
	{
		private var goodGuys:Array;
		private var badGuys:Array;
		private var goodActive:uint;
		private var badActive:uint;
		
		private var player:Player;
		
		//EXP distribution
		private var faced:Array;
		private static const FACEDTICKETS:uint = 5;
		private static const NOTFACEDTICKETS:uint = 3;
		public static const MAXPARTY:uint = 5;
		
		//turn values
		private var goodFirst:Boolean;
		private var attackProgression:uint;
		
		private var introSlide:Number;
		private static const INTROSLIDESPEED:Number = 0.65;
		public static const INTROSLIDEDONE:Number = 0.8;
		
		public function Battle(good:Array, bad:Array)
		{
			goodGuys = good;
			badGuys = bad;
			for (var i:uint = 0; i < goodGuys.length; i++)
				goodGuys[i].refresh();
			for (i = 0; i < badGuys.length; i++)
				badGuys[i].refresh();
			
			goodActive = Database.NONE;
			badActive = Database.NONE;
			
			attackProgression = 0;
			
			player = new Player();
			
			introSlide = 0;
			
			//exp distribution array
			faced = new Array();
			for (i = 0; i < goodGuys.length; i++)
			{
				var f:Array = new Array();
				for (var j:uint = 0; j < badGuys.length; j++)
					f.push(false);
				faced.push(f);
			}
		}
		
		public static function makeEncounter(good:Boolean, level:uint, encounter:uint):Array
		{
			var pD:Array = getProgressionData(level);
			var enc:Array = new Array();
			var encSize:uint = Math.random() * (1 + pD[5] - pD[4]) + pD[4];
			for (var i:uint = 0; i < encSize; i++)
			{
				var extraAttacks:uint = Math.random() * (1 + pD[3] - pD[2]) + pD[2];
				
				var comb:uint;
				if (i == 0)
					comb = Main.data.encounters[encounter][1];
				else
				{
					comb = (Main.data.encounters[encounter].length - 2) * Math.random();
					comb = Main.data.encounters[encounter][comb + 2];
				}
				
				var c:Creature = new Creature(Main.data.combinations[comb][1], Main.data.combinations[comb][2],
												good, level, extraAttacks);
												
				enc.push(c);
			}
			
			//shuffle the encounter
			if (enc.length > 1)
				enc.sort(randomSort);
			
			return enc;
		}
		
		public static function randomSort(a:Creature, b:Creature):Number
		{
			if (Math.random() < 0.5)
				return -1;
			else
				return 1;
		}
		
		public static function getProgressionData(level:uint):Array
		{
			var last:uint = 0;
			for (var i:uint = 0; i < Main.data.progressionDatas.length; i++)
			{
				var minLevel:uint = Main.data.progressionDatas[i][1];
				if (level >= minLevel)
					last = i;
				else
					break;
			}
			return Main.data.progressionDatas[last];
		}
		
		private function getReady(ar:Array):uint
		{
			for (var i:uint = 0; i < ar.length; i++)
				if (ar[i].lockedIn && !ar[i].dead)
					return i;
			return Database.NONE;
		}
		
		private function attack(good:Boolean):void
		{
			var fromAr:Array;
			var to:Creature;
			if (good)
			{
				fromAr = goodGuys;
				to = badGuys[badActive];
			}
			else
			{
				fromAr = badGuys;
				to = goodGuys[goodActive];
			}
			
			var fromI:uint = getReady(fromAr);
			if (fromI == Database.NONE)
			{
				//this means that the person who WAS ready died
				//so just end this here
				return;
			}
			
			//only change the active person NOW, that the attack is 100% confirmed to happen
			if (good)
				goodActive = fromI;
			else
				badActive = fromI;
				
			if (good)
				faced[goodActive][badActive] = true; //you have now faced them, so you will get extra EXP
			
			(fromAr[fromI] as Creature).startAttack(to);
		}
		
		public static function loadGroup(loadFrom:Array, p:uint, group:Array):uint
		{
			var groupSize:uint = loadFrom[p++];
			for (var i:uint = 0; i < groupSize; i++)
			{
				var c:Creature = new Creature();
				p = c.load(loadFrom, p);
				group.push(c);
			}
			return p;
		}
		
		public static function saveGroup(saveTo:Array, group:Array):void
		{
			saveTo.push(group.length);
			for (var i:uint = 0; i < group.length; i++)
				(group[i] as Creature).save(saveTo);
		}
		
		public function getEnemies(of:Creature):Array
		{
			//if you are on the good guy list, your enemies are on the good guy list
			for (var i:uint = 0; i < goodGuys.length; i++)
				if (goodGuys[i] == of)
					return badGuys;
			return goodGuys; //no need to check the converse
		}
		
		public function getAllies(of:Creature):Array
		{
			return getEnemies(getEnemies(of)[0]);
		}
		
		public override function render():void
		{
			for (var i:uint = 0; i < goodGuys.length; i++)
				(goodGuys[i] as Creature).render(i == goodActive, i, badActive, introSlide);
			for (i = 0; i < badGuys.length; i++)
				(badGuys[i] as Creature).render(i == badActive, i, goodActive, introSlide);
				
			if (goodActive != Database.NONE && goodGuys[goodActive].animating)
				goodGuys[goodActive].renderProjectile(goodActive, badActive);
			else if (badActive != Database.NONE && badGuys[badActive].animating)
				badGuys[badActive].renderProjectile(badActive, goodActive);
				
			if (getReady(goodGuys) == Database.NONE && introSlide == 1)
				player.render(goodGuys);
		}
		
		private function awardEXP():void
		{
			//total up the EXP given to each party member
			var expTo:Array = new Array();
			for (var i:uint = 0; i < goodGuys.length; i++)
				expTo.push(0);
			
			for (i = 0; i < badGuys.length; i++)
			{
				//get the ticket distribution
				var tickets:Array = new Array();
				var totalTickets:uint = 0;
				for (var j:uint = 0; j < goodGuys.length; j++)
				{
					var tic:uint;
					if (goodGuys[j].dead)
						tic = 0;
					else if (faced[j][i])
						tic = FACEDTICKETS;
					else
						tic = NOTFACEDTICKETS;
					totalTickets += tic;
					tickets.push(tic);
				}
				
				var totalExp:uint = badGuys[i].expReward;
				for (j = 0; j < goodGuys.length; j++)
				{
					var exp:uint = Math.ceil(1.0 * totalExp * tickets[j] / totalTickets);
					expTo[j] += exp;
				}
			}
			
			//advance everyone's synergy
			for (i = 0; i < goodGuys.length; i++)
				goodGuys[i].synergyModify();
			
			//actually award the exp
			for (i = 0; i < goodGuys.length; i++)
				goodGuys[i].awardExp(expTo[i]);
		}
		
		public override function update():void
		{
			if (introSlide != 1)
			{
				introSlide += FP.elapsed * INTROSLIDESPEED;
				if (introSlide > 1)
					introSlide = 1;
				return;
			}
			
			var goodAlive:Boolean = false;
			for (var i:uint = 0; i < goodGuys.length; i++)
				if (!goodGuys[i].dead)
					goodAlive = true;
			var badAlive:Boolean = false;
			for (i = 0; i < badGuys.length; i++)
				if (!badGuys[i].dead)
					badAlive = true;
			if (!goodAlive || !badAlive)
			{
				for (i = 0; i < goodGuys.length; i++)
					goodGuys[i].endBattle();
				for (i = 0; i < badGuys.length; i++)
					badGuys[i].endBattle();
				
				if (goodAlive)
					awardEXP();
				
				(FP.engine as Main).returnToMap();
			}
			
			for (i = 0; i < goodGuys.length; i++)
				goodGuys[i].update();
			for (i = 0; i < badGuys.length; i++)
				badGuys[i].update();
			
			if (goodActive != Database.NONE && badActive != Database.NONE &&
				(goodGuys[goodActive].animating || badGuys[badActive].animating))
				return;
				
			if (goodActive != Database.NONE && goodGuys[goodActive].dead)
				goodActive = Database.NONE;
			if (badActive != Database.NONE && badGuys[badActive].dead)
				badActive = Database.NONE;
			
			if (attackProgression != 0)
			{
				switch(attackProgression)
				{
				case 1: //first attack
					attack(goodFirst);
					attackProgression = 2;
					break;
				case 2: //second attack
					attack(!goodFirst);
					attackProgression = 3;
					break;
				case 3: //turn over
					for (i = 0; i < goodGuys.length; i++)
						goodGuys[i].turnOver();
					for (i = 0; i < badGuys.length; i++)
						badGuys[i].turnOver();
					attackProgression = 0;
					player.reset();
					break;
				}
			}
			else if (getReady(goodGuys) != Database.NONE && getReady(badGuys) != Database.NONE)
			{
				//if both sides are ready, go on
				
				//if the current active person for either side is dead, activate them now
				//so there's no chance of hitting a corpse if you are too fast
				if (getReady(goodGuys) != Database.NONE && getReady(badGuys) != Database.NONE)
				{
					if (goodActive == Database.NONE)
						goodActive = getReady(goodGuys);
					if (badActive == Database.NONE)
						badActive = getReady(badGuys);
				}
				
				//execute prebattle specials
				//this is based on who the target will be assuming the OTHER person goes first, for both sides
				//trying to do otherwise would cause weird undefined behavior with priority attacks on clever enemies
				var goodA:Creature = goodGuys[getReady(goodGuys)];
				var badA:Creature = badGuys[getReady(badGuys)];
				goodA.mirrorAction(badA);
				badA.mirrorAction(goodA);
				goodA.executePrebattleSpecials(badA);
				badA.executePrebattleSpecials(goodA);
				
				//who goes first?
				goodFirst = goodA.effectiveInitiative >= badA.effectiveInitiative;
				
				attackProgression = 1;
			}
			else
			{
				if (getReady(goodGuys) == Database.NONE)
				{
					//player control
					player.update(goodGuys);
				}
				if (getReady(badGuys) == Database.NONE
					&& getReady(goodGuys) != Database.NONE) //the bad guy shouldn't pick until the player does
													//so that the player cant watch the power bars to see who is going to
													//attack next
				{
					var bP:uint = Math.random() * badGuys.length;
					badGuys[bP].pickRandomAttack();
				}
			}
		}
		
	}

}