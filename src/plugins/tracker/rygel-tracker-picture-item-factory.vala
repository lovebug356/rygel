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
using DBus;

/**
 * Tracker picture item factory.
 */
public class Rygel.TrackerPictureItemFactory : Rygel.TrackerItemFactory {
    private enum PictureMetadata {
        HEIGHT = Metadata.LAST_KEY,
        WIDTH,

        LAST_KEY
    }

    private const string CATEGORY = "nmm:Photo";

    public TrackerPictureItemFactory () {
        base (CATEGORY, MediaItem.IMAGE_CLASS);
    }

    public override MediaItem create (string                 id,
                                      string                 uri,
                                      TrackerSearchContainer parent,
                                      string[]               metadata)
                                      throws GLib.Error {
        var item = base.create (id, uri, parent, metadata);

        if (metadata[PictureMetadata.WIDTH] != "")
            item.width = metadata[PictureMetadata.WIDTH].to_int ();

        if (metadata[PictureMetadata.HEIGHT] != "")
            item.height = metadata[PictureMetadata.HEIGHT].to_int ();

        return item;
    }

    public override string[] get_metadata_keys () {
        var base_keys = base.get_metadata_keys ();

        var keys = new string[PictureMetadata.LAST_KEY];
        for (var i = 0; i < base_keys.length; i++) {
            keys[i] = base_keys[i];
        }

        keys[PictureMetadata.WIDTH] = "nfo:width";
        keys[PictureMetadata.HEIGHT] = "nfo:height";

        return keys;
    }
}

