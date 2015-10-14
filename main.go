// +build linux,!darwin

package main

import (
	"log"

	"golang.org/x/mobile/app"
	"golang.org/x/mobile/event/key"
	"golang.org/x/mobile/event/lifecycle"
	"golang.org/x/mobile/event/paint"
	"golang.org/x/mobile/event/size"
	"golang.org/x/mobile/event/touch"
)

var (
	inst app.App
)

func onPaintEvent(e *paint.Event) {
	log.Println("onPaintEvent", e)
	inst.Publish()
}

func onLifecycleEvent(e *lifecycle.Event) {
	log.Println("onLifecycleEvent", e)
	crossAlive := e.Crosses(lifecycle.StageAlive)
	crossVisible := e.Crosses(lifecycle.StageVisible)
	crossFocused := e.Crosses(lifecycle.StageFocused)
	if crossAlive == lifecycle.CrossOn {
		log.Println("onCreate")
	}
	if crossVisible == lifecycle.CrossOn {
		log.Println("onStart")
	}
	if crossFocused == lifecycle.CrossOn {
		log.Println("onResume")
	} else if crossFocused == lifecycle.CrossOff {
		log.Println("onFreeze")
	}
	if crossVisible == lifecycle.CrossOff {
		log.Println("onStop")
	}
	if crossAlive == lifecycle.CrossOff {
		log.Println("onDestroy")
	}
}

func onSizeEvent(e *size.Event) {
	log.Println("onSizeEvent", e)
}

func onTouchEvent(e *touch.Event) {
	log.Println("onTouchEvent", e)
}

func onKeyEvent(e *key.Event) {
	log.Println("onKeyEvent", e)
}

func appMain(a app.App) {
	inst = a
	for e := range a.Events() {
		switch e := a.Filter(e).(type) {
		case lifecycle.Event:
			onLifecycleEvent(&e)
		case size.Event:
			onSizeEvent(&e)
		case paint.Event:
			onPaintEvent(&e)
		case touch.Event:
			onTouchEvent(&e)
		case key.Event:
			onKeyEvent(&e)
		}
	}
}

func main() {
	app.Main(appMain)
}
