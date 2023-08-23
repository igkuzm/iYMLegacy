/**
 * File              : structures.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 23.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#ifndef STRUCTURES_H
#define STRUCTURES_H

#include <stdio.h>
#include <time.h>
#include <stdbool.h>
#include "cJSON.h"

typedef struct cover {
	bool custom;
	char *dir;
	char **itemsUri;
	int n_itemsUri;
	char *uri;
	char *type;
	char *prefix;
	char *version;
	char *error;
} cover_t;

typedef struct artist {
	bool composer;
	cover_t *cover;
	int n_cover;
	int id;
	char *name;
	bool various;
} artist_t;

typedef struct label {
	int id;
	char *name;
} label_t;

struct tag {
	int id;
	char *value;
};

typedef struct album {
	int id;
	char *error;
	char *title;
	int year;
	time_t releaseDate;
	char *coverUri;
	char *ogImage;
	char *genre;
	int trackCount;
	bool recent;
	bool veryImportant;
	artist_t *artists;
	int n_artists;
	label_t *labels;
	int n_labels;
	bool available;
	bool availabaleForPremiumUsers;
	bool availableForMobile;
	bool availablePartially;
} album_t;

struct major {
		int id;
		char *name;
};

struct normalization {
		int gain;
		int peak;
};

struct track {
	album_t *albums;	
	int n_albums;
	bool available;
	bool availableForPremiumUsers;
	bool availableFullWithoutPermission;
	char *coverUri;
	int durationMs;
	size_t fileSize;
	char *id;
	bool lyricsAvailable;
	struct major major;
	struct normalization normalization;
	char *ogImage;
	int previewDurationMs;
	char *realId;
	bool rememberPosition;
	char *storageDir;
	char *title;
	char *type;
	char *backgroundVideoUri;
	artist_t *artists;
	int n_artists;
};
typedef struct track track_t ;
track_t *c_yandex_music_track_new_from_json(cJSON *json);
void c_yandex_music_track_free(track_t *track);

typedef struct tracks {
	int id;
	int playCount;
	bool recent;
	time_t	timestamp;
	struct track track;
} tracks_t;

struct owner {
	char *login;
	char *name;
	char *sex;
	int uid;
	bool verified;
};

struct playCounter {
	char *description;
	char *descriptionNext;
	bool updated;
	int value;
};

typedef struct playlist {
	char *playlistUuid;
	char *description;
	char *descriptionFormatted;
	bool available;
	bool collective;
	cover_t *cover;
	int n_cover;
	time_t created;
	time_t modified;
	char *backgroundColor;
	char *textColor;
	int durationMs;
	bool isBanner;
	bool isPremiere;
	int kind;
	char *ogImage;
	struct owner owner;
	//prerolls
	int revision;
	int snapshot;
	struct tag *tags;
	int n_tags;
	char *title;
	int trackCount;
	int uid;
	char *visibility;
	int likesCount;
	struct tracks *tracks;
	int n_tracks;
	char *animatedCoverUri;
	struct cover coverWithoutText;
	bool everPlayed;
	char *generatedPlayListType;
	char *idForFrom;
	//madeFor
	struct playCounter playCounter;
} playlist_t;



#endif /* ifndef STRUCTURES_H */		
