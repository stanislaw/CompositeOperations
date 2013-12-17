
xcodebuild:
	rm -rfv /Users/$(shell whoami)/Library/Developer/Xcode/DerivedData/DevelopmentApp*
	rm -rf DevelopmentApp/build/
	cd DevelopmentApp && xcodebuild -verbose -workspace DevelopmentApp.xcworkspace -scheme DevelopmentApp clean build test

