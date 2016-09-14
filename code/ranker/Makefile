all:
	clang `gnustep-config --objc-flags` `gnustep-config --objc-libs` -fobjc-runtime=gnustep -fblocks -lobjc -ldispatch -lgnustep-base *.m -o ranker
mac:
	clang -framework Foundation *.m -o ranker
clean:
	rm ranker
