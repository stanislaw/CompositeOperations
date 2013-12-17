xctool:
	cd DevelopmentApp && xctool -workspace DevelopmentApp.xcworkspace -scheme DevelopmentApp clean test

xcodebuild:
	cd DevelopmentApp && xcodebuild -verbose -workspace DevelopmentApp.xcworkspace -scheme DevelopmentApp clean test

clean:
	rm -rfv /Users/$(shell whoami)/Library/Developer/Xcode/DerivedData/DevelopmentApp*
	rm -rf DevelopmentApp/build/
