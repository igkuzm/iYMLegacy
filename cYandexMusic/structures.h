/**
 * File              : structures.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 25.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#ifndef STRUCTURES_H
#define STRUCTURES_H

#include <stdio.h>
#include <time.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include "cJSON.h"

#define new_from_json(T, j)\
	({\
	 struct T *ptr = (struct T *)malloc(sizeof(struct T));\
	 if (!ptr){\
		perror("malloc");\
		return NULL;\
	 }\
	 init_##T(ptr, j);\
	 ptr;\
	})		

#define init_int(p, s, j) \
	({\
	  p->s = 0;\
		cJSON *o = cJSON_GetObjectItem(j, #s);\
		if (o)\
			p->s = o->valueint;\
	})

#define init_string(p, s, j) \
	({\
	  p->s = NULL;\
		cJSON *o = cJSON_GetObjectItem(json, #s);\
		if (o){\
			char *str = o->valuestring;\
			if (str)\
				p->s = strdup(str);\
	 }\
	})

#define free_string(p, s) \
	({\
		if (p->s)\
			free(p->s);\
		p->s = NULL;\
	})


#define init_string_array(p, s, j) \
	({\
		cJSON *a = cJSON_GetObjectItem(j, #s);\
		if (a && cJSON_IsArray(a)){\
			int i;\
			int count = cJSON_GetArraySize(a);\
			p->s = malloc(count * sizeof(char *));\
			if (!c->s){\
				perror("malloc");\
				return;\
			}\
			for (i = 0; i < count; ++i) {\
				p->s[i] = NULL;\
				cJSON *item = cJSON_GetArrayItem(a, i);\
				if (item){\
					char *str = item->valuestring;\
					if (str)\
						p->s[i] = strdup(str);\
				}\
			}\
			p->n_##s = count;\
		}\
	})

#define free_string_array(p, s) \
	({\
		if (p->s){\
			int i;\
			for (i = 0; i < c->n_##s; ++i) {\
				if(p->s[i])\
					free(p->s[i]);\
				p->s[i] = NULL;\
			}\
			free(p->s);\
		}\
	})


#define init_struct(p, s, j, T) \
	({\
		cJSON *o = cJSON_GetObjectItem(json, #s);\
		if (o)\
			init_##T(&(p->s), o);\
	})

#define free_struct(p, s, T) \
	({\
		free_##T(&p->s);\
	})


#define init_struct_array(p, s, j, T) \
	({\
		cJSON *a = cJSON_GetObjectItem(json, #s);\
		if (a && cJSON_IsArray(a)){\
			int i;\
			int count = cJSON_GetArraySize(a);\
			p->s = malloc(count * sizeof(struct T));\
			if (!p->s){\
				perror("malloc");\
				return;\
			}\
			for (i = 0; i < count; ++i) {\
				memset(&(p->s[i]), 0, sizeof(struct T));\
				cJSON *item = cJSON_GetArrayItem(a, i);\
				if (item)\
					init_##T(&(p->s[i]), item);\
			}\
			p->n_##s = count;\
		}\
	})

#define free_struct_array(p, s, T) \
	({\
		if (p->s){\
			int i;\
			for (i = 0; i < p->n_##s; ++i) {\
				free_##T(&(p->s[i]));\
			}\
			free(p->s);\
		}\
	})

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

struct playlist {
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
	long kind;
	char *ogImage;
	struct owner owner;
	//prerolls
	int revision;
	int snapshot;
	struct tag *tags;
	int n_tags;
	char *title;
	int trackCount;
	long uid;
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
};
typedef struct playlist playlist_t;
playlist_t *c_yandex_music_playlist_new_from_json(cJSON *json);
void c_yandex_music_playlist_free(playlist_t *p);


#define STRUCT\
	STRUCT_ITEM_STR(codec)\
	STRUCT_ITEM_BOL(gain)\
	STRUCT_ITEM_STR(preview)\
	STRUCT_ITEM_STR(downloadInfoUrl)\
	STRUCT_ITEM_BOL(direct)\
	STRUCT_ITEM_INT(bitrateInKbps)

struct downloadInfo {
	#define STRUCT_ITEM_STR(m) char * m;
	#define STRUCT_ITEM_BOL(m) bool m;
	#define STRUCT_ITEM_INT(m) int m;
	STRUCT
	#undef STRUCT_ITEM_STR
	#undef STRUCT_ITEM_BOL
	#undef STRUCT_ITEM_INT
};

static void init_downloadInfo(struct downloadInfo *c, cJSON *json)
{
	#define STRUCT_ITEM_STR(m) init_string(c, m, json);
	#define STRUCT_ITEM_BOL(m) init_int(c, m, json);
	#define STRUCT_ITEM_INT(m) init_int(c, m, json);
	STRUCT
	#undef STRUCT_ITEM_STR
	#undef STRUCT_ITEM_BOL
	#undef STRUCT_ITEM_INT
}

static struct downloadInfo *
c_yandex_music_downloadInfo_new_from_json(cJSON *json)
{
	return new_from_json(downloadInfo, json);
}


#endif /* ifndef STRUCTURES_H */		
