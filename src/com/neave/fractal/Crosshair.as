package com.neave.fractal
{
	import flash.display.CapsStyle;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	
	public final class Crosshair extends Sprite
	{
		public function Crosshair(size:uint = 6)
		{
			drawCrosshair(size, 3, 0x000000, 0.5);
			drawCrosshair(size, 1, 0xffffff, 1);
			filters = [ new GlowFilter(0x000000, 0.5, 4, 4, 1, 2) ];
			cacheAsBitmap = true;
		}
		
		private function drawCrosshair(size:uint, thickness:uint, color:uint, alpha:Number):void
		{
			graphics.lineStyle(thickness, color, alpha, true, LineScaleMode.NORMAL, CapsStyle.SQUARE);
			graphics.moveTo(0, -size);
			graphics.lineTo(0, size);
			graphics.moveTo(-size, 0);
			graphics.lineTo(size, 0);
		}
	}
}