# Simple 3D Swift

![Simple3DSwiftDemo](/simple3Ddemo.gif?raw=true "Simple3DSwift Demo")

A quick experiment in minimalist [Swift](https://developer.apple.com/swift/) coding and [3D math](https://www.amazon.com/Math-Primer-Graphics-Game-Development-ebook-dp-B008KZU548/dp/B008KZU548).

## The Goal

To create an interactive 3D [wireframe](https://en.wikipedia.org/wiki/Wire-frame_model) world using minimal Swift code and no **3D** or **graphics libraries** ([AppKit](https://developer.apple.com/documentation/appkit) is used for keyboard event handling and basic drawing).

## Result

The **3D world** is composed, rendered, and animated in about **~200 lines** of **Swift** ([code](/Simple3D.swift)), which includes geometry, event handling, and animation.

## Discussion

This code could be condensed further, and could certainly be improved in many ways, but mostly this was an experiment to see if I could reduce the math for a basic 3D wireframe renderer down to the barest essentials.

The code is not much more than a handful of `CGFloat`s and calls to `sin()`/`cos()` for the rotations. This is by no means a robust or performant 3D engine, but I was happy with how little code was required to get the world up-and-running.

## Related Article

I'm working on an article (to be posted [on my blog](http://sound-of-silence.com)) which summarizes the minimal math and data structures in this demo, since it might be of interest to individuals just getting started writing 3D programs. If this is something you'd like to see please [let me know](http://sound-of-silence.com/?page=contact).

## Author

**Matt Reagan** - Website: [http://sound-of-silence.com/](http://sound-of-silence.com/) - Twitter: [@hmblebee](https://twitter.com/hmblebee)

## License

Source code and related resources are Copyright (C) Matthew Reagan 2019. The source code is released under the [MIT License](https://opensource.org/licenses/MIT).
