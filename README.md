# Introduction 
Short test of Tabular data with Realm and RxSwift

# Getting Started
Software dependencies:

Project requires following pods
- https://cocoapods.org/pods/RealmSwift
- https://cocoapods.org/pods/RxSwift
- https://cocoapods.org/pods/lottie-ios

# Build and Test
The project includes external dependencies added through cocoapods which are *not* included in the source control so project 
requires pod installation .
Run on terminal:
 - 1 - pod install

# Logic

- TabularData Framework to download and parse the csv data and Realm to store and query the data locally
- We use RxSwift Framework to implement reactive updates to the content
- Lottie pod used to display a loading animation at the start
