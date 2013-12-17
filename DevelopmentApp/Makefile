xcodebuild:
	xcodebuild -verbose -workspace DevelopmentApp.xcworkspace -scheme DevelopmentApp clean test

xctool:
	xctool -workspace DevelopmentApp.xcworkspace -scheme DevelopmentApp clean test

clean:
	rm -rfv /Users/$(shell whoami)/Library/Developer/Xcode/DerivedData/DevelopmentApp*
	rm -rf DevelopmentApp/build/
