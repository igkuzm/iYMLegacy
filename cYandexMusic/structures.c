/**
 * File              : structures.c
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 23.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "structures.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define init_int(p, s, j) \
	({\
	  p->s = 0;\
		cJSON *s = cJSON_GetObjectItem(j, #s);\
		if (s)\
			p->s = s->valueint;\
	})

#define init_string(p, s, j) \
	({\
	  p->s = NULL;\
		cJSON *s = cJSON_GetObjectItem(json, #s);\
		if (s){\
			char *str = s->valuestring;\
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
		cJSON *s = cJSON_GetObjectItem(j, #s);\
		if (s){\
			int i;\
			int count = cJSON_GetArraySize(s);\
			p->s = malloc(count * sizeof(char *));\
			if (!c->s){\
				perror("malloc");\
				return;\
			}\
			for (i = 0; i < count; ++i) {\
				p->s[i] = NULL;\
				cJSON *item = cJSON_GetArrayItem(s, i);\
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
		cJSON *s = cJSON_GetObjectItem(json, #s);\
		if (s)\
			init_##T(&(p->s), s);\
	})

#define free_struct(p, s, T) \
	({\
		struct T member = p->s;\
		free_##T(&member);\
	})


#define init_struct_array(p, s, j, T) \
	({\
		cJSON *s = cJSON_GetObjectItem(json, #s);\
		if (s){\
			int i;\
			int count = cJSON_GetArraySize(s);\
			p->s = malloc(count * sizeof(struct T));\
			if (!p->s){\
				perror("malloc");\
				return;\
			}\
			for (i = 0; i < count; ++i) {\
				struct T member = p->s[i];\
				memset(&member, 0, sizeof(struct T));\
				cJSON *item = cJSON_GetArrayItem(s, i);\
				if (item)\
					init_##T(&member, item);\
			}\
			p->n_##s = count;\
		}\
	})

#define free_struct_array(p, s, T) \
	({\
		if (p->s){\
			int i;\
			for (i = 0; i < p->n_##s; ++i) {\
				struct T member = p->s[i];\
				free_##T(&member);\
			}\
			free(p->s);\
		}\
	})

void init_cover(cover_t *c, cJSON *json){
	init_int(c, custom, json);
	init_string(c, dir, json);
	init_string_array(c, itemsUri, json);
	init_string(c, uri, json);
	init_string(c, version, json);
	init_string(c, error, json);
	init_string(c, type, json);
	init_string(c, prefix, json);
}

void free_cover(cover_t *c){
	free_string(c, dir);	
	free_string_array(c, itemsUri);	
	free_string(c, uri);	
	free_string(c, version);	
	free_string(c, error);	
	free_string(c, type);	
	free_string(c, prefix);	
}

void init_artist(artist_t *c, cJSON *json){
	init_int(c, composer, json);	
	init_struct_array(c, cover, json, cover);
	init_int(c, id, json);
	init_string(c, name, json);
	init_int(c, various, json);	
}

void free_artist(artist_t *c){
	free_struct_array(c, cover, cover);
	free_string(c, name);	
}

void init_label(label_t *c, cJSON *json){
	init_int(c, id, json);	
	init_string(c, name, json);
}
	
void free_label(label_t *c){
	free_string(c, name);	
}

void init_tag(struct tag *c, cJSON *json){
	init_int(c, id, json);	
	init_string(c, value, json);
}
	
void free_tag(struct tag *c){
	free_string(c, value);	
}

void init_album(album_t *c, cJSON *json){
	init_int(c, id, json);
	init_string(c, error, json);
	init_string(c, title, json);
	init_int(c, year, json);
	init_int(c, releaseDate, json);
	init_string(c, coverUri, json);
	init_string(c, ogImage, json);
	init_string(c, genre, json);
	init_int(c, trackCount, json);
	init_int(c, recent, json);
	init_int(c, veryImportant, json);
	init_struct_array(c, artists, json, artist);
	init_struct_array(c, labels, json, label);
	init_int(c, available, json);
	init_int(c, availabaleForPremiumUsers, json);
	init_int(c, availableForMobile, json);
	init_int(c, availablePartially, json);
}

void free_album(album_t *c){
	free_string(c, error);
	free_string(c, title);
	free_string(c, coverUri);
	free_string(c, ogImage);
	free_string(c, genre);
	free_struct_array(c, artists, artist);
	free_struct_array(c, labels, label);
}

void init_major(struct major *c, cJSON *json){
	init_int(c, id, json);	
	init_string(c, name, json);
}
	
void free_major(struct major *c){
	free_string(c, name);	
}

void init_normalization(struct normalization *c, cJSON *json){
	init_int(c, gain, json);	
	init_int(c, peak, json);	
}
	
void free_normalization(struct normalization *c){
}

void init_track(struct track *c, cJSON *json){
	init_struct_array(c, albums, json, album);
	init_int(c, available, json);	
	init_int(c, availableForPremiumUsers, json);	
	init_int(c, availableFullWithoutPermission, json);	
	init_string(c, coverUri, json);
	init_int(c, durationMs, json);	
	init_int(c, fileSize, json);	
	init_string(c, id, json);
	init_int(c, lyricsAvailable, json);	
	init_struct(c, major, json, major);
	init_struct(c, normalization, json, normalization);
	init_string(c, ogImage, json);
	init_int(c, previewDurationMs, json);	
	init_string(c, realId, json);
	init_int(c, rememberPosition, json);	
	init_string(c, storageDir, json);
	init_string(c, title, json);
	init_string(c, type, json);
	init_string(c, backgroundVideoUri, json);
	init_struct_array(c, artists, json, artist);
}

void free_track(struct track *c){
	free_struct_array(c, albums, album);
	free_string(c, coverUri);
	free_string(c, id);
	free_struct(c, major, major);
	free_struct(c, normalization, normalization);
	free_string(c, ogImage);
	free_string(c, realId);
	free_string(c, storageDir);
	free_string(c, title);
	free_string(c, type);
	free_string(c, backgroundVideoUri);
	free_struct_array(c, artists, artist);
}

void init_tracks(struct tracks *c, cJSON *json){
	init_int(c, id, json);
	init_int(c, playCount, json);
	init_int(c, recent, json);
	init_int(c, timestamp, json);
	init_struct(c, track, json, track);
}

void free_tracks(struct tracks *c){
	free_struct(c, track, track);
}

void init_owner(struct owner *c, cJSON *json){
	init_string(c, login, json);
	init_string(c, name, json);
	init_string(c, sex, json);
	init_int(c, uid, json);
	init_int(c, verified, json);
}

void free_owner(struct owner *c){
	free_string(c, login);
	free_string(c, name);
	free_string(c, sex);
}

void init_playCounter(struct playCounter *c, cJSON *json) {
	init_string(c, description, json);
	init_string(c, descriptionNext, json);
	init_int(c, updated, json);
	init_int(c, value, json);
}

void free_playCounter(struct playCounter *c) {
	free_string(c, description);
	free_string(c, descriptionNext);
}

void init_playlist(struct playlist *c, cJSON *json) {
	init_string(c, playlistUuid, json);
	init_string(c, description, json);
	init_string(c, descriptionFormatted, json);
	init_int(c, available, json);
	init_int(c, collective, json);
	init_struct_array(c, cover, json, cover);
	init_int(c, created, json);
	init_int(c, modified, json);
	init_string(c, backgroundColor, json);
	init_string(c, textColor, json);
	init_int(c, durationMs, json);
	init_int(c, isBanner, json);
	init_int(c, isPremiere, json);
	init_int(c, kind, json);
	init_string(c, ogImage, json);
	init_struct(c, owner, json, owner);
	//prerolls
	init_int(c, revision, json);
	init_int(c, snapshot, json);
	init_struct_array(c, tags, json, tag);
	init_string(c, title, json);
	init_int(c, trackCount, json);
	init_int(c, uid, json);
	init_string(c, visibility, json);
	init_int(c, likesCount, json);
	init_struct_array(c, tracks, json, tracks);
	init_string(c, animatedCoverUri, json);
	init_struct(c, coverWithoutText, json, cover);
	init_int(c, everPlayed, json);
	init_string(c, generatedPlayListType, json);
	init_string(c, idForFrom, json);
	//madeFor
	init_struct(c, playCounter, json, playCounter);
}

void free_playlist(struct playlist *c) {
	free_string(c, playlistUuid);
	free_string(c, description);
	free_string(c, descriptionFormatted);
	free_struct_array(c, cover, cover);
	free_string(c, backgroundColor);
	free_string(c, textColor);
	free_string(c, ogImage);
	free_struct(c, owner, owner);
	free_struct_array(c, tags, tag);
	free_string(c, title);
	free_string(c, visibility);
	free_struct_array(c, tracks, tracks);
	free_string(c, animatedCoverUri);
	free_struct(c, coverWithoutText, cover);
	free_string(c, generatedPlayListType);
	free_string(c, idForFrom);
	free_struct(c, playCounter, playCounter);
}

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

track_t * c_yandex_music_track_new_from_json(cJSON *json){
	return new_from_json(track, json);
}
void c_yandex_music_track_free(track_t *track){
	if (track){
		free_track(track);
		free(track);
	}
}

