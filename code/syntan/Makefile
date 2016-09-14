all:
	clang `gnustep-config --objc-flags` `gnustep-config --objc-libs` -fobjc-runtime=gnustep -fblocks -lobjc -ldispatch -lgnustep-base *.m -o syntan
mac:
	clang -framework Foundation *.m -o syntan
clean:
	rm syntan