/**
 * File              : structures.c
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 29.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "structures.h"
#include "cJSON.h"
#include <stdio.h>
#include <string.h>

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
	
	char id_str[128];
	sprintf(id_str, "%ld", c->id);
	c->realId = strdup(id_str);

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
	c->type = strdup("album");
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
	
	cJSON *id_json = cJSON_GetObjectItem(json, "id");
	if (cJSON_IsString(id_json))
		init_string(c, id, json);
	else if (cJSON_IsNumber(id_json)){
		long num = id_json->valueint;
		char id_str[128];
		sprintf(id_str, "%ld", num);
		c->id = strdup(id_str);
	}
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

track_t * c_yandex_music_track_new_from_json(cJSON *json){
	return new_from_json(track, json);
}
void c_yandex_music_track_free(track_t *track){
	if (track){
		free_track(track);
		free(track);
	}
}

playlist_t *c_yandex_music_playlist_new_from_json(cJSON *json){
	return new_from_json(playlist, json);
}
void c_yandex_music_playlist_free(playlist_t *p){
	if (p){
		free_playlist(p);
		free(p);
	}
}

album_t * c_yandex_music_album_new_from_json(cJSON *json){
	return new_from_json(album, json);
}
void c_yandex_music_album_free(album_t *album){
	if (album){
		free_album(album);
		free(album);
	}
}


