# BrickHack Mobile (iOS)


<div style="display: inline">

<img alt="Code Climate maintainability" src="https://img.shields.io/codeclimate/maintainability/codeRIT/brickhack-mobile-ios">

<img alt="GitHub release (latest SemVer)" src="https://img.shields.io/github/v/release/codeRIT/brickhack-mobile-ios">
</div>

<p align="center">
	<img src=".github/appicon.jpg" width="300px" style="border-radius: 20%"/>
</p>

## Features 

The definitive app for BrickHack 6 attendees!

This app lets you:

* **View the Schedule:** Attendees are able to view the latest and greatest events as they happen, and view some basic information for each event..
* **Track events**: By favoriting events, users can get push notifications as those events start.
* **Resources:** View the Devpost, Slack, and call emergency services if needed.


## Setup

### Installing CocoaPods (and related project-level dependencies):

To install CocoaPods (and other dependencies), make sure you have ruby `2.6.3` or greater. The easiest way to do this on macOS is to set a global `rbenv` version as follows:
```
$ brew install rbenv ruby-build
$ rbenv install 2.6.3
$ rbenv global 2.6.3
```

And add rbenv to your `~/.bashrc` or `~/.zshrc`:
```
eval "$(rbenv init -)"
```
Or, for `fish` users, in your `~/.config/fish/config.fish`:
```
source (rbenv init - | source)
```

Finally, run this to install `cocoapods` and its dependencies. 

```
$ bundle install
```
```
$ pod install
```

### API Keys

The complicated series of steps above means that on first `$ pod install`, CocoaPods will prompt for API keys that need to be set. 

- If you are an open-source contributor, please provide your own keys (e.g., Google Sheets) as needed.
- If you are a member of codeRIT, ask the Engineering team lead for keys.

## Contribution
For Git, we will be following the
[Git Workflow](https://nvie.com/posts/a-successful-git-branching-model/)
set forth by Vincent Driessen on NVIE.


### .xcodeproj

Each developer needs to use and _not_ commit their own Bundle Identifier, and developer team. 

The App Store version uses `io.BrickHack.Mobile.peterkos`, but despite this, all locally run versions need to use a unique identifier. 
