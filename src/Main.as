package
{
	import com.neave.fractal.FractalZoomer;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;

	[SWF(width="800", height="600", backgroundColor="#000a00", frameRate="31")]	
	public class Main extends Sprite
	{
		private var fractal:FractalZoomer;
		
		public function Main()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.showDefaultContextMenu = false;
			
			fractal = new FractalZoomer(stage.stageWidth, stage.stageHeight);
			addChild(fractal);
			
			stage.addEventListener(Event.RESIZE, resizeFractal);			
		}
		
		private function resizeFractal(event:Event):void
		{
			fractal.setSize(stage.stageWidth, stage.stageHeight);
		}
	}
}