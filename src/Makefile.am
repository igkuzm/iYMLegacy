AUTOMAKE_OPTIONS = subdir-objects

bin_PROGRAMS = iYMLegacy
iYMLegacy_SOURCES = \
		../cYandexMusic/cYandexOAuth.c \
		../cYandexMusic/cYandexMusic.c \
		../cYandexMusic/structures.c \
		../cYandexMusic/uuid4.c \
		../cYandexMusic/cJSON.c \
		AppDelegate.m \
		RootViewController.m \
		FavoritesViewController.m \
		YandexConnect.m \
		main.m

iYMLegacy_CFLAGS = \
			-framework UIKit -framework Foundation -framework QuickLook -fobjc-arc

iYMLegacy_LDFLAGS = \
			-framework UIKit -framework Foundation -framework QuickLook

iYMLegacy_LDADD = \
			-lssl -lcurl -L../libs

bin_SCRIPTS = iYMLegacy.ipa
CLEANiFILES = $(bin_SCRIPTS)
EXTRA_DIST  = iYMLegacy.ipa

_dir:
	mkdir -p iYMLegacy.app

_plist:
	sed -e 's/VERSION/${PACKAGE_VERSION}/g' Info.plist > iYMLegacy.app/Info.plist

_images:
	cp -f ../images/AppIcon*.png iYMLegacy.app/.
	cp -f ../images/Directory*.png iYMLegacy.app/.

iYMLegacy.app: iYMLegacy _dir _plist _images
	cp -f iYMLegacy iYMLegacy.app/. 
	cp -r ../libs iYMLegacy.app/.
	cd iYMLegacy.app; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libssl.0.9.8.dylib @executable_path/libs/libssl.dylib iYDLegacy; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcurl.4.dylib @executable_path/libs/libcurl.dylib iYDLegacy; \
	cd libs; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcrypto.0.9.8.dylib @executable_path/libs/libcrypto.dylib libssl.dylib; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libgcc_s.1.dylib @executable_path/libs/libgcc_s.1.dylib libssl.dylib; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libgcc_s.1.dylib @executable_path/libs/libgcc_s.1.dylib libcrypto.dylib;

iYMLegacy.ipa: iYMLegacy.app
	mkdir Payload
	cp -r iYMLegacy.app Payload/.
	${ZIP} -r iYMLegacy.ipa Payload iTunesArtwork iTunesMetadata.plist
	rm -rf Payload

clean-local:
	rm -r iYMLegacy.app
	rm -r iYMLegacy.ipa

install:
#do nothing
