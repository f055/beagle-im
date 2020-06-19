
<h1 align="center">
  <img alt="Beagle Icon" src="https://raw.githubusercontent.com/f055/beagle-im/mix-new_chatslist/BeagleIM/Assets.xcassets/AppIcon.appiconset/IMG_0720_512.png" width="256" />
  <br />
  BeagleIM
</h1>

This is a fork repo of BeagleIM by [Tigase](https://tigase.net). The purpose of this fork is to apply unofficial visual improvements to BeagleIM. Changes so far:

[x] Application icon
[ ] Status bar icon
[x] Sidebar colors

## What is BeagleIM

BeagleIM is an XMPP client for macOS based on [TigaseSwift XMPP library](https://github.com/tigaseinc/tigase-swift).

## Features

[BeagleIM](https://beagle.im/) is powerful XMPP client with support for file transfer, VoIP and end-to-end encryption.

## How to build

1. Clone this repo and swith to `mix-new_chatslist` branch
2. Clone this [OpenSSL repo](https://github.com/krzyzanowskim/openssl)
3. Open `/beagle-im/BeagleIM.xcodeproj` with Xcode
4. View *Targets > Signing & Capabilities* and update your *Team* in *Signing* section
5. Select *File > Add Files to "BeagleIM"* and select `/openssl/OpenSSL.xcodeproj`
6. Select *File > Swift Packages > Update to Latest Package Versions*
7. Select *Product > Build*

## Support

When looking for support, please first search for answers to your question in the available online channels:

* Our online documentation: [Tigase Docs](https://docs.tigase.net)
* Our online forums: [Tigase Forums](https://help.tigase.net/portal/community)
* Our online Knowledge Base [Tigase KB](https://help.tigase.net/portal/kb)

If you didn't find an answer in the resources above, feel free to submit your question to either our
[community portal](https://help.tigase.net/portal/community) or open a [support ticket](https://help.tigase.net/portal/newticket).

## Downloads

You can download it from the [Mac App Store](https://itunes.apple.com/us/app/beagleim-by-tigase-inc/id1445349494?l=pl&ls=1&mt=1) or using [Homebrew](https://brew.sh/) package manager:
```
brew tap tigase/tigase
brew cask install beagleim
```

See [our Homebrew tap](https://github.com/tigase/homebrew-tigase) for details

## Using software

After installing it, go to **Preferences** and add an account or register a new one. After that you can start using XMPP client for chatting over XMPP with your account.

## Licenses

<img alt="Tigase Logo" src="https://github.com/tigase/website-assets/blob/master/tigase/images/tigase-logo.png?raw=true" width="25" /> Official [Tigase](https://tigase.net/) repository is available at: [https://github.com/tigase/beagle-im/](https://github.com/tigase/beagle-im/)

Copyright (c) 2004 Tigase, Inc.

Licensed under GPL License Version 3. Other licensing options available upon request.

Beagle icons made by <a href="https://www.flaticon.com/authors/freepik" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a> and modified by [Marek Foss](https://github.com/f055). Licensed under Flaticon License.
