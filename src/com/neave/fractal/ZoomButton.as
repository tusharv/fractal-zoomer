package com.neave.fractal
{
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.SimpleButton;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	public final class ZoomButton extends SimpleButton
	{
		private var plusIcon:Boolean;
		
		public function ZoomButton(plusIcon:Boolean)
		{
			this.plusIcon = plusIcon;
			
			addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			
			super(drawUpState(), drawOverState(), drawDownState(), drawButtonShape());
		}
		
		private function onMouseOver(event:MouseEvent):void
		{
			Mouse.cursor = MouseCursor.BUTTON;
		}
		
		private function onMouseOut(event:MouseEvent):void
		{
			Mouse.cursor = MouseCursor.HAND;
		}
		
		private function drawIcon(graphics:Graphics):void
		{
			graphics.beginFill(0x222222);
			graphics.drawRect(15, 23, 20, 4);
			graphics.endFill();
			
			if (plusIcon)
			{
				graphics.beginFill(0x222222);
				graphics.drawRect(23, 15, 4, 20);
				graphics.endFill();
			}
		}
		
		private function drawButtonShape(alpha:Number = 1):Shape
		{
			var m:Matrix = new Matrix();
			m.createGradientBox(50, 50, Math.PI / 2);
			
			var shape:Shape = new Shape();
			shape.graphics.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xdddddd], [alpha, alpha], [0x00, 0xff], m);
			shape.graphics.drawRoundRect(0, 0, 50, 50, 5, 5);
			shape.graphics.endFill();
			
			drawIcon(shape.graphics);
			
			return shape;
		}
		
		private function drawUpState():Shape
		{
			var shape:Shape = drawButtonShape(0.75);
			shape.blendMode = BlendMode.ADD;
			return shape;
		}
		
		private function drawOverState():Shape
		{
			var shape:Shape = drawButtonShape();
			return shape;
		}
		
		private function drawDownState():Shape
		{
			var shape:Shape = drawButtonShape();
			shape.filters = [ new GlowFilter(0x000000, 1, 15, 15, 0.5, 3, true) ];
			return shape;
		}
	}
}