<img src="https://clarifai.com/cms-assets/20180307033326/logo2.svg" width="512">

# Clarity

<table style="width:100%">
  <tr>
    <th><img width="340" alt="Screenshot 1" src="https://user-images.githubusercontent.com/204792/56301585-1f0aa480-6106-11e9-997a-6d3e392aa8ee.png"></th>
    <th><img width="340" alt="Screenshot 2" src="https://user-images.githubusercontent.com/204792/56301586-1f0aa480-6106-11e9-9927-1ee0f8b20615.png"></th>
    <th><img width="340" alt="Screenshot 3" src="https://user-images.githubusercontent.com/204792/56301587-1f0aa480-6106-11e9-8e77-4b33152683d8.png"></th>
  </tr>
</table>


Clarifai is excited to bring you _Clarity_, an app that lets you explore the world around you through the eyes of Artificial Intelligence! Clarity exposes our world class technology in a hands-on experience for those who wish to develop a deeper connection with image recognition AI. No technical knowledge is required, just start pointing your camera, and get a feel for what your device can now see.

To get started, go to [https://clarifai.com/signup/](https://clarifai.com/signup/) to create a free developer account with Clarifai. Once an account is created, it is easy and quick to create an API Key on the website. Launching Clarity for the first time will automatically prompt for a valid API Key, which can simply be typed or copied into the alert box and permanently saved for future use.

This repository contains the source code of the Clarity app. Here you can look behind the scenes and learn how we used the [Clarifai Apple SDK](https://github.com/Clarifai/clarifai-apple-sdk) to make Clarity do all the cool things it does.

## Getting started

In this project we are are using CocoaPods to integrate the SDK.

```ruby
target 'Clarity' do
    platform :ios, '11.0'
    use_frameworks!

    pod 'Clarifai-Apple-SDK', '~> 3.0.0'
end
```

However, in your projects you also have the option of integrating manually. To see how to do it, please go to the [Clarifai Apple SDK](https://github.com/Clarifai/clarifai-apple-sdk) page and read the README.

## Learn and do more

Check out our [documentation site](https://developer.clarifai.com/docs/) to learn a lot more about how to bring A.I. to your app.

## Support

Questions? Have an issue? Send us a message at <ios-dev@clarifai.com>.

## License

The Clarity app is available under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0). See the LICENSE file for more info.
