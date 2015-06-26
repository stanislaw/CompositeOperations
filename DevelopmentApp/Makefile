test:
	./build.sh distribute
xctool:
	xctool -project DevelopmentApp.xcodeproj \
               -scheme CompositeOperations-iOS \
               -sdk iphonesimulator \
               clean test

xcodebuild:
	xcodebuild -verbose -project DevelopmentApp.xcodeproj -scheme CompositeOperations clean test

