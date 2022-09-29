![Shakuro Infinity Scroll View](Resources/title_image.png)
<br><br>
# InfinityScrollView
![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)
![License MIT](https://img.shields.io/badge/license-MIT-green.svg)

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)

`InfinityScrollView` is a Swift library that allows you to add endless horizontal scroll to different items. `InfinityScrollView` has various configuration options:
- fast deceleration rate 
- snap to center item 
- configurable snap deceleration animations
 

Infinity scroll example:

![](Resources/infinity_scroll.gif)


Infinity scroll example with different items sizes:

![](Resources/infinity_scroll_with_different_sizes.gif)


Infinity scroll example with snap to center item:

![](Resources/infinity_scroll_with_snap_to_center.gif)


Single item behaviour:

![](Resources/single_item_behaviour.gif)


## Requirements

- iOS 11.0+
- Xcode 11.0+
- Swift 5.0+

## Installation

### CocoaPods

To integrate Infinity Scroll View into your Xcode project with CocoaPods, specify it in your `Podfile`:

```ruby
pod 'Shakuro.InfinityScrollView'
```

Then, run the following command:

```bash
$ pod install
```

### Manually

If you prefer not to use CocoaPods, you can integrate Shakuro.InfinityScrollView simply by copying it to your project.

## Usage

Just create `InfinityScrollView` programmatically or in the storyboard. Take into account that `InfinityScrollView` must have the data source and the delegate objects. The data source needs to adopt the `InfinityScrollViewDataSource` protocol and the delegate has to adopt the `InfinityScrollViewDelegate` protocol. The data source provides the views that `InfinityScrollView` will display. The delegate allows you to respond to scrolling events.

Take a look at the [InfinityScrollView_Example](https://github.com/shakurocom/InfinityScrollView/tree/main/InfinityScrollView_Example) (you need to perform `pod install` before before using it).

## License

Shakuro.InfinityScrollView is released under the MIT license. [See LICENSE](https://github.com/shakurocom/InfinityScrollView/blob/main/LICENSE.md) for details.

## Give it a try and reach us

Star this tool if you like it, it will help us grow and add new useful things. Feel free to reach out and hire our team to develop a web project for you.


