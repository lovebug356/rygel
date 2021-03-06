/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

using GUPnP;
using Gst;

/**
 * Represents MediaExport item.
 */
public class Rygel.MediaExportItem : Rygel.MediaItem {
    public MediaExportItem (MediaContainer parent,
                            File           file,
                            FileInfo       info) {
        string content_type = info.get_content_type ();
        string item_class = null;
        string id = Checksum.compute_for_string (ChecksumType.MD5,
                                                 info.get_name ());

        // use heuristics based on content type; will use MediaHarvester
        // when it's ready

        if (content_type.has_prefix ("video/")) {
            item_class = MediaItem.VIDEO_CLASS;
        } else if (content_type.has_prefix ("audio/")) {
            item_class = MediaItem.AUDIO_CLASS;
        } else if (content_type.has_prefix ("image/")) {
            item_class = MediaItem.IMAGE_CLASS;
        }

        if (item_class == null) {
            item_class = MediaItem.AUDIO_CLASS;
            warning ("Failed to detect UPnP class for '%s', assuming it's '%s'",
                     file.get_uri (), item_class);
        }

        base (id, parent, info.get_name (), item_class);

        this.mime_type = content_type;
        this.add_uri (file.get_uri (), null);
    }

    public static MediaItem? create_from_taglist (MediaContainer parent,
                                                  File file,
                                                  Gst.TagList tag_list) {
        string id = Checksum.compute_for_string (ChecksumType.MD5,
                                                 file.get_uri ());
        int width = -1;
        int height = -1;
        string class_guessed = null;

        if (tag_list != null) {
            string codec;

            if (!tag_list.get_string (TAG_VIDEO_CODEC, out codec)) {
                if (!tag_list.get_string (TAG_AUDIO_CODEC, out codec)) {
                    if (tag_list.get_int (MetadataExtractor.TAG_RYGEL_WIDTH, out width) ||
                        tag_list.get_int (MetadataExtractor.TAG_RYGEL_HEIGHT, out height)) {
                        class_guessed = MediaItem.IMAGE_CLASS;
                    } else {
                        // if it has width and height and a duration, assume
                        // it is a video (to capture the MPEG TS without audio
                        // case)
                        int64 duration;
                        if (tag_list.get_int64 (MetadataExtractor.TAG_RYGEL_DURATION,
                                                out duration)) {
                            class_guessed = MediaItem.VIDEO_CLASS;
                        } else {
                            warning("There's no codec inside and file is no image: " +
                                    "%s", file.get_uri ());
                            return null;
                        }
                    }
                } else {
                    // MPEG TS streams seem to miss VIDEO_CODEC; so if we have
                    // an AUDIO_CODEC and width or height, assume video as
                    // well
                    if (tag_list.get_int (MetadataExtractor.TAG_RYGEL_WIDTH, out width) ||
                        tag_list.get_int (MetadataExtractor.TAG_RYGEL_HEIGHT, out height)) {
                        class_guessed = MediaItem.VIDEO_CLASS;
                    } else {
                        class_guessed = MediaItem.AUDIO_CLASS;
                    }
                }
            } else {
                class_guessed = MediaItem.VIDEO_CLASS;
            }
        } else {
            // throw error. Taglist can't be empty
            warning("Got empty taglist for file %s", file.get_uri ());
            return null;
        }

        return new MediaExportItem.from_taglist (parent,
                                                 id,
                                                 file,
                                                 tag_list,
                                                 class_guessed);
    }

    private MediaExportItem.from_taglist (MediaContainer parent,
                                          string id,
                                          File file,
                                          Gst.TagList tag_list,
                                          string upnp_class) {
        string title = null;
        if (upnp_class == MediaItem.AUDIO_CLASS ||
            upnp_class == MediaItem.MUSIC_CLASS) {

            if (!tag_list.get_string (TAG_TITLE, out title)) {
                title = file.get_basename ();
            }

        } else {
            title = file.get_basename ();
        }
        base (id, parent, title, upnp_class);

        tag_list.get_int (MetadataExtractor.TAG_RYGEL_WIDTH, out this.width);
        tag_list.get_int (MetadataExtractor.TAG_RYGEL_HEIGHT, out this.height);
        tag_list.get_int (MetadataExtractor.TAG_RYGEL_DEPTH,
                          out this.color_depth);
        int64 duration;
        tag_list.get_int64 (MetadataExtractor.TAG_RYGEL_DURATION,
                            out duration);
        this.duration = (duration == -1) ? -1 : (long) (duration / 1000000000);

        tag_list.get_int (MetadataExtractor.TAG_RYGEL_CHANNELS, out this.n_audio_channels);

        tag_list.get_string (TAG_ARTIST, out this.author);
        tag_list.get_string (TAG_ALBUM, out this.album);

        uint tmp;
        tag_list.get_uint (TAG_TRACK_NUMBER, out tmp);
        this.track_number = (int)tmp;
        tag_list.get_uint (TAG_BITRATE, out tmp);
        this.bitrate = (int)tmp / 8;
        tag_list.get_int (MetadataExtractor.TAG_RYGEL_RATE, out this.sample_freq);


        int64 size;
        tag_list.get_int64 (MetadataExtractor.TAG_RYGEL_SIZE, out size);
        this.size = (long) size;

        uint64 mtime;
        tag_list.get_uint64 (MetadataExtractor.TAG_RYGEL_MTIME,
                             out mtime);
        this.modified = (int64) mtime;

        GLib.Date? date;
        if (tag_list.get_date (TAG_DATE, out date)) {
            char[] datestr = new char[30];
            date.strftime(datestr, "%F");
            this.date = (string)datestr;
        } else {
            var tv = TimeVal();
            tv.tv_usec = 0;
            tv.tv_sec = (long)mtime;
            this.date = tv.to_iso8601 ();
        }


        tag_list.get_string (MetadataExtractor.TAG_RYGEL_MIME,
                             out this.mime_type);

        this.add_uri (file.get_uri (), null);
    }
}

