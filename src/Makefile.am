AUTOMAKE_OPTIONS = subdir-objects

bin_PROGRAMS = iYMLegacy
iYMLegacy_SOURCES = \
		../cYandexMusic/cYandexOAuth.c \
		../cYandexMusic/cYandexMusic.c \
		../cYandexMusic/oauth.c \
		../cYandexMusic/structures.c \
		../cYandexMusic/uuid4.c \
		../cYandexMusic/cJSON.c \
		../cYandexMusic/ezxml.c \
		AppDelegate.m \
		Item.m \
		RootViewController.m \
		FeedViewController.m \
		FavoritesViewController.m \
		SearchViewController.m \
		SearchViewControllerDetail.m \
		YandexConnect.m \
		TrackListViewController.m \
		PlayerViewController.m \
		RecentsViewController.m \
		PlayerController.m \
		PlaylistsViewController.m \
		TextEditViewController.m \
		ActionSheet.m \
		main.m

iYMLegacy_CFLAGS = 

iYMLegacy_OBJCFLAGS = -fobjc-arc

iYMLegacy_LDFLAGS = \
			-framework UIKit \
			-framework MediaPlayer \
			-framework CoreMedia \
			-framework AVFoundation \
			-framework Foundation \
			-framework QuickLook \
			-framework CoreGraphics

iYMLegacy_LDADD = \
									-lssl -lcurl -L../libs

bin_SCRIPTS = iYMLegacy.ipa
CLEANFILES = $(bin_SCRIPTS)
EXTRA_DIST  = iYMLegacy.ipa

_dir:
	mkdir -p iYMLegacy.app

_plist:
	sed -e 's/VERSION/${PACKAGE_VERSION}/g' Info.plist > iYMLegacy.app/Info.plist

_images:
	cp -f ../images/Icon*.png iYMLegacy.app/.
	cp -f ../images/player*.png iYMLegacy.app/.
	cp -f ../images/heart.png iYMLegacy.app/.
	cp -f ../images/heart_fill.png iYMLegacy.app/.
	cp -f ../images/playlist*.png iYMLegacy.app/.

_nibs:
	cp -fr ../lproj/* iYMLegacy.app/.

iYMLegacy.app: iYMLegacy _dir _plist _images _nibs
	cp -f iYMLegacy iYMLegacy.app/. 
	cp -r ../libs iYMLegacy.app/.
	cd iYMLegacy.app; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libssl.0.9.8.dylib @executable_path/libs/libssl.dylib iYMLegacy; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcurl.4.dylib @executable_path/libs/libcurl.dylib iYMLegacy; \
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
